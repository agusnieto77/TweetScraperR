# Respuestas/hilo via API GraphQL/JSON de X (experimental, rumbo a 0.4.0) ---
#
# TweetDetail exige x-client-transaction-id, asi que se cosecha la respuesta
# JSON que dispara la app al navegar el tweet (.pw_harvest). Las respuestas
# vienen en entries `conversationthread-*`, que el parser .parse_timeline_tweets
# ya desarma (via .entry_tweet_results).

#' Get Tweet Replies / Thread via the X API (experimental)
#'
#' @description
#'
#' <a href="https://lifecycle.r-lib.org/articles/stages.html#experimental" target="_blank"><img src="https://lifecycle.r-lib.org/articles/figures/lifecycle-experimental.svg" alt="[Experimental]"></a>
#'
#' Recupera el tweet y sus respuestas (hilo de conversacion) consultando la
#' **API GraphQL interna de X**. Devuelve datos estructurados del JSON. Requiere
#' una sesion importada con [importSessionX()].
#'
#' @param url URL del tweet del cual obtener las respuestas.
#' @param n_tweets Numero maximo de tweets (tweet + respuestas) a recuperar.
#'   Por defecto 40.
#' @param dir Directorio de destino del RDS. Por defecto el de trabajo.
#' @param save Logico. Si TRUE (por defecto) guarda el resultado en un RDS.
#'
#' @return Un tibble con un tweet por fila (el tweet original y sus respuestas),
#'   con columnas fecha, user, texto, respuestas, retweets, citas, megustas,
#'   views, es_retweet, es_cita, url, tweet_id.
#' @export
#'
#' @examples
#' \dontrun{
#' importSessionX(auth_token = "...", ct0 = "...")
#' getTweetsRepliesAPI("https://x.com/NASA/status/123", n_tweets = 100)
#' }
getTweetsRepliesAPI <- function(url, n_tweets = 40, dir = getwd(), save = TRUE) {
  if (missing(url) || !nzchar(url)) stop("Necesito la URL de un tweet.")
  cat("Recolectando respuestas de: ", url, "\n", sep = "")
  scrolls <- max(3L, as.integer(ceiling(n_tweets / 15) + 3L))
  docs <- .pw_harvest(url, "TweetDetail", max_scrolls = scrolls)

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

  prefix <- paste0("api_replies_", gsub("https://x.com/(.*)/status/(.*)", "\\1_\\2", url))
  .save_rds(tweets, dir, prefix, save = save)
  tweets
}
