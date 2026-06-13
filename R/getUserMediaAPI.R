# Media de un usuario via API GraphQL/JSON de X (experimental, 0.4.0) -------

#' Get a User's Media Tweets via the X API (experimental)
#'
#' @description
#'
#' <a href="https://lifecycle.r-lib.org/articles/stages.html#experimental" target="_blank"><img src="https://lifecycle.r-lib.org/articles/figures/lifecycle-experimental.svg" alt="[Experimental]"></a>
#'
#' Recupera los tweets con media (fotos/videos) de unx usuarix consultando la
#' **API GraphQL interna de X** (UserMedia). Devuelve datos estructurados del
#' JSON. Requiere una sesion importada con [importSessionX()].
#'
#' @param username Nombre de usuarix (sin @). Por defecto "NASA".
#' @param n_tweets Numero maximo de tweets a recuperar. Por defecto 40.
#' @param dir Directorio de destino del RDS. Por defecto el de trabajo.
#' @param save Logico. Si TRUE (por defecto) guarda el resultado en un RDS.
#'
#' @return Un tibble con un tweet por fila (mismas columnas que getUserTweetsAPI).
#' @export
#'
#' @examples
#' \dontrun{
#' importSessionX(auth_token = "...", ct0 = "...")
#' getUserMediaAPI("NASA", n_tweets = 100)
#' }
getUserMediaAPI <- function(username = "NASA", n_tweets = 40, dir = getwd(), save = TRUE) {
  if (!nzchar(username)) stop("Necesito un nombre de usuarix.")
  url <- paste0("https://x.com/", username, "/media")
  cat("Recolectando media de @", username, "...\n", sep = "")
  scrolls <- max(3L, as.integer(ceiling(n_tweets / 15) + 3L))
  docs <- .pw_harvest(url, "UserMedia", max_scrolls = scrolls)

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
  cat("Tweets de media recolectados:", nrow(tweets), "\n")
  .save_rds(tweets, dir, paste0("api_media_", username), save = save)
  tweets
}
