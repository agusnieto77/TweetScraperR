# Scraping via API GraphQL/JSON de X (experimental, rumbo a 0.4.0) ---------
#
# A diferencia del scraping por HTML (que parsea selectores CSS fragiles), estas
# funciones consultan la API GraphQL interna de X y parsean JSON estructurado.
# Reusan la sesion importada con importSessionX(); el navegador autenticado
# genera nativamente las cabeceras anti-bot, asi que no hay que reproducirlas.

#' Devuelve b si a es NULL (coalesce de NULL)
#' @noRd
.or_null <- function(a, b) if (is.null(a)) b else a

#' Parsea la fecha de Twitter ("Wdy Mon DD HH:MM:SS +0000 YYYY") a POSIXct UTC
#'
#' Independiente del locale del sistema (no usa nombres de mes/dia localizados).
#' @noRd
.x_parse_twitter_date <- function(x) {
  if (is.null(x) || !nzchar(x)) return(as.POSIXct(NA, tz = "UTC"))
  meses <- c(Jan = 1, Feb = 2, Mar = 3, Apr = 4, May = 5, Jun = 6,
             Jul = 7, Aug = 8, Sep = 9, Oct = 10, Nov = 11, Dec = 12)
  m <- regmatches(x, regexec("^\\w+ (\\w+) (\\d+) (\\d+):(\\d+):(\\d+) [+-]\\d+ (\\d+)$", x))[[1]]
  if (length(m) != 7) return(as.POSIXct(NA, tz = "UTC"))
  as.POSIXct(
    sprintf("%s-%02d-%02d %s:%s:%s", m[7], meses[[m[2]]], as.integer(m[3]), m[4], m[5], m[6]),
    tz = "UTC"
  )
}

#' Encuentra recursivamente la primera lista "instructions" en la respuesta
#'
#' La ruta del timeline difiere por endpoint (UserTweets vs SearchTimeline,
#' etc.); esta busqueda en profundidad la ubica sin hardcodear el path.
#' @noRd
.find_instructions <- function(x) {
  if (!is.list(x)) return(NULL)
  if (!is.null(x[["instructions"]]) && is.list(x[["instructions"]])) {
    return(x[["instructions"]])
  }
  for (el in x) {
    r <- .find_instructions(el)
    if (!is.null(r)) return(r)
  }
  NULL
}

#' Extrae un campo de cada item de una lista de entidades como vector character
#' @noRd
.entity_vec <- function(items, field) {
  if (is.null(items) || !length(items)) return(character(0))
  out <- vapply(items, function(x) .or_null(x[[field]], NA_character_), character(1))
  out[!is.na(out)]
}

#' Extrae URLs y tipos de media de un objeto legacy (fotos y videos/gifs)
#' @noRd
.extract_media <- function(lg) {
  media <- lg$extended_entities$media
  if (is.null(media)) media <- lg$entities$media
  if (is.null(media) || !length(media)) return(list(urls = character(0), tipos = character(0)))
  urls <- character(0)
  tipos <- character(0)
  for (m in media) {
    tipo <- .or_null(m$type, "photo")
    if (tipo %in% c("video", "animated_gif") && length(m$video_info$variants)) {
      mp4 <- Filter(function(v) identical(v$content_type, "video/mp4"), m$video_info$variants)
      if (length(mp4)) {
        br <- vapply(mp4, function(v) as.numeric(.or_null(v$bitrate, 0)), numeric(1))
        url <- mp4[[which.max(br)]]$url
      } else {
        url <- .or_null(m$media_url_https, NA_character_)
      }
    } else {
      url <- .or_null(m$media_url_https, NA_character_)
    }
    urls <- c(urls, url)
    tipos <- c(tipos, tipo)
  }
  list(urls = urls, tipos = tipos)
}

#' Construye una fila-tibble de tweet a partir de un objeto tweet_results$result
#' @noRd
.tweet_row <- function(tr) {
  if (is.null(tr)) return(NULL)
  if (identical(tr$`__typename`, "TweetWithVisibilityResults")) tr <- tr$tweet
  lg <- tr$legacy
  if (is.null(lg$full_text)) return(NULL)
  core <- tr$core$user_results$result
  handle <- .or_null(core$core$screen_name, core$legacy$screen_name)
  tid <- .or_null(tr$rest_id, lg$id_str)
  ent <- lg$entities
  med <- .extract_media(lg)
  qr <- tr$quoted_status_result$result
  if (identical(qr$`__typename`, "TweetWithVisibilityResults")) qr <- qr$tweet
  tibble::tibble(
    fecha           = .x_parse_twitter_date(lg$created_at),
    user            = if (is.null(handle)) NA_character_ else paste0("@", handle),
    texto           = lg$full_text,
    idioma          = .or_null(lg$lang, NA_character_),
    respuestas      = as.integer(.or_null(lg$reply_count, NA)),
    retweets        = as.integer(.or_null(lg$retweet_count, NA)),
    citas           = as.integer(.or_null(lg$quote_count, NA)),
    megustas        = as.integer(.or_null(lg$favorite_count, NA)),
    views           = suppressWarnings(as.integer(.or_null(tr$views$count, NA))),
    hashtags        = list(.entity_vec(ent$hashtags, "text")),
    menciones       = list(.entity_vec(ent$user_mentions, "screen_name")),
    urls_externas   = list(.entity_vec(ent$urls, "expanded_url")),
    media           = list(med$urls),
    media_tipo      = list(med$tipos),
    es_retweet      = !is.null(lg$retweeted_status_result),
    es_cita         = isTRUE(lg$is_quote_status),
    tweet_citado_id = .or_null(qr$rest_id, NA_character_),
    conversation_id = .or_null(lg$conversation_id_str, NA_character_),
    url             = if (is.null(handle)) NA_character_ else paste0("https://x.com/", handle, "/status/", tid),
    tweet_id        = .or_null(tid, NA_character_)
  )
}

