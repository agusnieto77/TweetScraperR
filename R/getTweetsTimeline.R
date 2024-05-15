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
  Sys.sleep(2)
  TweetScraperR::getAuthentication()
  Sys.sleep(2)
  fech <- "article time"
  user1 <- "article a.css-175oi2r.r-1wbh5a2.r-dnmrzs.r-1ny4l3l.r-1loqt21 .css-1rynq56.r-dnmrzs.r-1udh08x.r-3s2u2q.r-bcqeeo.r-qvutc0.r-37j5jr.r-a023e6.r-rjixqe.r-16dba41.r-18u37iz.r-1wvb978 .css-1qaijid.r-bcqeeo.r-qvutc0.r-poiln3"
  user2 <- "div.css-175oi2r.r-adacv.r-1udh08x.r-1ets6dv.r-1867qdf.r-rs99b7.r-o7ynqc.r-6416eg.r-1ny4l3l.r-1loqt21 > div > div.css-175oi2r.r-eqz5dr.r-1fz3rvf.r-1s2bzr4 > div > div > div > div.css-175oi2r.r-1wbh5a2.r-dnmrzs.r-1ny4l3l > div > div.css-175oi2r.r-18u37iz.r-1wbh5a2.r-13hce6t > div > div.css-175oi2r.r-1wbh5a2.r-dnmrzs > div > div > span"
  tweet <- "article .css-1rynq56.r-8akbws.r-krxsd3.r-dnmrzs.r-1udh08x.r-bcqeeo.r-qvutc0.r-37j5jr.r-a023e6.r-rjixqe.r-16dba41.r-bnwqim"
  url_tweet <- "div.css-175oi2r.r-18u37iz.r-1wbh5a2.r-13hce6t > div > div.css-175oi2r.r-18u37iz.r-1q142lx > a"
  timeline <- rvest::read_html_live(paste0("https://twitter.com/", username))
  Sys.sleep(3)
  tweets_udb <- tibble::tibble()
  i <- 1
  repetitions <- 0
  max_repetitions <- 2
  prev_count <- -1
  while (TRUE) {
    if (nrow(tweets_udb) > n_tweets || repetitions >= max_repetitions) {
      cat("Finalizó la recolección de tweets.")
      break
    }
    i_tweets <- tibble::tibble(
      fecha = lubridate::as_datetime(rvest::html_attr(timeline$html_elements(css = fech), "datetime")),
      usern = rvest::html_text(timeline$html_elements(css = paste(user1, user2, sep = ", "))),
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
