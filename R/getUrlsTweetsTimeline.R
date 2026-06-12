#' Get URLs of User Timeline Tweets
#'
#' @description
#'
#' <a href="https://lifecycle.r-lib.org/articles/stages.html#experimental" target="_blank"><img src="https://lifecycle.r-lib.org/articles/figures/lifecycle-experimental.svg" alt="[Experimental]"></a>
#'
#' Esta funci\u00f3n recupera URLs de tweets del timeline de unx usuarix especificadx en Twitter.
#' Opcionalmente puede iniciar sesi\u00f3n en Twitter utilizando las credenciales proporcionadas si open=TRUE,
#' navega al perfil del usuarix especificadx, y recopila hasta `n_urls` URLs de tweets.
#' El proceso de recolecci\u00f3n se detiene si se alcanza el n\u00famero m\u00e1ximo de URLs especificado o
#' despu\u00e9s de realizar 600 capturas y se detiene el desplazamiento (scroll).
#'
#' @param username El nombre de usuarix de Twitter del cual quieres obtener el timeline. Por defecto es "rstatstweet".
#' @param n_urls El n\u00famero m\u00e1ximo de URLs de tweets a obtener. Por defecto es 100.
#' @param open Indica si se debe realizar el proceso de autenticaci\u00f3n (por defecto FALSE).
#' @param xuser Nombre de usuarix de Twitter para autenticaci\u00f3n. Por defecto es el valor de la variable de entorno del sistema USER.
#' @param xpass Contrase\u00f1a de Twitter para autenticaci\u00f3n. Por defecto es el valor de la variable de entorno del sistema PASS.
#' @param max_retries n\u00famero m\u00e1ximo de intentos de conexi\u00f3n. Por defecto es 3.
#' @param dir Directorio donde se guardar\u00e1 el archivo de salida. Por defecto es el directorio de trabajo actual.
#' @param save L\u00f3gico. Indica si se debe guardar el resultado en un archivo RDS (por defecto TRUE).
#' @return Un vector que contiene las URLs de tweets obtenidas.
#' @export
#'
#' @examples
#' \dontrun{
#' # Sin autenticaci\u00f3n
#' getUrlsTweetsTimeline(username = "rstatstweet", n_urls = 200)
#'
#' # Con autenticaci\u00f3n
#' getUrlsTweetsTimeline(username = "rstatstweet", n_urls = 200, open = TRUE)
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
  usernameok <- NULL
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

      usernameok <- rvest::read_html_live(paste0("https://x.com/", username))
      Sys.sleep(3)
      url_tweet <- "div.css-175oi2r > div > div.css-175oi2r > a.css-146c3p1.r-bcqeeo.r-1ttztb7.r-qvutc0.r-37j5jr.r-a023e6"
      tweets_urls <- c()
      repetitions <- 0
      max_repetitions <- 3  # Incrementado a 3 para consistencia
      cat("Inici\u00f3 la recolecci\u00f3n de URLs.\n")

      while (TRUE) {
        if (length(tweets_urls) >= n_urls || repetitions >= max_repetitions) {
          cat("Finaliz\u00f3 la recolecci\u00f3n de URLs.\n")
          break
        }

        urls_tweets <- rvest::html_attr(usernameok$html_elements(css = url_tweet), "href")
        urls_tweets <- urls_tweets[grep("/status/", urls_tweets)]
        new_tweets <- unique(urls_tweets[!urls_tweets %in% tweets_urls])
        tweets_urls <- unique(c(tweets_urls, new_tweets))

        usernameok$scroll_by(top = 4000, left = 0)
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
  if (!is.null(usernameok)) {
    usernameok$session$close()
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
      saveRDS(tweets_urls, file.path(dir, paste0("urls_", username, "_", gsub("-|:|\\.", "_", format(Sys.time(), "%Y_%m_%d_%X")), ".rds")))
      cat("URLs procesadas y guardadas.\n")
    } else {
      cat("URLs procesadas. No se han guardado en un archivo RDS.\n")
    }
  } else {
    warning("No se encontraron URLs de tweets.")
  }

  return(tweets_urls)
}
