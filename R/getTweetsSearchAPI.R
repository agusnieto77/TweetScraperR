# Busqueda via API GraphQL/JSON de X (experimental, rumbo a 0.4.0) ---------
#
# SearchTimeline exige el header x-client-transaction-id (un fetch crafteado da
# 404), asi que en vez de craftear la request se "cosecha" la respuesta JSON
# que dispara la propia app de X al navegar la pagina de busqueda (.pw_harvest),
# y se parsea con el mismo parser de timeline (.parse_timeline_tweets).

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
#' @param save Logico. Si TRUE (por defecto) guarda el resultado en un RDS.
#' @param since Fecha "desde" (opcional). Formato "YYYY-MM-DD" o el
#'   "YYYY-MM-DD_HH:MM:SS" de X. Migra el parametro de los historicos legacy.
#' @param until Fecha "hasta" (opcional). Mismo formato que `since`.
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
                               dir = getwd(), save = TRUE) {
  product <- match.arg(product)
  f <- c(Latest = "live", Top = "top", Media = "media")[[product]]
  # Filtros de fechas nativos de la busqueda de X (paridad con los historicos
  # legacy): aceptan "YYYY-MM-DD" o el "YYYY-MM-DD_HH:MM:SS[_UTC]" de los
  # historicos viejos (X usa "since:YYYY-MM-DD_HH:MM:SS" sin el sufijo _UTC).
  if (!is.null(since) && nzchar(since)) {
    since <- sub("_UTC$", "", since)
    since <- gsub("[[:space:]]+", "_", since)
    search <- paste(search, paste0("since:", since))
  }
  if (!is.null(until) && nzchar(until)) {
    until <- sub("_UTC$", "", until)
    until <- gsub("[[:space:]]+", "_", until)
    search <- paste(search, paste0("until:", until))
  }
  url <- paste0("https://x.com/search?q=", utils::URLencode(search, reserved = TRUE),
                "&src=typed_query&f=", f)
  cat("Buscando: ", search, " (", product, ")\n", sep = "")

  scrolls <- max(3L, as.integer(ceiling(n_tweets / 15) + 3L))
  docs <- .pw_harvest(url, "SearchTimeline", max_scrolls = scrolls)

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
