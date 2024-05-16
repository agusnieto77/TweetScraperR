#' Get Tweets from User Timeline
#'
#' Esta función recupera tweets del timeline de un usuario especificado en Twitter.
#'
#' @param username El nombre de usuario de Twitter del cual quieres obtener el timeline.
#' @param n_tweets El número máximo de tweets a obtener. Por defecto es 100.
#' @param xuser Nombre de usuario de Twitter para autenticación. Por defecto es el valor de la variable de entorno del sistema USER.
#' @param xpass Contraseña de Twitter para autenticación. Por defecto es el valor de la variable de entorno del sistema PASS.
#' @return Un vector que contiene los tweets obtenidos.
#' @export
#'
#' @examples
#' \dontrun{
#' getTweetsTimeline(username = "rstatstweet", n_tweets = 200)
#' }
#'
#' @references
#' Puedes encontrar más información sobre el paquete TweetScrapeR en:
#' \url{https://github.com/agusnieto77/TweetScraperR}
#'
#' @import rvest
#' @import tibble

getTweetsTimeline <- function(
    username = "rstatstweet",
    n_tweets = 100,
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
  fech <- "div > div > div > a > time"
  user1 <- "div.css-175oi2r.r-18u37iz.r-1wbh5a2.r-1ez5h0i > div > div.css-175oi2r.r-1wbh5a2.r-dnmrzs > a > div > span"
  tweet <- "#react-root > div > div > div.css-175oi2r.r-1f2l425.r-13qz1uu.r-417010.r-18u37iz > main > div > div > div > div > div > div:nth-child(3) > div > div > section > div > div > div > div > div > article > div > div > div.css-175oi2r.r-18u37iz > div.css-175oi2r.r-1iusvr4.r-16y2uox.r-1777fci.r-kzbkwu > div:nth-child(2)"
  url_tweet <- "div.css-175oi2r.r-18u37iz.r-1wbh5a2.r-1ez5h0i > div > div.css-175oi2r.r-18u37iz.r-1q142lx > a"
  user2 <-     "div.css-175oi2r.r-18u37iz.r-1wbh5a2.r-1ez5h0i > div > div.css-175oi2r.r-18u37iz.r-1q142lx > div > a"
  timeline <- rvest::read_html_live(paste0("https://twitter.com/", username))
  Sys.sleep(3)
  tweets_udb <- tibble::tibble()
  i <- 1
  repetitions <- 0
  max_repetitions <- 3
  prev_count <- -1
  while (TRUE) {
    if (nrow(tweets_udb) > n_tweets || repetitions >= max_repetitions) {
      cat("Finalizó la recolección de tweets.")
      break
    }
    i_tweets <- tibble::tibble(
      fecha = lubridate::as_datetime(rvest::html_attr(timeline$html_elements(css = fech), "datetime")),
      usern = rvest::html_text(timeline$html_elements(css = user1)),
      tweet = rvest::html_text(timeline$html_elements(css = tweet)),
      url = rvest::html_attr(timeline$html_elements(css = paste(url_tweet, user2, sep = ", ")), "href")
    )
    new_count <- nrow(i_tweets)
    if (new_count == prev_count) {
      repetitions <- repetitions + 1
    } else {
      repetitions <- 0
    }
    if (repetitions >= max_repetitions) {
      cat("Finalizó la recolección de tweets.")
      break
    }
    tweets_udb <- unique(rbind(tweets_udb, i_tweets))
    prev_count <- new_count
    timeline$scroll_by(top = 4000, left = 0)
    message("Tweets recolectados: ", nrow(tweets_udb))
    Sys.sleep(2.5)
  }
  twitter$session$close()
  timeline$session$close()
  tweets_udb$url <- paste0("https://twitter.com", tweets_udb$url)
  tweets_udb$is_original <- tweets_udb$usern == paste0("@", username)
  tweets_udb$is_retweet <- !is.na(tweets_udb$usern) & tweets_udb$usern != paste0("@", username)
  tweets_udb$is_cita <- is.na(tweets_udb$usern)
  saveRDS(tweets_udb, paste0("timeline_", username, "_", gsub("-|:|\\.", "_", format(Sys.time(), "%Y_%m_%d_%X")), ".rds"))
}
