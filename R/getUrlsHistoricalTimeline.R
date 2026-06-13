#' Get Historical Tweet URLs from a User Timeline
#'
#' @description
#'
#' <a href="https://lifecycle.r-lib.org/articles/stages.html#experimental" target="_blank"><img src="https://lifecycle.r-lib.org/articles/figures/lifecycle-experimental.svg" alt="[Experimental]"></a>
#'
#' Esta función recupera URLs de tweets del timeline histórico de unx usuarix en Twitter,
#' basado en un rango de fechas especificado. Opcionalmente puede realizar la autenticación en Twitter
#' mediante el nombre de usuarix y la contraseña proporcionados, o los valores predeterminados de
#' las variables de entorno del sistema. Después de autenticar al usuarix (si open=TRUE), la función
#' realiza una búsqueda de tweets publicados por le usuarix especificadx dentro del rango
#' de fechas definido por los parámetros `since` y `until`. Las URLs de los tweets encontrados
#' se recogen hasta alcanzar el número máximo de URLs especificado por el parámetro `n_urls` o
#' hasta que no se encuentren nuevas URLs en varios intentos consecutivos. Los resultados se
#' guardan en un archivo con formato `.rds` en el directorio especificado por el parámetro `dir`
#' si el parámetro `save` es TRUE.
#'
#' @param username Nombre de usuarix de Twitter del que se desean recuperar los tweets. Por defecto es "rstatstweet".
#' @param timeout Tiempo de espera entre solicitudes en segundos. Por defecto es 10.
#' @param n_urls El número máximo de URLs de tweets a recuperar. Por defecto es 100.
#' @param since Fecha de inicio para la búsqueda de tweets (en formato "YYYY-MM-DD"). Por defecto es "2018-10-26".
#' @param until Fecha de fin para la búsqueda de tweets (en formato "YYYY-MM-DD"). Por defecto es "2018-10-30".
#' @param open Indica si se debe realizar el proceso de autenticación (por defecto FALSE).
#' @param xuser Nombre de usuarix de Twitter para autenticación. Por defecto es el valor de la variable de entorno TWITTER_USER (o, si no está definida, USER).
#' @param xpass Contraseña de Twitter para autenticación. Por defecto es el valor de la variable de entorno TWITTER_PASS (o, si no está definida, PASS).
#' @param dir Directorio para guardar el archivo RDS con las URLs recolectadas. Por defecto es el directorio de trabajo actual.
#' @param save Lógico. Indica si se debe guardar el resultado en un archivo RDS (por defecto TRUE).
#' @return Un vector que contiene las URLs de tweets recuperadas.
#' @export
#'
#' @examples
#' \dontrun{
#' # Sin autenticación
#' getUrlsHistoricalTimeline(
#'   username = "rstatstweet", n_urls = 50,
#'   since = "2018-10-26", until = "2018-10-30"
#' )
#'
#' # Con autenticación
#' getUrlsHistoricalTimeline(
#'   username = "rstatstweet", n_urls = 50,
#'   since = "2018-10-26", until = "2018-10-30",
#'   open = TRUE
#' )
#'
#' # Sin guardar los resultados
#' getUrlsHistoricalTimeline(
#'   username = "rstatstweet", n_urls = 50,
#'   since = "2018-10-26", until = "2018-10-30",
#'   save = FALSE
#' )
#' }
#'
#' @references
#' Puedes encontrar más información sobre el paquete TweetScrapeR en:
#' <https://github.com/agusnieto77/TweetScraperR>
#'
#' @importFrom rvest html_elements html_attr
#'

getUrlsHistoricalTimeline <- function(
    username = "rstatstweet",
    timeout = 10,
    n_urls = 100,
    since = "2018-10-26",
    until = "2018-10-30",
    open = FALSE,
    xuser = Sys.getenv("TWITTER_USER", Sys.getenv("USER")),
    xpass = Sys.getenv("TWITTER_PASS", Sys.getenv("PASS")),
    dir = getwd(),
    save = TRUE
) {
  usersearh <- paste0("https://x.com/search?f=live&q=%28from%3A", username, "%29+until%3A", until, "+since%3A", since, "&src=typed_query")
  cat("Inici\u00f3 la recolecci\u00f3n de URLs.\n")

  res <- .pw_collect(usersearh, mode = "urls", n_max = n_urls, max_attempts = 3)
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
    .save_rds(tweets_urls, dir, paste0("urls_historical_timeline_", username), save = save, label = "URLs")
  } else {
    warning("No se encontraron URLs de tweets.")
  }
  return(tweets_urls)
}
