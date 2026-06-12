#' Get Tweets URLs by Search
#'
#' @description
#' 
#' <a href="https://lifecycle.r-lib.org/articles/stages.html#experimental" target="_blank"><img src="https://lifecycle.r-lib.org/articles/figures/lifecycle-experimental.svg" alt="[Experimental]"></a>
#' 
#' Esta funci\u00f3n recupera URLs de tweets basados en una consulta de b\u00fasqueda especifica en Twitter.
#' Utiliza el buscador de Twitter para encontrar tweets que coincidan con el t\u00e9rmino de b\u00fasqueda proporcionado,
#' enfoc\u00e1ndose en los tweets destacados que aparecen en la plataforma.
#' Opcionalmente puede iniciar sesi\u00f3n en Twitter usando las credenciales proporcionadas si open=TRUE, realiza la b\u00fasqueda, y
#' recolecta las URLs de los tweets que corresponden a la consulta.
#' 
#' La recolecci\u00f3n se detiene cuando se ha alcanzado el n\u00famero especificado de URLs o cuando no se encuentran
#' nuevas URLs despu\u00e9s de varios intentos. Las URLs recolectadas se guardan en un archivo RDS en el directorio
#' especificado si el par\u00e1metro 'save' es TRUE, y tambi\u00e9n se devuelven como un vector de cadenas con las urls recolectadas.
#'
#' @param search La consulta de b\u00fasqueda para usar en la recuperaci\u00f3n de tweets. Por defecto es "#RStats".
#' @param n_urls El n\u00famero m\u00e1ximo de URLs de tweets a recuperar. Por defecto es 100.
#' @param open Indica si se debe realizar el proceso de autenticaci\u00f3n (por defecto FALSE).
#' @param xuser Nombre de usuarix de Twitter para autenticaci\u00f3n. Por defecto es el valor de la variable de entorno del sistema USER.
#' @param xpass Contrase\u00f1a de Twitter para autenticaci\u00f3n. Por defecto es el valor de la variable de entorno del sistema PASS.
#' @param max_retries n\u00famero m\u00e1ximo de intentos de conexi\u00f3n.
#' @param dir Directorio de destino de los RDS.
#' @param save L\u00f3gico. Indica si se debe guardar el resultado en un archivo RDS (por defecto TRUE).
#' 
#' @return Un vector que contiene las URLs de tweets recuperadas.
#' @export
#'
#' @examples
#' \dontrun{
#' # Sin autenticaci\u00f3n
#' getUrlsTweetsSearch(search = "#RStats", n_urls = 200)
#' 
#' # Con autenticaci\u00f3n
#' getUrlsTweetsSearch(search = "#RStats", n_urls = 200, open = TRUE)
#' 
#' # Sin guardar los resultados
#' getUrlsTweetsSearch(search = "#RStats", n_urls = 200, save = FALSE)
#' }
#'
#' @references
#' Puedes encontrar m\u00e1s informaci\u00f3n sobre el paquete TweetScrapeR en:
#' <https://github.com/agusnieto77/TweetScraperR>
#'
#' @importFrom rvest read_html_live html_elements html_attr
#' 

getUrlsTweetsSearch <- function(
    search = "#RStats",
    n_urls = 100,
    open = FALSE,
    xuser = Sys.getenv("USER"),
    xpass = Sys.getenv("PASS"),
    max_retries = 3,
    dir = getwd(),
    save = TRUE
) {
  global_retry_count <- 0
  success <- FALSE
  twitter <- NULL
  searchok <- NULL
  tweets_urls <- c()
  
  while (global_retry_count < max_retries && !success) {
    tryCatch({
      if (open) {
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
      }
      
      searchok <- rvest::read_html_live(paste0("https://x.com/search?q=", gsub("#", "%23", search), "&src=typed_query"))
      Sys.sleep(3)
      url_tweet <- "div.css-175oi2r > div > div.css-175oi2r > a.css-146c3p1.r-bcqeeo.r-1ttztb7.r-qvutc0.r-37j5jr.r-a023e6"
      tweets_urls <- c()
      repetitions <- 0
      max_repetitions <- 3
      cat("Inici\u00f3 la recolecci\u00f3n de URLs.\n")
      
      while (TRUE) {
        if (length(tweets_urls) >= n_urls || repetitions >= max_repetitions) {
          cat("Finaliz\u00f3 la recolecci\u00f3n de URLs.\n")
          break
        }
        
        urls_tweets <- rvest::html_attr(searchok$html_elements(css = url_tweet), "href")
        urls_tweets <- urls_tweets[grep("/status/", urls_tweets)]
        new_tweets <- unique(urls_tweets[!urls_tweets %in% tweets_urls])
        tweets_urls <- unique(c(tweets_urls, new_tweets))
        
        searchok$scroll_by(top = 4000, left = 0)
        message("URLs recolectadas: ", length(tweets_urls))
        Sys.sleep(2.5)
        
        if (length(new_tweets) == 0) {
          repetitions <- repetitions + 1
        } else {
          repetitions <- 0
        }
      }
      
      success <- TRUE
      
    }, error = function(e) {
      message("Error: ", e$message)
      global_retry_count <- global_retry_count + 1
      message("Reintentando... (Intento ", global_retry_count, " de ", max_retries, ")")
      Sys.sleep(5)
    })
  }
  
  # Cerrar sesiones
  if (!is.null(searchok)) {
    searchok$session$close()
  }
  if (!is.null(twitter)) {
    twitter$session$close()
  }
  
  if (!success) {
    stop("No se pudo completar la operaci\u00f3n despu\u00e9s de ", max_retries, " intentos.")
  }
  
  if (length(tweets_urls) > 0) {
    tweets_urls <- tweets_urls[1:min(length(tweets_urls), n_urls)]  # Limitar al n\u00famero solicitado
    tweets_urls <- paste0("https://x.com", tweets_urls)
    if (save) {
      saveRDS(tweets_urls, paste0(dir, "/search_", gsub("#", "hashtag_", search), "_", gsub("-|:|\\.", "_", format(Sys.time(), "%Y_%m_%d_%X")), ".rds"))
      cat("URLs procesadas y guardadas.\n")
    } else {
      cat("URLs procesadas. No se han guardado en un archivo RDS.\n")
    }
  } else {
    warning("No se encontraron URLs de tweets.")
  }
  
  return(tweets_urls)
}
