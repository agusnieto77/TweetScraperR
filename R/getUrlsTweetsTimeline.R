#' Get URLs of User Timeline Tweets
#'
#' @description
#'
#' <a href="https://lifecycle.r-lib.org/articles/stages.html#experimental" target="_blank"><img src="https://lifecycle.r-lib.org/articles/figures/lifecycle-experimental.svg" alt="[Experimental]"></a>
#'
#' Esta función recupera URLs de tweets del timeline de unx usuarix especificadx en Twitter.
#' Opcionalmente puede iniciar sesión en Twitter utilizando las credenciales proporcionadas si open=TRUE,
#' navega al perfil del usuarix especificadx, y recopila hasta `n_urls` URLs de tweets.
#' El proceso de recolección se detiene si se alcanza el número máximo de URLs especificado o
#' después de realizar 600 capturas y se detiene el desplazamiento (scroll).
#'
#' @param username El nombre de usuarix de Twitter del cual quieres obtener el timeline. Por defecto es "rstatstweet".
#' @param n_urls El número máximo de URLs de tweets a obtener. Por defecto es 100.
#' @param open Indica si se debe realizar el proceso de autenticación (por defecto FALSE).
#' @param xuser Nombre de usuarix de Twitter para autenticación. Por defecto es el valor de la variable de entorno TWITTER_USER (o, si no está definida, USER).
#' @param xpass Contraseña de Twitter para autenticación. Por defecto es el valor de la variable de entorno TWITTER_PASS (o, si no está definida, PASS).
#' @param max_retries número máximo de intentos de conexión. Por defecto es 3.
#' @param dir Directorio donde se guardará el archivo de salida. Por defecto es el directorio de trabajo actual.
#' @param save Lógico. Indica si se debe guardar el resultado en un archivo RDS (por defecto TRUE).
#' @return Un vector que contiene las URLs de tweets obtenidas.
#' @export
#'
#' @examples
#' \dontrun{
#' # Sin autenticación
#' getUrlsTweetsTimeline(username = "rstatstweet", n_urls = 200)
#'
#' # Con autenticación
#' getUrlsTweetsTimeline(username = "rstatstweet", n_urls = 200, open = TRUE)
#'
#' # Sin guardar los resultados
#' getUrlsTweetsTimeline(username = "rstatstweet", n_urls = 200, save = FALSE)
#' }
#'
#' @importFrom rvest html_elements html_attr
#'

getUrlsTweetsTimeline <- function(
    username = "rstatstweet",
    n_urls = 100,
    open = FALSE,
    xuser = Sys.getenv("TWITTER_USER", Sys.getenv("USER")),
    xpass = Sys.getenv("TWITTER_PASS", Sys.getenv("PASS")),
    max_retries = 3,
    dir = getwd(),
    save = TRUE
) {
  url <- paste0("https://x.com/", username)
  cat("Inici\u00f3 la recolecci\u00f3n de URLs.\n")

  res <- .pw_collect(url, mode = "urls", n_max = n_urls, max_attempts = max_retries)
  if (isTRUE(res$reason == "not_logged_in")) {
    stop("No hay una sesi\u00f3n activa de X. Import\u00e1 tu sesi\u00f3n con importSessionX(auth_token, ct0) antes de scrapear.")
  }
  if (!isTRUE(res$ok)) {
    stop("No se pudo completar la operaci\u00f3n: ", .pw_or(res$error, .pw_or(res$reason, "error desconocido")))
  }
  cat("Finaliz\u00f3 la recolecci\u00f3n de URLs.\n")

  tweets_urls <- res$items
  tweets_urls <- tweets_urls[grep("/status/", tweets_urls)]
  if (length(tweets_urls) > 0) {
    tweets_urls <- utils::head(tweets_urls, n_urls)
    tweets_urls <- ifelse(grepl("^https?://", tweets_urls), tweets_urls, paste0("https://x.com", tweets_urls))
    .save_rds(tweets_urls, dir, paste0("urls_", username), save = save, label = "URLs")
  } else {
    warning("No se encontraron URLs de tweets.")
  }

  return(tweets_urls)
}
