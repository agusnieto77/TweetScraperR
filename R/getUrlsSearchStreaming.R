#' Get Live Tweet URLs by Search
#'
#' Esta función recupera URLs de tweets basados en una consulta de búsqueda en tiempo real en Twitter.
#'
#' @param search La consulta de búsqueda para recuperar tweets. Por defecto es "#RStats".
#' @param n_urls El número máximo de URLs de tweets a recuperar. Por defecto es 100.
#' @param xuser Nombre de usuario de Twitter para autenticación. Por defecto es el valor de la variable de entorno del sistema USER.
#' @param xpass Contraseña de Twitter para autenticación. Por defecto es el valor de la variable de entorno del sistema PASS.
#' @return Un vector que contiene las URLs de tweets recuperadas.
#' @export
#'
#' @examples
#' \dontrun{
#' getUrlsSearchStreaming(search = "#RStats", n_urls = 200)
#' }
#'
#' @references
#' Puedes encontrar más información sobre el paquete TweetScrapeR en:
#' \url{https://github.com/agusnieto77/TweetScraperR}
#'
#' @import rvest

getUrlsSearchStreaming <- function(
    search = "#RStats",
    timeout = 10,
    n_urls = 100,
    xuser = Sys.getenv("USER"),
    xpass = Sys.getenv("PASS")
) {
  twitter <- rvest::read_html_live("https://x.com/i/flow/login")
  Sys.sleep(2)
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
  
  tweets_urls <- c()
  attempts <- 0
  max_attempts <- 3
  
  while (length(tweets_urls) < n_urls && attempts < max_attempts) {
    url_tweet <- "div.css-175oi2r > div > div.css-175oi2r > a.css-146c3p1.r-bcqeeo.r-1ttztb7.r-qvutc0.r-37j5jr.r-a023e6"
    try({
      searchok <- rvest::read_html_live(paste0("https://x.com/search?q=", gsub("#", "%23", search), "&src=typed_query&f=live"))
      Sys.sleep(1.5)
      urls_tweets <- rvest::html_attr(searchok$html_elements(css = url_tweet), "href")
      urls_tweets <- urls_tweets[grep("/status/", urls_tweets)]
      new_tweets <- unique(urls_tweets[!urls_tweets %in% tweets_urls])
      tweets_urls <- unique(append(tweets_urls, new_tweets))
      tweets_urls <- tweets_urls[!is.na(tweets_urls)]
      message("URLs recolectadas: ", length(tweets_urls))
      Sys.sleep(timeout)
      
      if (length(new_tweets) == 0) {
        attempts <- attempts + 1
      } else {
        attempts <- 0
      }
    }, silent = TRUE)
  }
  
  twitter$session$close()
  searchok$session$close()
  
  tweets_urls <- tweets_urls[1:min(length(tweets_urls), n_urls)]
  saveRDS(paste0("https://x.com", tweets_urls), paste0("search_live_", gsub("#", "hashtag_", search), "_", gsub("-|:|\\.", "_", format(Sys.time(), "%Y_%m_%d_%X")), ".rds"))
}