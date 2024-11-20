#' Get URLs of User Timeline Tweets
#'
#' @description
#' 
#' <a href="https://lifecycle.r-lib.org/articles/stages.html#experimental" target="_blank"><img src="https://lifecycle.r-lib.org/articles/figures/lifecycle-experimental.svg" alt="[Experimental]"></a>
#' 
#' Esta función recupera URLs de tweets del timeline de unx usuarix especificadx en Twitter. 
#' Inicia sesión en Twitter utilizando las credenciales proporcionadas, navega al perfil del 
#' usuarix especificadx, y recopila hasta `n_urls` URLs de tweets. 
#' El proceso de recolección se detiene si se alcanza el número máximo de URLs especificado o 
#' después de realizar 600 capturas y se detiene el desplazamiento (scroll).
#'
#' @param username El nombre de usuarix de Twitter del cual quieres obtener el timeline. Por defecto es "rstatstweet".
#' @param n_urls El número máximo de URLs de tweets a obtener. Por defecto es 100.
#' @param xuser Nombre de usuarix de Twitter para autenticación. Por defecto es el valor de la variable de entorno del sistema USER.
#' @param xpass Contraseña de Twitter para autenticación. Por defecto es el valor de la variable de entorno del sistema PASS.
#' @param dir Directorio donde se guardará el archivo de salida. Por defecto es el directorio de trabajo actual.
#' @param save Lógico. Indica si se debe guardar el resultado en un archivo RDS (por defecto TRUE).
#' @return Un vector que contiene las URLs de tweets obtenidas.
#' @export
#'
#' @examples
#' \dontrun{
#' getUrlsTweetsTimeline(username = "rstatstweet", n_urls = 200)
#' 
#' # Sin guardar los resultados
#' getUrlsTweetsTimeline(username = "rstatstweet", n_urls = 200, save = FALSE)
#' }
#'
#' @importFrom rvest read_html_live html_elements html_attr
#' 

getUrlsTweetsTimeline <- function(
    username = "rstatstweet",
    n_urls = 100,
    xuser = Sys.getenv("USER"),
    xpass = Sys.getenv("PASS"),
    dir = getwd(),
    save = TRUE
) {
  twitter <- rvest::read_html_live("https://x.com/i/flow/login")
  Sys.sleep(3)
  userx <- "#layers > div > div > div > div > div > div > div.css-175oi2r > div.css-175oi2r > div > div > div.css-175oi2r > div.css-175oi2r > div > div > div > div.css-175oi2r > label > div > div.css-175oi2r > div > input"
  nextx <- "#layers div > div > div > button:nth-child(6) > div"
  passx <- "#layers > div > div > div > div > div > div > div > div > div > div > div > div > div > div > div > div > div > label > div > div > div > input"
  login <- "#layers > div > div > div > div > div > div > div.css-175oi2r > div.css-175oi2r > div > div > div.css-175oi2r > div.css-175oi2r.r-16y2uox > div.css-175oi2r > div > div.css-175oi2r > div > div > button"
  twitter$type(css = userx, text = xuser)
  twitter$click(css = nextx, n_clicks = 1)
  Sys.sleep(2)
  twitter$type(css = passx, text = xpass)
  twitter$click(css = login, n_clicks = 1)
  Sys.sleep(2)
  usernameok <- rvest::read_html_live(paste0("https://x.com/", username))
  Sys.sleep(3)
  url_tweet <- "div.css-175oi2r > div > div.css-175oi2r > a.css-146c3p1.r-bcqeeo.r-1ttztb7.r-qvutc0.r-37j5jr.r-a023e6"
  tweets_urls <- c()
  repetitions <- 0
  max_repetitions <- 2
  cat("Inició la recolección de URLs.\n")
  while (TRUE) {
    urls_tweets <- rvest::html_attr(usernameok$html_elements(css = url_tweet), "href")
    if (length(tweets_urls) > n_urls || repetitions >= max_repetitions) {
      cat("Finalizó la recolección de URLs.\n")
      break
    }
    urls_tweets <- urls_tweets[grep("/status/", urls_tweets)]
    new_tweets <- unique(urls_tweets[!urls_tweets %in% tweets_urls])
    tweets_urls <- unique(append(tweets_urls, new_tweets))
    usernameok$scroll_by(top = 4000, left = 0)
    message("URLs recolectadas: ", length(tweets_urls))
    Sys.sleep(2.5)
    if (length(new_tweets) == 0) {
      repetitions <- repetitions + 1
    } else {
      repetitions <- 0
    }
  }
  twitter$session$close()
  usernameok$session$close()
  tweets_urls <- paste0("https://x.com", tweets_urls)
  
  if (save) {
    saveRDS(tweets_urls, file.path(dir, paste0("urls_", username, "_", gsub("-|:|\\.", "_", format(Sys.time(), "%Y_%m_%d_%X")), ".rds")))
    cat("URLs procesadas y guardadas.\n")
  } else {
    cat("URLs procesadas. No se han guardado en un archivo RDS.\n")
  }
  
  return(tweets_urls)
}
