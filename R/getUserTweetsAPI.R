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

#' Resuelve el rest_id (ID numerico) de un usuario por su screen name
#' @noRd
.x_user_rest_id <- function(username, state = .pw_state_path()) {
  d <- .pw_graphql(
    .gql_ops$UserByScreenName,
    list(screen_name = username, withSafetyModeUserFields = TRUE),
    .gql_features_user, state = state
  )
  rid <- d$data$user$result$rest_id
  if (is.null(rid)) {
    stop("No se encontr\u00f3 el usuario @", username, " (\u00bfexiste? \u00bfsesi\u00f3n v\u00e1lida?).")
  }
  rid
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
  tibble::tibble(
    fecha       = .x_parse_twitter_date(lg$created_at),
    user        = if (is.null(handle)) NA_character_ else paste0("@", handle),
    texto       = lg$full_text,
    respuestas  = as.integer(.or_null(lg$reply_count, NA)),
    retweets    = as.integer(.or_null(lg$retweet_count, NA)),
    citas       = as.integer(.or_null(lg$quote_count, NA)),
    megustas    = as.integer(.or_null(lg$favorite_count, NA)),
    views       = suppressWarnings(as.integer(.or_null(tr$views$count, NA))),
    es_retweet  = !is.null(lg$retweeted_status_result),
    es_cita     = isTRUE(lg$is_quote_status),
    url         = if (is.null(handle)) NA_character_ else paste0("https://x.com/", handle, "/status/", tid),
    tweet_id    = .or_null(tid, NA_character_)
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
#' @return Un tibble con un tweet por fila y columnas fecha, user, texto,
#'   respuestas, retweets, citas, megustas, views, es_retweet, es_cita, url,
#'   tweet_id.
#' @export
#'
#' @examples
#' \dontrun{
#' importSessionX(auth_token = "...", ct0 = "...")
#' tw <- getUserTweetsAPI("NASA", n_tweets = 100)
#' }
getUserTweetsAPI <- function(username = "NASA", n_tweets = 40, dir = getwd(), save = TRUE) {
  state <- .pw_state_path()
  cat("Resolviendo @", username, "...\n", sep = "")
  uid <- .x_user_rest_id(username, state)

  acc <- list()
  cursor <- NULL
  got <- 0L
  repeat {
    vars <- list(
      userId = uid, count = 40L, includePromotedContent = TRUE,
      withQuickPromoteEligibilityTweetFields = TRUE, withVoice = TRUE,
      withV2Timeline = TRUE
    )
    if (!is.null(cursor)) vars$cursor <- cursor
    d <- .pw_graphql(.gql_ops$UserTweets, vars, .gql_features, state = state)
    parsed <- .parse_timeline_tweets(d)
    if (is.null(parsed$tweets)) break
    acc[[length(acc) + 1L]] <- parsed$tweets
    got <- got + nrow(parsed$tweets)
    cat("Recolectados", got, "tweets...\n")
    if (got >= n_tweets) break
    if (is.na(parsed$cursor) || identical(parsed$cursor, cursor)) break
    cursor <- parsed$cursor
  }

  tweets <- if (length(acc)) utils::head(dplyr::bind_rows(acc), n_tweets) else tibble::tibble()
  .save_rds(tweets, dir, paste0("api_timeline_", username), save = save)
  tweets
}
