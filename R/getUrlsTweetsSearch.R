#' Get Tweets URLs by Search
#'
#' @description
#' 
#' <a href="https://lifecycle.r-lib.org/articles/stages.html#experimental" target="_blank"><img src="https://lifecycle.r-lib.org/articles/figures/lifecycle-experimental.svg" alt="[Experimental]"></a>
#' 
#' Esta función recupera URLs de tweets basados en una consulta de búsqueda especifica en Twitter.
#' Utiliza el buscador de Twitter para encontrar tweets que coincidan con el término de búsqueda proporcionado,
#' enfocándose en los tweets destacados que aparecen en la plataforma.
#' La función inicia sesión en Twitter usando las credenciales proporcionadas, realiza la búsqueda, y
#' recolecta las URLs de los tweets que corresponden a la consulta.
#' 
#' La recolección se detiene cuando se ha alcanzado el número especificado de URLs o cuando no se encuentran
#' nuevas URLs después de varios intentos. Las URLs recolectadas se guardan en un archivo RDS en el directorio
#' especificado si el parámetro 'save' es TRUE, y también se devuelven como un vector de cadenas con las urls recolectadas.
#'
#' @param search La consulta de búsqueda para usar en la recuperación de tweets. Por defecto es "#RStats".
#' @param n_urls El número máximo de URLs de tweets a recuperar. Por defecto es 100.
#' @param xuser Nombre de usuarix de Twitter para autenticación. Por defecto es el valor de la variable de entorno del sistema USER.
#' @param xpass Contraseña de Twitter para autenticación. Por defecto es el valor de la variable de entorno del sistema PASS.
#' @param max_retries número máximo de intentos de conexión.
#' @param dir Directorio de destino de los RDS.
#' @param save Lógico. Indica si se debe guardar el resultado en un archivo RDS (por defecto TRUE).
#' 
#' @return Un vector que contiene las URLs de tweets recuperadas.
#' @export
#'
#' @examples
#' \dontrun{
#' getUrlsTweetsSearch(search = "#RStats", n_urls = 200)
#' 
#' # Sin guardar los resultados
#' getUrlsTweetsSearch(search = "#RStats", n_urls = 200, save = FALSE)
#' }
#'
#' @references
#' Puedes encontrar más información sobre el paquete TweetScrapeR en:
#' <https://github.com/agusnieto77/TweetScraperR>
#'
#' @importFrom rvest read_html_live html_elements html_attr
#' 

getUrlsTweetsSearch <- function(
    search = "#RStats",
    n_urls = 100,
    xuser = Sys.getenv("USER"),
    xpass = Sys.getenv("PASS"),
    max_retries = 3,
    dir = getwd(),
    save = TRUE
) {
  retry_count <- 0
  success <- FALSE
  while (retry_count < max_retries && !success) {
    tryCatch({
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
      searchok <- rvest::read_html_live(paste0("https://x.com/search?q=", gsub("#", "%23", search), "&src=typed_query"))
      Sys.sleep(3)
      url_tweet <- "div.css-175oi2r > div > div.css-175oi2r > a.css-146c3p1.r-bcqeeo.r-1ttztb7.r-qvutc0.r-37j5jr.r-a023e6"
      tweets_urls <- c()
      i <- 1
      repetitions <- 0
      max_repetitions <- 2
      cat("Inició la recolección de URLs.\n")
      while (TRUE) {
        urls_tweets <- rvest::html_attr(searchok$html_elements(css = url_tweet), "href")
        if (length(tweets_urls) > n_urls || repetitions >= max_repetitions) {
          cat("Finalizó la recolección de URLs.\n")
          break
        }
        urls_tweets <- urls_tweets[grep("/status/", urls_tweets)]
        new_tweets <- unique(urls_tweets[!urls_tweets %in% tweets_urls])
        tweets_urls <- unique(append(tweets_urls, new_tweets))
        Sys.sleep(2.5)
        searchok$scroll_by(top = 4000, left = 0)
        message("URLs recolectadas: ", length(tweets_urls))
        Sys.sleep(2.5)
        if (length(new_tweets) == 0) {
          repetitions <- repetitions + 1
        } else {
          repetitions <- 0
        }
        i <- i + 1
      }
      twitter$session$close()
      searchok$session$close()
      success <- TRUE
    }, error = function(e) {
      message("Error: ", e$message)
      retry_count <- retry_count + 1
      message("Reintentando... (Intento ", retry_count, " de ", max_retries, ")")
      Sys.sleep(5)
    })
  }
  if (!success) {
    stop("No se pudo completar la operación después de ", max_retries, " intentos.")
  }
  if (length(tweets_urls) > 0) {
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
