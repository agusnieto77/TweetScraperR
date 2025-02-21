#' Get Tweets URLs Replies
#'
#' @description
#' 
#' <a href="https://lifecycle.r-lib.org/articles/stages.html#experimental" target="_blank"><img src="https://lifecycle.r-lib.org/articles/figures/lifecycle-experimental.svg" alt="[Experimental]"></a>
#' 
#' Esta función recupera las URLs de las respuestas a un tweet específico en Twitter (ahora X).
#' Utiliza web scraping para acceder a la página del tweet, iniciar sesión con las credenciales proporcionadas,
#' y recolectar las URLs de las respuestas al tweet.
#' 
#' El proceso incluye:
#' 1. Iniciar sesión en Twitter usando las credenciales proporcionadas.
#' 2. Navegar a la URL del tweet especificado.
#' 3. Extraer las URLs de las respuestas mediante scraping.
#' 4. Continuar scrolling y recolectando URLs hasta alcanzar el número deseado o no encontrar nuevas URLs.
#' 
#' La función guarda las URLs recolectadas en un archivo RDS en el directorio especificado si el parámetro 'save' es TRUE,
#' y las devuelve como un vector de cadenas.
#'
#' @param url URL del tweet del cual se quieren obtener las respuestas. Por defecto es "https://x.com/Picanumeros/status/1610715405705789442".
#' @param n_urls El número máximo de URLs de respuestas a recuperar. Por defecto es 100.
#' @param xuser Nombre de usuario de Twitter para autenticación. Por defecto es el valor de la variable de entorno del sistema USER.
#' @param xpass Contraseña de Twitter para autenticación. Por defecto es el valor de la variable de entorno del sistema PASS.
#' @param view Ver el navegador. Por defecto es FALSE.
#' @param dir Directorio donde se guardará el archivo RDS con las URLs recolectadas. Por defecto es el directorio de trabajo actual.
#' @param save Lógico. Indica si se debe guardar el resultado en un archivo RDS (por defecto TRUE).
#'
#' @return Un vector que contiene las URLs de las respuestas al tweet especificado.
#' @export
#'
#' @examples
#' \dontrun{
#' getUrlsTweetsReplies(url = "https://x.com/Picanumeros/status/1610715405705789442", n_urls = 130)
#' 
#' # Sin guardar los resultados
#' getUrlsTweetsReplies(url = "https://x.com/Picanumeros/status/1610715405705789442", n_urls = 130, save = FALSE)
#' }
#'
#' @references
#' Puedes encontrar más información sobre el paquete TweetScraperR en:
#' <https://github.com/agusnieto77/TweetScraperR>
#'
#' @importFrom rvest read_html_live html_elements html_attr
#'
#' @note
#' Esta función utiliza web scraping y puede ser sensible a cambios en la estructura de la página de Twitter.

getUrlsTweetsReplies <- function(
    url = "https://x.com/Picanumeros/status/1610715405705789442",
    n_urls = 100,
    xuser = Sys.getenv("USER"),
    xpass = Sys.getenv("PASS"),
    view = FALSE,
    dir = getwd(),
    save = TRUE
) {
  retry_count <- 0
  max_retries <- 3
  success <- FALSE
  while (retry_count < max_retries && !success) {
    tryCatch({
      # twitter <- rvest::read_html_live("https://x.com/i/flow/login")
      # Sys.sleep(3)
      # userx <- "#layers > div > div > div > div > div > div > div.css-175oi2r > div.css-175oi2r > div > div > div.css-175oi2r > div.css-175oi2r > div > div > div > div.css-175oi2r > label > div > div.css-175oi2r > div > input"
      # nextx <- "#layers div > div > div > button:nth-child(6) > div"
      # passx <- "#layers > div > div > div > div > div > div > div > div > div > div > div > div > div > div > div > div > div > label > div > div > div > input"
      # login <- "#layers > div > div > div > div > div > div > div.css-175oi2r > div.css-175oi2r > div > div > div.css-175oi2r > div.css-175oi2r.r-16y2uox > div.css-175oi2r > div > div.css-175oi2r > div > div > button"
      # twitter$type(css = userx, text = xuser)
      # twitter$click(css = nextx, n_clicks = 1)
      # Sys.sleep(2)
      # twitter$type(css = passx, text = xpass)
      # twitter$click(css = login, n_clicks = 1)
      # Sys.sleep(2)
      urlok <- rvest::read_html_live(url)
      if (view) {
        urlok$view()
      }
      Sys.sleep(3)
      url_tweet <- "/html/body/div[1]/div/div/div[2]/main/div/div/div/div[1]/div/section/div/div/div/div/div/article/div/div/div[2]/div[2]/div[1]/div/div[1]/div/div/div[2]/div/div[3]/a"
      tweets_urls <- c()
      i <- 1
      repetitions <- 0
      max_repetitions <- 2
      cat("Inició la recolección de URLs.\n")
      while (TRUE) {
        urls_tweets <- rvest::html_attr(urlok$html_elements(xpath = url_tweet), "href")
        if (length(tweets_urls) > n_urls || repetitions >= max_repetitions) {
          cat("Finalizó la recolección de URLs.\n")
          break
        }
        urls_tweets <- urls_tweets[grep("/status/", urls_tweets)]
        new_tweets <- unique(urls_tweets[!urls_tweets %in% tweets_urls])
        tweets_urls <- unique(append(tweets_urls, new_tweets))
        Sys.sleep(2.5)
        urlok$scroll_by(top = 4000, left = 0)
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
      urlok$session$close()
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
      saveRDS(tweets_urls, paste0(dir, "/replies_", sub("https://x.com/(.*)/status/(.*)", "\\1_\\2", url), "_", gsub("-|:|\\.", "_", format(Sys.time(), "%Y_%m_%d_%X")), ".rds"))
      cat("URLs procesadas y guardadas.\n")
    } else {
      cat("URLs procesadas. No se han guardado en un archivo RDS.\n")
    }
  } else {
    warning("No se encontraron URLs de tweets.")
  }
  return(tweets_urls)
}
