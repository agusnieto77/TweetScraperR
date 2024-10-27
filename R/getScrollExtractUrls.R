#' Extraer las urls de los tweets de una línea de tiempo de Twitter mediante desplazamiento
#'
#' @description
#' Esta función extrae las urls de los tweets de una línea de tiempo de Twitter previamente abierta,
#' desplazándose por la página para recopilar la información deseada.
#'
#' @param objeto Un objeto de sesión de navegador web, por defecto 'timeline'.
#' @param username Character. El nombre de usuario de Twitter cuya línea de tiempo se está extrayendo.
#' @param n_tweets Numeric. El número máximo de tweets a extraer. Por defecto es 100.
#' @param dir Character. El directorio donde se guardará el archivo RDS con los tweets extraídos.
#'             Por defecto es el directorio de trabajo actual.
#'
#' @return Un vector con las urls extraídas
#'
#' @details
#' La función realiza las siguientes acciones:
#' 1. Inicia la extracción de tweets de la línea de tiempo.
#' 2. Desplaza la página hacia abajo para cargar más tweets.
#' 3. Extrae las urls de los tweets visibles.
#' 4. Continúa el proceso hasta alcanzar el número deseado de urls o hasta que no se carguen más tweets nuevos.
#' 5. Guarda las urls extraídas en un archivo RDS en el directorio especificado.
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
#' # Luego, extraer tweets
#' urls_extraidas <- getScrollExtractUrls(timeline, "rstatstweet", n_tweets = 200)
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
getScrollExtractUrls <- function(objeto = timeline, username = "rstatstweet", n_tweets = 100, dir = getwd()) {
  fech <- "div > div > div > a > time"
  user1 <- "div.css-175oi2r.r-18u37iz.r-1wbh5a2.r-1ez5h0i > div > div.css-175oi2r.r-1wbh5a2.r-dnmrzs > a > div > span"
  tweet <- "#react-root > div > div > div.css-175oi2r.r-1f2l425.r-13qz1uu.r-417010.r-18u37iz > main > div > div > div > div > div > div:nth-child(3) > div > div > section > div > div > div > div > div > article > div > div > div.css-175oi2r.r-18u37iz > div.css-175oi2r.r-1iusvr4.r-16y2uox.r-1777fci.r-kzbkwu > div:nth-child(2)"
  url_tweet <- "div.css-175oi2r.r-18u37iz.r-1wbh5a2.r-1ez5h0i > div > div.css-175oi2r.r-18u37iz.r-1q142lx > a"
  user2 <- "div.css-175oi2r.r-18u37iz.r-1wbh5a2.r-1ez5h0i > div > div.css-175oi2r.r-18u37iz.r-1q142lx > div > a"
  nom_ob <- deparse(substitute(objeto))
  tweets_udb <- c()
  i <- 1
  repetitions <- 0
  max_repetitions <- 3
  prev_count <- -1
  cat("Inició la recolección de tweets.\n")
  while (TRUE) {
    if (length(tweets_udb) > n_tweets || repetitions >= max_repetitions) {
      cat("Finalizó la recolección de tweets.\n")
      break
    }
    i_tweets <- rvest::html_attr(objeto$html_elements(css = paste(url_tweet, user2, sep = ", ")), "href")
    new_count <- length(i_tweets)
    if (new_count == prev_count) {
      repetitions <- repetitions + 1
    }
    else {
      repetitions <- 0
    }
    if (repetitions >= max_repetitions) {
      cat("Finalizó la recolección de tweets.")
      break
    }
    tweets_udb <- unique(append(tweets_udb, i_tweets))
    prev_count <- new_count
    objeto$scroll_by(top = 4000, left = 0)
    message("Tweets recolectados: ", length(tweets_udb))
    Sys.sleep(2.5)
  }
  tweets_udb <- paste0("https://x.com", tweets_udb)
  saveRDS(tweets_udb, paste0(dir, "/", nom_ob, "_", username, "_", gsub("-|:|\\.", "_", format(Sys.time(), "%Y_%m_%d_%X")), ".rds"))
  return(tweets_udb)
}
