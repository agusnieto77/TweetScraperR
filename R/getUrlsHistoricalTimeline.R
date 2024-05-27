#' Get Historical Tweet URLs from a User Timeline
#' 
#' @description
#' 
#' <a href="https://lifecycle.r-lib.org/articles/stages.html#experimental" target="_blank"><img src="https://lifecycle.r-lib.org/articles/figures/lifecycle-experimental.svg" alt="[Experimental]"></a>
#' 
#' Esta función recupera URLs de tweets históricos de la línea de tiempo de un usuario específico en Twitter.
#' 
#' @param username Nombre de usuario de Twitter del que se desean recuperar los tweets. Por defecto es "rstatstweet".
#' @param timeout Tiempo de espera entre solicitudes en segundos. Por defecto es 10.
#' @param n_urls El número máximo de URLs de tweets a recuperar. Por defecto es 100.
#' @param since Fecha de inicio para la búsqueda de tweets (en formato "YYYY-MM-DD"). Por defecto es "2018-10-26".
#' @param until Fecha de fin para la búsqueda de tweets (en formato "YYYY-MM-DD"). Por defecto es "2018-10-30".
#' @param xuser Nombre de usuario de Twitter para autenticación. Por defecto es el valor de la variable de entorno del sistema USER.
#' @param xpass Contraseña de Twitter para autenticación. Por defecto es el valor de la variable de entorno del sistema PASS.
#' @param dir Directorio para guardar el archivo RDS con las URLs recolectadas. Por defecto es el directorio de trabajo actual.
#' @return Un vector que contiene las URLs de tweets recuperadas.
#' @export
#'
#' @examples
#' \dontrun{
#' getUrlsHistoricalTimeline(username = "rstatstweet", n_urls = 50, since = "2018-10-26", until = "2018-10-30")
#' }
#'
#' @references
#' Puedes encontrar más información sobre el paquete TweetScrapeR en:
#' <https://github.com/agusnieto77/TweetScraperR>
#'
#' @import rvest

getUrlsHistoricalTimeline <- function(
    username = "rstatstweet",
    timeout = 10,
    n_urls = 100,
    since = "2018-10-26",
    until = "2018-10-30",
    xuser = Sys.getenv("USER"),
    xpass = Sys.getenv("PASS"),
    dir = getwd()
) {
  success <- FALSE
  while (!success) {
    tryCatch({
      success2 <- FALSE
      while (!success2) {
        tryCatch({
          twitter <- rvest::read_html_live("https://x.com/i/flow/login")
          success2 <- TRUE
        }, error = function(e) {
          if (grepl("loadEventFired", e$message)) {
            message("Error de tiempo de espera, reintentando...")
            Sys.sleep(5)
          } else {
            stop(e)
          }
        })
      }
      Sys.sleep(5)
      userx <- "#layers > div > div > div > div > div > div > div.css-175oi2r > div.css-175oi2r > div > div > div.css-175oi2r > div.css-175oi2r > div > div > div > div.css-175oi2r > label > div > div.css-175oi2r > div > input"
      nextx <- "#layers div > div > div > button:nth-child(6) > div"
      passx <- "#layers > div > div > div > div > div > div > div > div > div > div > div > div > div > div > div > div > div > label > div > div > div > input"
      login <- "#layers > div > div > div > div > div > div > div.css-175oi2r > div.css-175oi2r > div > div > div.css-175oi2r > div.css-175oi2r.r-16y2uox > div.css-175oi2r > div > div.css-175oi2r > div > div > button"
      twitter$type(css = userx, text = xuser)
      twitter$click(css = nextx, n_clicks = 1)
      Sys.sleep(1)
      twitter$type(css = passx, text = xpass)
      twitter$click(css = login, n_clicks = 1)
      Sys.sleep(1)
    }, error = function(e) {
      message("La cuenta ya está autenticada o ha ocurrido un error: ", e$message)
    })
    url_tweet <- "div.css-175oi2r > div > div.css-175oi2r > a.css-146c3p1.r-bcqeeo.r-1ttztb7.r-qvutc0.r-37j5jr.r-a023e6"
    usersearh <- paste0("https://x.com/search?f=live&q=%28from%3A", username, "%29+until%3A", until, "+since%3A", since, "&src=typed_query")
    success3 <- FALSE
    while (!success3) {
      tryCatch({
        historicalok <- rvest::read_html_live(usersearh)
        success3 <- TRUE
      }, error = function(e) {
        if (grepl("loadEventFired", e$message)) {
          message("Error de tiempo de espera, reintentando...")
          Sys.sleep(5)
        } else {
          stop(e)
        }
      })
    }
    tweets_urls <- c()
    attempts <- 0
    max_attempts <- 3
    success <- TRUE
    while (TRUE) {
      if (length(tweets_urls) >= n_urls || attempts >= max_attempts) {
        cat("Finalizó la recolección de URLs.\n")
        break
      }
      tryCatch({
        Sys.sleep(1.5)
        urls_tweets <- rvest::html_attr(historicalok$html_elements(css = url_tweet), "href")
        urls_tweets <- urls_tweets[grep("/status/", urls_tweets)]
        new_tweets <- unique(urls_tweets[!urls_tweets %in% tweets_urls])
        tweets_urls <- unique(c(tweets_urls, new_tweets))
        tweets_urls <- tweets_urls[!is.na(tweets_urls)]
        historicalok$scroll_by(top = 4000, left = 0)
        message("URLs recolectadas: ", length(tweets_urls))
        Sys.sleep(timeout)
        if (length(new_tweets) == 0) {
          attempts <- attempts + 1
        } else {
          attempts <- 0
        }
      }, error = function(e) {
        message("Error al recolectar URLs: ", e$message)
        attempts <- attempts + 1
      })
    }
    historicalok$session$close()
    twitter$session$close()
    tweets_urls <- tweets_urls[1:min(length(tweets_urls), n_urls)]
    tweets_urls <- paste0("https://x.com", tweets_urls)
    saveRDS(tweets_urls, paste0(dir, "/urls_historical_timeline_", username, "_", gsub("-|:|\\.", "_", format(Sys.time(), "%Y_%m_%d_%X")), ".rds"))
    return(tweets_urls)
  }
}