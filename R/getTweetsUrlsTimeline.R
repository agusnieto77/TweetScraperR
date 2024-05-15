#' Get URLs of User Timeline Tweets
#'
#' Esta función recupera URLs de tweets del timeline de un usuario especificado en Twitter.
#'
#' @param username El nombre de usuario de Twitter del cual quieres obtener el timeline. Por defecto es "rstatstweet".
#' @param n_urls El número máximo de URLs de tweets a obtener. Por defecto es 100.
#' @param xuser Nombre de usuario de Twitter para autenticación. Por defecto es el valor de la variable de entorno del sistema USER.
#' @param xpass Contraseña de Twitter para autenticación. Por defecto es el valor de la variable de entorno del sistema PASS.
#' @return Un vector que contiene las URLs de tweets obtenidas.
#' @export
#'
#' @examples
#' \dontrun{
#' getTweetsUrlsTimeline(username = "rstatstweet", n_urls = 200)
#' }
#'
#' @import rvest

getTweetsUrlsTimeline <- function(
    username = "rstatstweet",
    n_urls = 100,
    xuser = Sys.getenv("USER"),
    xpass = Sys.getenv("PASS")
) {
  twitter <- rvest::read_html_live("https://twitter.com/i/flow/login")
  Sys.sleep(3)
  userx <- "input"
  nextx <- "#layers div > div > div > button:nth-child(6) > div"
  passx <- "#layers > div > div > div > div > div > div > div > div > div > div > div > div > div > div > div > div > div > label > div > div > div > input"
  login <- "#layers > div > div > div > div > div > div > div.css-175oi2r > div.css-175oi2r > div > div > div.css-175oi2r > div.css-175oi2r.r-16y2uox > div.css-175oi2r > div > div.css-175oi2r > div > div > button"
  twitter$type(css = userx, text = xuser)
  twitter$click(css = nextx, n_clicks = 1)
  Sys.sleep(2)
  twitter$type(css = passx, text = xpass)
  twitter$click(css = login, n_clicks = 1)
  Sys.sleep(2)
  usernameok <- rvest::read_html_live(paste0("https://twitter.com/", username))
  Sys.sleep(3)
  url_tweet <- "div.css-175oi2r.r-18u37iz.r-1wbh5a2.r-13hce6t > div > div.css-175oi2r.r-18u37iz.r-1q142lx > a"
  tweets_urls <- c()
  i <- 1
  repetitions <- 0
  max_repetitions <- 2
  while (TRUE) {
    urls_tweets <- rvest::html_attr(usernameok$html_elements(css = url_tweet), "href")
    if (length(tweets_urls) > n_urls || repetitions >= max_repetitions) {
      cat("Finalizó la recolección de URLs.")
      break
    }
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
    i <- i + 1
  }
  twitter$session$close()
  usernameok$session$close()
  saveRDS(paste0("https://twitter.com", tweets_urls), paste0("urls_", username, "_", gsub("-|:|\\.", "_", format(Sys.time(), "%Y_%m_%d_%X")), ".rds"))
}
