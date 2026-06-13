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
  rows <- list()
  for (u in urls_tweets) {
    id <- sub("^.*/status/([0-9]+).*$", "\\1", u)
    docs <- .pw_harvest(u, "TweetDetail", max_scrolls = 1)
    focal <- NULL
    for (d in docs) {
      p <- .parse_timeline_tweets(d)
      if (!is.null(p$tweets)) {
        hit <- p$tweets[!is.na(p$tweets$tweet_id) & p$tweets$tweet_id == id, , drop = FALSE]
        if (nrow(hit)) {
          focal <- hit[1, ]
          break
        }
      }
    }
    if (!is.null(focal)) {
      rows[[length(rows) + 1L]] <- focal
    } else {
      warning("No se pudo recuperar el tweet: ", u)
    }
    cat("Procesado:", u, "\n")
  }
  tweets <- if (length(rows)) dplyr::bind_rows(rows) else tibble::tibble()
  .save_rds(tweets, dir, "api_tweets_data", save = save)
  tweets
}