#' Junta los tweet_results de un entry: directo o anidado en conversationthread
#' @noRd
.entry_tweet_results <- function(e) {
  res <- list()
  tr <- e$content$itemContent$tweet_results$result
  if (!is.null(tr)) res[[length(res) + 1L]] <- tr
  for (it in .or_null(e$content$items, list())) {
    tr2 <- it$item$itemContent$tweet_results$result
    if (!is.null(tr2)) res[[length(res) + 1L]] <- tr2
  }
  res
}

#' Extrae los tweets y el cursor de una respuesta de timeline GraphQL
#'
#' Funciona para timelines simples (UserTweets, SearchTimeline) y para hilos de
#' conversacion (TweetDetail), donde cada entry `conversationthread-*` agrupa
#' varias respuestas en `content$items`.
#' @noRd
.parse_timeline_tweets <- function(d) {
  insts <- .find_instructions(d)
  if (is.null(insts)) return(list(tweets = NULL, cursor = NA_character_))
  rows <- list()
  cursor <- NA_character_
  for (ins in insts) {
    for (e in .or_null(ins$entries, list())) {
      eid <- .or_null(e$entryId, "")
      if (grepl("^cursor-bottom", eid)) {
        cursor <- .or_null(e$content$value, cursor)
        next
      }
      for (tr in .entry_tweet_results(e)) {
        row <- .tweet_row(tr)
        if (!is.null(row)) rows[[length(rows) + 1L]] <- row
      }
    }
  }
  list(
    tweets = if (length(rows)) dplyr::bind_rows(rows) else NULL,
    cursor = cursor
  )
}

#' Get Tweets from a User Timeline via the X API (experimental)
#'
#' @description
#'
#' <a href="https://lifecycle.r-lib.org/articles/stages.html#experimental" target="_blank"><img src="https://lifecycle.r-lib.org/articles/figures/lifecycle-experimental.svg" alt="[Experimental]"></a>
#'
#' Recupera los tweets del timeline de unx usuarix consultando la **API GraphQL
#' interna de X** (en lugar de scrapear HTML). Devuelve datos estructurados
#' directamente del JSON: texto completo (sin truncar), fecha exacta, y metricas
#' (respuestas, retweets, citas, me gusta, vistas). Requiere una sesion
#' importada con [importSessionX()].
#'
#' @param username Nombre de usuarix (sin @). Por defecto "NASA".
#' @param n_tweets Numero maximo de tweets a recuperar. Por defecto 40.
#' @param dir Directorio de destino del RDS. Por defecto el de trabajo.
#' @param save Logico. Si TRUE (por defecto) guarda el resultado en un RDS.
#'
#' @return Un tibble con un tweet por fila y columnas: fecha, user, texto,
#'   idioma, respuestas, retweets, citas, megustas, views, hashtags (lista),
#'   menciones (lista), urls_externas (lista), media (lista de URLs),
#'   media_tipo (lista: photo/video/animated_gif), es_retweet, es_cita,
#'   tweet_citado_id, conversation_id, url y tweet_id.
#' @export
#'
#' @examples
#' \dontrun{
#' importSessionX(auth_token = "...", ct0 = "...")
#' tw <- getUserTweetsAPI("NASA", n_tweets = 100)
#' }
getUserTweetsAPI <- function(username = "NASA", n_tweets = 40, dir = getwd(), save = TRUE) {
  if (!nzchar(username)) stop("Necesito un nombre de usuarix.")
  url <- paste0("https://x.com/", username)
  cat("Recolectando timeline de @", username, "...\n", sep = "")
  scrolls <- max(3L, as.integer(ceiling(n_tweets / 15) + 3L))
  docs <- .pw_harvest(url, "UserTweets", max_scrolls = scrolls)

  rows <- list()
  for (d in docs) {
    p <- .parse_timeline_tweets(d)
    if (!is.null(p$tweets)) rows[[length(rows) + 1L]] <- p$tweets
  }
  tweets <- if (length(rows)) {
    dplyr::distinct(dplyr::bind_rows(rows), tweet_id, .keep_all = TRUE)
  } else {
    tibble::tibble()
  }
  if (nrow(tweets) > n_tweets) tweets <- utils::head(tweets, n_tweets)
  cat("Tweets \u00fanicos recolectados:", nrow(tweets), "\n")
  .save_rds(tweets, dir, paste0("api_timeline_", username), save = save)
  tweets
}
