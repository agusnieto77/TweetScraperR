#' Extraer tweets de una l\u00ednea de tiempo de Twitter mediante desplazamiento
#'
#' @description
#' 
#' <a href="https://lifecycle.r-lib.org/articles/stages.html#experimental" target="_blank"><img src="https://lifecycle.r-lib.org/articles/figures/lifecycle-experimental.svg" alt="[Experimental]"></a>
#' 
#' Esta funci\u00f3n extrae tweets de una l\u00ednea de tiempo de Twitter previamente abierta,
#' desplaz\u00e1ndose por la p\u00e1gina para recopilar la informaci\u00f3n deseada.
#'
#' @param objeto Un objeto de sesi\u00f3n de navegador web, por defecto 'timeline'.
#' @param username Character. El nombre de usuario de Twitter cuya l\u00ednea de tiempo se est\u00e1 extrayendo.
#' @param n_tweets Numeric. El n\u00famero m\u00e1ximo de tweets a extraer. Por defecto es 100.
#' @param dir Character. El directorio donde se guardar\u00e1 el archivo RDS con los tweets extra\u00eddos.
#'             Por defecto es el directorio de trabajo actual.
#' @param save Logical. Indica si se debe guardar el resultado en un archivo RDS. Por defecto es TRUE.
#'
#' @return Un tibble con los tweets extra\u00eddos, que incluye las siguientes columnas:
#' \itemize{
#'   \item fecha: La fecha y hora del tweet.
#'   \item usern: El nombre de usuario del autor del tweet.
#'   \item tweet: El texto del tweet.
#'   \item url: La URL completa del tweet.
#'   \item fecha_captura: La fecha y hora en que se captur\u00f3 el tweet.
#'   \item is_original: Indicador booleano de si el tweet es original del usuario especificado.
#'   \item is_retweet: Indicador booleano de si el tweet es un retweet.
#'   \item is_cita: Indicador booleano de si el tweet es una cita.
#' }
#'
#' @details
#' La funci\u00f3n realiza las siguientes acciones:
#' 1. Inicia la extracci\u00f3n de tweets de la l\u00ednea de tiempo.
#' 2. Desplaza la p\u00e1gina hacia abajo para cargar m\u00e1s tweets.
#' 3. Extrae la informaci\u00f3n de los tweets visibles.
#' 4. Contin\u00faa el proceso hasta alcanzar el n\u00famero deseado de tweets o hasta que no se carguen m\u00e1s tweets nuevos.
#' 5. Si save es TRUE, guarda los tweets extra\u00eddos en un archivo RDS en el directorio especificado.
#'
#' La funci\u00f3n utiliza selectores CSS espec\u00edficos para extraer la informaci\u00f3n de los tweets.
#' Si la extracci\u00f3n se detiene antes de alcanzar el n\u00famero deseado de tweets, puede ser debido a
#' limitaciones en la carga de tweets por parte de Twitter o problemas de conexi\u00f3n.
#'
#' @note
#' Esta funci\u00f3n asume que ya se ha abierto una sesi\u00f3n de navegador con la l\u00ednea de tiempo de Twitter
#' utilizando la funci\u00f3n `openTimeline()` u otra funci\u00f3n similar.
#'
#' @examples
#' \dontrun{
#' # Primero, abrir una l\u00ednea de tiempo
#' openTimeline("rstatstweet")
#' 
#' # Luego, extraer tweets y guardar el resultado
#' tweets_extraidos <- getScrollExtract(timeline, "rstatstweet", n_tweets = 200, save = TRUE)
#' 
#' # Extraer tweets sin guardar el resultado
#' tweets_extraidos <- getScrollExtract(timeline, "rstatstweet", n_tweets = 200, save = FALSE)
#' 
#' # Cerrar la l\u00ednea de tiempo despu\u00e9s de la extracci\u00f3n
#' closeTimeline()
#' }
#'
#' @seealso 
#' \code{\link{openTimeline}} para abrir una l\u00ednea de tiempo de Twitter.
#' \code{\link{closeTimeline}} para cerrar la sesi\u00f3n del navegador despu\u00e9s de la extracci\u00f3n.
#'
#' @importFrom tibble tibble
#' @importFrom lubridate as_datetime
#' @importFrom rvest html_attr html_text html_elements
#' @importFrom dplyr distinct
#'
#' @export
#' 
getScrollExtract <- function(
    objeto = timeline,
    username = "rstatstweet",
    n_tweets = 100,
    dir = getwd(),
    save = TRUE
) {
  fech <- "div > div > div > a > time"
  user1 <- "div.css-175oi2r.r-18u37iz.r-1wbh5a2.r-1ez5h0i > div > div.css-175oi2r.r-1wbh5a2.r-dnmrzs > a > div > span"
  tweet <- "#react-root > div > div > div.css-175oi2r.r-1f2l425.r-13qz1uu.r-417010.r-18u37iz > main > div > div > div > div > div > div:nth-child(3) > div > div > section > div > div > div > div > div > article > div > div > div.css-175oi2r.r-18u37iz > div.css-175oi2r.r-1iusvr4.r-16y2uox.r-1777fci.r-kzbkwu > div:nth-child(2)"
  url_tweet <- "div.css-175oi2r.r-18u37iz.r-1wbh5a2.r-1ez5h0i > div > div.css-175oi2r.r-18u37iz.r-1q142lx > a"
  user2 <- "div.css-175oi2r.r-18u37iz.r-1wbh5a2.r-1ez5h0i > div > div.css-175oi2r.r-18u37iz.r-1q142lx > div > a"
  
  nom_ob <- deparse(substitute(objeto))
  tweets_udb <- tibble::tibble()
  i <- 1
  repetitions <- 0
  max_repetitions <- 3
  prev_count <- -1
  cat("Inici\u00f3 la recolecci\u00f3n de tweets.\n")
  while (TRUE) {
    if (nrow(tweets_udb) > n_tweets || repetitions >= max_repetitions) {
      cat("Finaliz\u00f3 la recolecci\u00f3n de tweets.\n")
      break
    }
    i_tweets <- tibble::tibble(
      fecha = lubridate::as_datetime(rvest::html_attr(objeto$html_elements(css = fech), "datetime")),
      usern = rvest::html_text(objeto$html_elements(css = user1)),
      tweet = rvest::html_text(objeto$html_elements(css = tweet)),
      url = rvest::html_attr(objeto$html_elements(css = paste(url_tweet, user2, sep = ", ")), "href"),
      fecha_captura = Sys.time()
    )
    new_count <- nrow(i_tweets)
    if (new_count == prev_count) {
      repetitions <- repetitions + 1
    } else {
      repetitions <- 0
    }
    if (repetitions >= max_repetitions) {
      cat("Finaliz\u00f3 la recolecci\u00f3n de tweets.")
      break
    }
    tweets_udb <- dplyr::distinct(rbind(tweets_udb, i_tweets), url, .keep_all = TRUE)
    prev_count <- new_count
    objeto$scroll_by(top = 4000, left = 0)
    message("Tweets recolectados: ", nrow(tweets_udb))
    Sys.sleep(2.5)
  }
  tweets_udb$url <- paste0("https://x.com", tweets_udb$url)
  tweets_udb$is_original <- tweets_udb$usern == paste0("@", username)
  tweets_udb$is_retweet <- !is.na(tweets_udb$usern) & tweets_udb$usern != paste0("@", username)
  tweets_udb$is_cita <- is.na(tweets_udb$usern)
  
  if (save) {
    saveRDS(tweets_udb, paste0(dir, "/", nom_ob, "_", username, "_", gsub("-|:|\\.", "_", format(Sys.time(), "%Y_%m_%d_%X")), ".rds"))
    cat("Los tweets se han guardado en un archivo RDS.\n")
  } else {
    cat("Los tweets no se han guardado en un archivo RDS.\n")
  }
  
  return(tweets_udb)
}
