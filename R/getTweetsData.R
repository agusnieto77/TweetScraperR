#' Get Tweets Data
#'
#' Esta función recupera datos de tweets a partir de URLs de tweets proporcionadas.
#'
#' @param urls_tweets Vector de URLs de tweets de los cuales se desea obtener datos.
#' @param xuser Nombre de usuario de Twitter para autenticación. Por defecto es el valor de la variable de entorno del sistema USER.
#' @param xpass Contraseña de Twitter para autenticación. Por defecto es el valor de la variable de entorno del sistema PASS.
#' @return Un tibble que contiene los datos de los tweets recuperados.
#' @export
#'
#' @examples
#' \dontrun{
#' getTweetsData(urls_tweets = "https://twitter.com/estacion_erre/status/1788929978811232537")
#' }
#'
#' @import rvest
#' @import lubridate
#' @import tibble

getTweetsData <- function(
    urls_tweets,
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
  tweet_original <- "/html/body/div/div/div/div/main/div/div/div/div/div/section/div/div/div/div/div/article/div/div/div/div[1]/div/div/span"
  fech <- ".css-175oi2r.r-1r5su4o time"
  username <- "/html/body/div/div/div/div/main/div/div/div/div/div/section/div/div/div[1]/div/div/article/div/div/div/div/div/div/div/div/div/div/div/div/a/div/span"
  name <- "/html/body/div[1]/div/div/div/main/div/div/div/div/div/section/div/div/div[1]/div/div/article/div/div/div/div/div/div/div/div/div/div/div/a/div/div/span/span"
  metrica_res <- "/html/body/div/div/div/div/main/div/div/div/div/div/section/div/div/div/div/div/article/div/div/div/div/div/div/div[1]/div/div/div/span/span/span"
  metrica_rep <- "/html/body/div/div/div/div/main/div/div/div/div/div/section/div/div/div/div/div/article/div/div/div/div/div/div/div[2]/div/div/div/span/span/span"
  metrica_meg <- "/html/body/div/div/div/div/main/div/div/div/div/div/section/div/div/div/div/div/article/div/div/div/div/div/div/div[3]/div/div/div/span/span/span"
  Sys.sleep(3)
  tweets_db <- tibble::tibble()
  for (i in urls_tweets) {
    tweets <- rvest::read_html_live(i)
    Sys.sleep(4)
    tweets_db <- rbind(
      tweets_db,
      tibble::tibble(
        fecha = lubridate::as_datetime(rvest::html_attr(tweets$html_elements(css = fech), "datetime")),
        username = sub("^https://twitter.com/(.*?)/.*$", "\\1", i),
        texto = paste(rvest::html_text(tweets$html_elements(xpath = tweet_original)), collapse = " "),
        respuestas = rvest::html_text(tweets$html_elements(xpath = metrica_res))[1],
        reposteos = rvest::html_text(tweets$html_elements(xpath = metrica_rep))[1],
        megustas = rvest::html_text(tweets$html_elements(xpath = metrica_meg))[1],
        post_completo = list(tweets$html_elements(css = "article")),
        url = i
      )
    )
    message("Datos recolectados del tweet: ", i)
  }
  twitter$session$close()
  tweets$session$close()
  saveRDS(tweets_db, paste0("db_tweets_", gsub("-|:|\\.", "_", format(Sys.time(), "%Y_%m_%d_%X")), ".rds"))
}
