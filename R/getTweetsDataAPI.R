# Datos de tweets por URL via API GraphQL/JSON de X (experimental, 0.4.0) ---
#
# Reemplazo API de getTweetsData()/getTweetsData2() (HTML). Para cada URL navega
# el tweet, cosecha la respuesta TweetDetail y se queda con el tweet focal (el
# que coincide con el id de la URL), descartando las respuestas del hilo.

#' Get Tweet Data from URLs via the X API (experimental)
#'
#' @description
#'
#' <a href="https://lifecycle.r-lib.org/articles/stages.html#experimental" target="_blank"><img src="https://lifecycle.r-lib.org/articles/figures/lifecycle-experimental.svg" alt="[Experimental]"></a>
#'
#' Recupera los datos de tweets a partir de sus URLs consultando la **API
#' GraphQL interna de X** (TweetDetail). Devuelve datos estructurados del JSON.
#' Es el reemplazo basado en API de `getTweetsData()`. Requiere una sesion
#' importada con [importSessionX()].
#'
#' @param urls_tweets Vector de URLs de tweets (formato https://x.com/u/status/123).
#' @param dir Directorio de destino del RDS. Por defecto el de trabajo.
#' @param save Logico. Si TRUE (por defecto) guarda el resultado en un RDS.
#'
#' @return Un tibble con una fila por tweet (mismas columnas que getUserTweetsAPI).
#' @export
#'
#' @examples
#' \dontrun{
#' importSessionX(auth_token = "...", ct0 = "...")
#' getTweetsDataAPI(c("https://x.com/NASA/status/123", "https://x.com/NASA/status/456"))
#' }
getTweetsDataAPI <- function(urls_tweets, dir = getwd(), save = TRUE) {
  if (missing(urls_tweets) || !length(urls_tweets)) {
    stop("Necesito al menos una URL de tweet.")
  }
  ids <- sub("^.*/status/([0-9]+).*$", "\\1", urls_tweets)
  # Una sola sesion de navegador para TODAS las URLs (batch).
  grupos <- .pw_harvest_batch(urls_tweets, "TweetDetail", max_scrolls = 1)

  rows <- list()
  for (k in seq_along(grupos)) {
    focal <- NULL
    for (d in grupos[[k]]) {
      p <- .parse_timeline_tweets(d)
      if (!is.null(p$tweets)) {
        hit <- p$tweets[!is.na(p$tweets$tweet_id) & p$tweets$tweet_id == ids[k], , drop = FALSE]
        if (nrow(hit)) {
          focal <- hit[1, ]
          break
        }
      }
    }
    if (!is.null(focal)) {
      rows[[length(rows) + 1L]] <- focal
    } else {
      warning("No se pudo recuperar el tweet: ", urls_tweets[k])
    }
    cat("Procesado:", urls_tweets[k], "\n")
  }
  tweets <- if (length(rows)) dplyr::bind_rows(rows) else tibble::tibble()
  .save_rds(tweets, dir, "api_tweets_data", save = save)
  tweets
}
