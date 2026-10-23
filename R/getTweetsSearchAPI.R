# Busqueda via API GraphQL/JSON de X (experimental, rumbo a 0.4.0) ---------
#
# SearchTimeline exige el header x-client-transaction-id (un fetch crafteado da
# 404), asi que en vez de craftear la request se "cosecha" la respuesta JSON
# que dispara la propia app de X al navegar la pagina de busqueda (.pw_harvest),
# y se parsea con el mismo parser de timeline (.parse_timeline_tweets).

#' URL del buscador de X para una consulta y una pestania (`f`)
#' @noRd
.search_url <- function(search, f) {
  paste0("https://x.com/search?q=", utils::URLencode(search, reserved = TRUE),
         "&src=typed_query&f=", f)
}

#' Interpreta un `since`/`until` como instante UTC
#'
#' Acepta un dia (`"YYYY-MM-DD"` o `Date`, a las 00:00 UTC) o un instante
#' (`"YYYY-MM-DD HH:MM[:SS]"` en UTC, con `_` o `T` como separador y sufijo
#' `_UTC` opcional, o un `POSIXct` en cualquier zona horaria).
#' @return `list(time = POSIXct, day = logico)`, o NULL si `x` es NULL o vacio.
#' @noRd
.parse_search_time <- function(x, op) {
  if (is.null(x) || (is.character(x) && !nzchar(x))) return(NULL)
  if (length(x) != 1L || is.na(x)) {
    stop("`", op, "` debe ser una sola fecha.", call. = FALSE)
  }
  if (inherits(x, "Date")) return(list(time = as.POSIXct(format(x), tz = "UTC"), day = TRUE))
  if (inherits(x, "POSIXct")) return(list(time = x, day = FALSE))
  x <- trimws(sub("_UTC$", "", as.character(x)))
  if (grepl("^\\d{4}-\\d{2}-\\d{2}$", x, perl = TRUE) &&
      !is.na(as.Date(x, format = "%Y-%m-%d", optional = TRUE))) {
    return(list(time = as.POSIXct(x, tz = "UTC"), day = TRUE))
  }
  if (grepl("^\\d{4}-\\d{2}-\\d{2}[ _T]\\d{2}:\\d{2}(:\\d{2})?$", x, perl = TRUE)) {
    x <- sub("^(\\S{10})[ _T]", "\\1 ", x)
    t <- as.POSIXct(x, tz = "UTC", tryFormats = c("%Y-%m-%d %H:%M:%S", "%Y-%m-%d %H:%M"),
                    optional = TRUE)
    if (!is.na(t)) return(list(time = t, day = FALSE))
  }
  stop("`", op, "` no es una fecha valida: usa \"YYYY-MM-DD\" o \"YYYY-MM-DD HH:MM:SS\" (UTC).",
       call. = FALSE)
}

#' Operador de fecha de la busqueda de X para `since`/`until`
#'
#' Siempre se pasa como `since_time:`/`until_time:` en segundos Unix. Los
#' operadores de dia (`since:`/`until:`) los interpreta X en la zona horaria
#' del navegador (la del motor es la de Buenos Aires), no en UTC, y X ya no
#' devuelve resultados con `since:YYYY-MM-DD_HH:MM:SS`. Un dia en `until`
#' incluye ese dia completo (hasta las 00:00 UTC del siguiente).
#' @return El operador como texto, o NULL si `x` es NULL o vacio.
#' @noRd
.search_time_operator <- function(x, op) {
  t <- .parse_search_time(x, op)
  if (is.null(t)) return(NULL)
  secs <- floor(as.numeric(t$time)) + if (t$day && op == "until") 86400 else 0
  paste0(op, "_time:", sprintf("%.0f", secs))
}

#' Search Tweets via the X API (experimental)
#'
#' @description
#'
#' <a href="https://lifecycle.r-lib.org/articles/stages.html#experimental" target="_blank"><img src="https://lifecycle.r-lib.org/articles/figures/lifecycle-experimental.svg" alt="[Experimental]"></a>
#'
#' Busca tweets que coinciden con una consulta consultando la **API GraphQL
#' interna de X** (en lugar de scrapear HTML). Devuelve datos estructurados del
#' JSON: texto completo, fecha exacta y metricas (respuestas, retweets, citas,
#' me gusta, vistas). Requiere una sesion importada con [importSessionX()].
#'
#' @param search Consulta de busqueda (soporta operadores de X, p.ej. "from:NASA",
#'   "#RStats", "lang:es"). Por defecto "#RStats".
#' @param n_tweets Numero maximo de tweets a recuperar. Por defecto 40.
#' @param product Pestania de resultados: "Latest" (recientes, por defecto),
#'   "Top" (destacados) o "Media".
#' @param dir Directorio de destino del RDS. Por defecto el de trabajo.
#' @param save Logico. Si TRUE guarda el resultado en un RDS dentro de `dir`.
#'   Por defecto FALSE: no se escribe ningun archivo.
#' @param since Desde cuando (opcional). Un dia `"YYYY-MM-DD"` (desde las
#'   00:00 UTC de ese dia) o un instante `"YYYY-MM-DD HH:MM[:SS]"` en UTC
#'   (tambien con `_` o `T` como separador y sufijo `_UTC`). Acepta objetos
#'   `Date` y `POSIXct`. Se traduce al operador `since_time:` de X.
#' @param until Hasta cuando (opcional), mismos formatos que `since`. Un dia
#'   incluye ese dia completo (UTC); se traduce a `until_time:`.
#'
#' @return Un tibble con un tweet por fila (mismas columnas que
#'   [getUserTweetsAPI()], incluyendo media, hashtags, menciones, etc.).
#' @export
#'
#' @examples
#' \dontrun{
#' importSessionX(auth_token = "...", ct0 = "...")
#' tw <- getTweetsSearchAPI("#RStats", n_tweets = 100)
#' getTweetsSearchAPI("from:NASA artemis", product = "Top")
#' }
getTweetsSearchAPI <- function(search = "#RStats", n_tweets = 40,
                               product = c("Latest", "Top", "Media"),
                               since = NULL, until = NULL,
                               dir = getwd(), save = FALSE) {
  product <- match.arg(product)
  f <- c(Latest = "live", Top = "top", Media = "media")[[product]]
  search <- paste(c(search, .search_time_operator(since, "since"),
                    .search_time_operator(until, "until")), collapse = " ")
  url <- .search_url(search, f)
  cat("Buscando: ", search, " (", product, ")\n", sep = "")

  docs <- .pw_harvest(url, "SearchTimeline", max_scrolls = .scrolls_for(n_tweets), n = n_tweets)

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

  .save_rds(tweets, dir, paste0("api_search_", gsub("[^A-Za-z0-9]+", "_", search)), save = save)
  tweets
}
