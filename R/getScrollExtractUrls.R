#' Extract Tweet URLs from a Timeline by Scrolling
#'
#' @description
#' 
#' <a href="https://lifecycle.r-lib.org/articles/stages.html#experimental" target="_blank"><img src="https://lifecycle.r-lib.org/articles/figures/lifecycle-experimental.svg" alt="[Experimental]"></a>
#' 
#' Esta función extrae las urls de los tweets de una línea de tiempo de Twitter previamente abierta,
#' desplazándose por la página para recopilar la información deseada.
#'
#' @param objeto Un objeto de sesión de navegador web, por defecto 'timeline'.
#' @param username Character. El nombre de usuario de Twitter cuya línea de tiempo se está extrayendo.
#' @param n_tweets Numeric. El número máximo de tweets a extraer. Por defecto es 100.
#' @param dir Character. El directorio donde se guardará el archivo RDS con los tweets extraídos.
#'             Por defecto es el directorio de trabajo actual.
#' @param save Logical. Indica si se debe guardar el resultado en un archivo RDS. Por defecto es TRUE.
#'
#' @return Un vector con las urls extraídas
#'
#' @details
#' La función realiza las siguientes acciones:
#' 1. Inicia la extracción de tweets de la línea de tiempo.
#' 2. Desplaza la página hacia abajo para cargar más tweets.
#' 3. Extrae las urls de los tweets visibles.
#' 4. Continúa el proceso hasta alcanzar el número deseado de urls o hasta que no se carguen más tweets nuevos.
#' 5. Si save es TRUE, guarda las urls extraídas en un archivo RDS en el directorio especificado.
#'
#' La función utiliza selectores CSS específicos para extraer la url de los tweets.
#' Si la extracción se detiene antes de alcanzar el número deseado de tweets, puede ser debido a
#' limitaciones en la carga de tweets por parte de Twitter o problemas de conexión.
#'
#' @note
#' Esta función asume que ya se ha abierto una sesión de navegador con la línea de tiempo de Twitter
#' utilizando la función `openTimeline()` u otra función similar.
#'
#' @examples
#' \dontrun{
#' # Primero, abrir una línea de tiempo
#' openTimeline("rstatstweet")
#' 
#' # Luego, extraer tweets y guardar el resultado
#' urls_extraidas <- getScrollExtractUrls(timeline, "rstatstweet", n_tweets = 200, save = TRUE)
#' 
#' # Extraer tweets sin guardar el resultado
#' urls_extraidas <- getScrollExtractUrls(timeline, "rstatstweet", n_tweets = 200, save = FALSE)
#' 
#' # Cerrar la línea de tiempo después de la extracción
#' closeTimeline()
#' }
#'
#' @seealso 
#' \code{\link{openTimeline}} para abrir una línea de tiempo de Twitter.
#' \code{\link{closeTimeline}} para cerrar la sesión del navegador después de la extracción.
#'
#' @importFrom rvest html_attr html_text html_elements
#'
#' @export
#' 

getScrollExtractUrls <- function(objeto = timeline,
                                 username = "rstatstweet",
                                 n_tweets = 100,
                                 dir = getwd(),
                                 save = TRUE) {
  nom_ob <- deparse(substitute(objeto))
  url <- paste0("https://x.com/", username)
  cat("Inici\u00f3 la recolecci\u00f3n de tweets.\n")

  res <- .pw_collect(url, mode = "urls", n_max = n_tweets, max_attempts = 3)
  if (isTRUE(res$reason == "not_logged_in")) {
    stop("No hay una sesi\u00f3n activa de X. Import\u00e1 tu sesi\u00f3n con importSessionX(auth_token, ct0) antes de scrapear.")
  }
  if (!isTRUE(res$ok)) {
    stop("No se pudo completar la operaci\u00f3n: ", .pw_or(res$error, .pw_or(res$reason, "error desconocido")))
  }
  cat("Finaliz\u00f3 la recolecci\u00f3n de tweets.\n")

  tweets_udb <- res$items
  tweets_udb <- tweets_udb[grep("/status/", tweets_udb)]
  if (length(tweets_udb) > 0) {
    tweets_udb <- utils::head(tweets_udb, n_tweets)
    tweets_udb <- ifelse(grepl("^https?://", tweets_udb), tweets_udb, paste0("https://x.com", tweets_udb))
    .save_rds(tweets_udb, dir, paste0(nom_ob, "_", username), save = save, label = "URLs")
  } else {
    warning("No se encontraron URLs de tweets.")
  }

  return(tweets_udb)
}
