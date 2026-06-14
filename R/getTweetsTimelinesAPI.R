# Timeline combinado de varias cuentas via API GraphQL/JSON (experimental) --
#
# Reemplaza el flujo "Lista de X": en vez de necesitar un list_id pre-armado,
# toma directamente un vector de cuentas y devuelve su timeline combinado,
# reusando el batch de harvest (un solo navegador para todas las cuentas).

#' Normaliza una cuenta: acepta "handle", "@handle" o la URL completa
#' @noRd
.x_handle <- function(x) {
  x <- gsub("^@|^https?://(www\\.)?(x|twitter)\\.com/", "", trimws(x))
  sub("/.*$", "", x)
}

#' Get the Combined Timeline of Several Users via the X API (experimental)
#'
#' @description
#'
#' <a href="https://lifecycle.r-lib.org/articles/stages.html#experimental" target="_blank"><img src="https://lifecycle.r-lib.org/articles/figures/lifecycle-experimental.svg" alt="[Experimental]"></a>
#'
#' Recupera y combina los timelines de varias cuentas consultando la **API
#' GraphQL interna de X**, en una sola sesion de navegador (batch). Util para
#' monitorear un conjunto curado de cuentas (lo que harias con una Lista de X,
#' pero sin necesitar un list_id). Devuelve un unico tibble ordenado por fecha
#' (mas reciente primero) y deduplicado. Requiere una sesion importada con
#' [importSessionX()].
#'
#' @param usernames Vector de nombres de usuarix (acepta "NASA", "@NASA" o la
#'   URL completa "https://x.com/NASA").
#' @param n_tweets Numero maximo de tweets a recuperar **por cuenta**. Por
#'   defecto 40.
#' @param dir Directorio de destino del RDS. Por defecto el de trabajo.
#' @param save Logico. Si TRUE (por defecto) guarda el resultado en un RDS.
#'
#' @return Un tibble con un tweet por fila (mismas columnas que
#'   [getUserTweetsAPI()]), combinado y ordenado por fecha.
#' @export
#'
#' @examples
#' \dontrun{
#' importSessionX(auth_token = "...", ct0 = "...")
#' getTweetsTimelinesAPI(c("elravignani", "NucleoIdaes", "BNMMArgentina"), n_tweets = 100)
#' }
getTweetsTimelinesAPI <- function(usernames, n_tweets = 40, dir = getwd(), save = TRUE) {
  if (missing(usernames) || !length(usernames)) {
    stop("Necesito al menos un nombre de usuarix.")
  }
  # Normalizar: aceptar "@handle", "handle" o la URL completa.
  usernames <- .x_handle(usernames)
  cat("Recolectando timelines de ", length(usernames), " cuentas...\n", sep = "")

  scrolls <- max(3L, as.integer(ceiling(n_tweets / 15) + 3L))
  grupos <- .pw_harvest_batch(paste0("https://x.com/", usernames), "UserTweets", max_scrolls = scrolls)

  acc <- list()
  for (k in seq_along(grupos)) {
    rows <- list()
    for (d in grupos[[k]]) {
      p <- .parse_timeline_tweets(d)
      if (!is.null(p$tweets)) rows[[length(rows) + 1L]] <- p$tweets
    }
    n_k <- 0L
    if (length(rows)) {
      tw <- dplyr::distinct(dplyr::bind_rows(rows), tweet_id, .keep_all = TRUE)
      tw <- utils::head(tw, n_tweets)
      acc[[length(acc) + 1L]] <- tw
      n_k <- nrow(tw)
    } else {
      warning("Sin tweets para @", usernames[k], " (\u00bfprotegida o inexistente?).")
    }
    cat("  @", usernames[k], ": ", n_k, " tweets\n", sep = "")
  }

  tweets <- if (length(acc)) dplyr::bind_rows(acc) else tibble::tibble()
  if (nrow(tweets)) {
    tweets <- dplyr::distinct(tweets, tweet_id, .keep_all = TRUE)
    tweets <- tweets[order(tweets$fecha, decreasing = TRUE), , drop = FALSE]
  }
  cat("Total combinado:", nrow(tweets), "tweets de", length(usernames), "cuentas.\n")
  .save_rds(tweets, dir, "api_timelines", save = save)
  tweets
}
