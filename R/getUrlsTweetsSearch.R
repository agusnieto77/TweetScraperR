#' Get Tweets URLs by Search
#'
#' @description
#' 
#' <a href="https://lifecycle.r-lib.org/articles/stages.html#experimental" target="_blank"><img src="https://lifecycle.r-lib.org/articles/figures/lifecycle-experimental.svg" alt="[Experimental]"></a>
#'
#' @description
#' **Obsoleta**: preférí getTweetsSearchAPI(), basada en la API de X (datos del JSON, mas robusta).
#'
#' Esta función recupera URLs de tweets basados en una consulta de búsqueda especifica en Twitter.
#' Utiliza el buscador de Twitter para encontrar tweets que coincidan con el término de búsqueda proporcionado,
#' enfocándose en los tweets destacados que aparecen en la plataforma.
#' Opcionalmente puede iniciar sesión en Twitter usando las credenciales proporcionadas si open=TRUE, realiza la búsqueda, y
#' recolecta las URLs de los tweets que corresponden a la consulta.
#' 
#' La recolección se detiene cuando se ha alcanzado el número especificado de URLs o cuando no se encuentran
#' nuevas URLs después de varios intentos. Las URLs recolectadas se guardan en un archivo RDS en el directorio
#' especificado si el parámetro 'save' es TRUE, y también se devuelven como un vector de cadenas con las urls recolectadas.
#'
#' @param search La consulta de búsqueda para usar en la recuperación de tweets. Por defecto es "#RStats".
#' @param n_urls El número máximo de URLs de tweets a recuperar. Por defecto es 100.
#' @param open Indica si se debe realizar el proceso de autenticación (por defecto FALSE).
#' @param xuser Nombre de usuarix de Twitter para autenticación. Por defecto es el valor de la variable de entorno TWITTER_USER (o, si no está definida, USER).
#' @param xpass Contraseña de Twitter para autenticación. Por defecto es el valor de la variable de entorno TWITTER_PASS (o, si no está definida, PASS).
#' @param max_retries número máximo de intentos de conexión.
#' @param dir Directorio de destino de los RDS.
#' @param save Lógico. Indica si se debe guardar el resultado en un archivo RDS (por defecto TRUE).
#' 
#' @return Un vector que contiene las URLs de tweets recuperadas.
#' @export
#'
#' @examples
#' \dontrun{
#' # Sin autenticación
#' getUrlsTweetsSearch(search = "#RStats", n_urls = 200)
#' 
#' # Con autenticación
#' getUrlsTweetsSearch(search = "#RStats", n_urls = 200, open = TRUE)
#' 
#' # Sin guardar los resultados
#' getUrlsTweetsSearch(search = "#RStats", n_urls = 200, save = FALSE)
#' }
#'
#' @references
#' Puedes encontrar más información sobre el paquete TweetScrapeR en:
#' <https://github.com/agusnieto77/TweetScraperR>
#'
#' @importFrom rvest html_elements html_attr
#'

getUrlsTweetsSearch <- function(
    search = "#RStats",
    n_urls = 100,
    open = FALSE,
    xuser = Sys.getenv("TWITTER_USER", Sys.getenv("USER")),
    xpass = Sys.getenv("TWITTER_PASS", Sys.getenv("PASS")),
    max_retries = 3,
    dir = getwd(),
    save = TRUE
) {
  .Deprecated(msg = "getUrlsTweetsSearch() est\u00e1 obsoleta: us\u00e1 getTweetsSearchAPI() (basada en la API de X, datos estructurados del JSON, m\u00e1s robusta). Ver ?getTweetsSearchAPI.")
  url <- paste0("https://x.com/search?q=", gsub("#", "%23", search), "&src=typed_query")
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
    .save_rds(tweets_urls, dir, paste0("search_", gsub("#", "hashtag_", search)), save = save, label = "URLs")
  } else {
    warning("No se encontraron URLs de tweets.")
  }

  return(tweets_urls)
}
