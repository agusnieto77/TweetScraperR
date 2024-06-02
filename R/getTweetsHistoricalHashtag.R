#' Get Historical Tweets with a Specific Hashtag
#' 
#' @description
#' 
#' <a href="https://lifecycle.r-lib.org/articles/stages.html#experimental" target="_blank"><img src="https://lifecycle.r-lib.org/articles/figures/lifecycle-experimental.svg" alt="[Experimental]"></a>
#' 
#'  Esta función recupera datos de los tweets que contienen un hashtag específico en Twitter, 
#'  basado en un rango de fechas especificado. Utiliza autenticación en Twitter mediante el 
#'  nombre de usuarix y la contraseña proporcionados, o los valores predeterminados de las 
#'  variables de entorno del sistema. Después de autenticar al usuario, la función realiza 
#'  una búsqueda de tweets que contienen el hashtag especificado dentro del rango de fechas 
#'  definido por los parámetros `since` y `until`. Las URLs de los tweets encontrados se recogen 
#'  hasta alcanzar el número máximo de URLs especificado por el parámetro `n_tweets` o hasta que no 
#'  se encuentren nuevas URLs en varios intentos consecutivos. Los resultados se guardan en un 
#'  archivo con formato `.rds` en el directorio especificado por el parámetro `dir`.
#' 
#' @param hashtag Hashtag de Twitter del cual se desean recuperar los tweets históricos. Por defecto es "#rstats".
#' @param timeout Tiempo de espera entre solicitudes en segundos. Por defecto es 10.
#' @param n_tweets El número máximo de URLs de tweets a recuperar. Por defecto es 100.
#' @param since Fecha de inicio para la búsqueda de tweets (en formato "YYYY-MM-DD"). Por defecto es "2018-10-26".
#' @param until Fecha de fin para la búsqueda de tweets (en formato "YYYY-MM-DD"). Por defecto es "2018-10-30".
#' @param xuser Nombre de usuarix de Twitter para autenticación. Por defecto es el valor de la variable de entorno del sistema USER.
#' @param xpass Contraseña de Twitter para autenticación. Por defecto es el valor de la variable de entorno del sistema PASS.
#' @param dir Directorio para guardar el archivo RDS con los datos de los tweets recolectados. Por defecto es el directorio de trabajo actual.
#' @return Un tibble que contiene las URLs de tweets recuperadas, junto con la fecha, usuario, contenido del tweet y URL del tweet.
#' @export
#'
#' @examples
#' \dontrun{
#' getTweetsHistoricalHashtag(hashtag = "#rstats", n_tweets = 150, since = "2018-10-26", until = "2018-10-30")
#' }
#'
#' @references
#' Puedes encontrar más información sobre el paquete TweetScrapeR en:
#' <https://github.com/agusnieto77/TweetScraperR>
#' 
#' @import rvest
#' @import tibble
#' @import lubridate

getTweetsHistoricalHashtag <- function(
    hashtag = "#rstats",
    timeout = 10,
    n_tweets = 100,
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
      message("La cuenta ya está autenticada o ha ocurrido un error.")
      message("Se inició la recolección de datos...")
    })
    url_tweet <- "div.css-175oi2r > div > div.css-175oi2r > a.css-146c3p1.r-bcqeeo.r-1ttztb7.r-qvutc0.r-37j5jr.r-a023e6"
    hashtagsearch <- paste0("https://x.com/search?q=(%23", gsub("#", "", hashtag), "%20until%3A", until, "%20since%3A", since, "&src=typed_query&f=live")
    success3 <- FALSE
    while (!success3) {
      tryCatch({
        historicalok <- rvest::read_html_live(hashtagsearch)
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
    articles <- list()
    attempts <- 0
    max_attempts <- 3
    success <- TRUE
    while (TRUE) {
      if (length(articles) >= n_tweets || attempts >= max_attempts) {
        cat("Finalizó la recolección de tweets.\n")
        cat("Procesando datos...\n")
        break
      }
      tryCatch({
        Sys.sleep(1.5)
        nuevos_articles <- as.character(historicalok$html_elements(css = "article"))
        urls_tweets <- nuevos_articles
        new_tweets <- length(unique(urls_tweets[!urls_tweets %in% articles]))
        articles <- unique(append(articles, nuevos_articles))
        articles <- articles[!is.na(articles)]
        historicalok$scroll_by(top = 4000, left = 0)
        message("Tweets recolectados: ", length(articles))
        Sys.sleep(timeout)
        if (new_tweets == 0) {
          attempts <- attempts + 1
        } else {
          attempts <- 0
        }
      }, error = function(e) {
        attempts <- attempts + 1
      })
    }
    if (length(articles) > 0) {
      tweets_recolectados <- tibble::tibble(
        art_html = articles,
        fecha =  lubridate::as_datetime("2008-11-09 09:12:30 UTC"),
        user = "",
        tweet = "",
        url = "",
        fecha_captura =  Sys.time()
      )
      for (i in 1:length(tweets_recolectados$art_html)) {
        fechas <- lubridate::as_datetime(rvest::html_attr(rvest::html_elements(rvest::read_html(articles[[i]]), css = "time"), "datetime"))
        fechas <- fechas[order(fechas, decreasing = TRUE)][1]
        if (lubridate::is.POSIXct(fechas)) {max_fecha <- fechas} else {max_fecha <- NA}
        tweets_recolectados$fecha[i] <- max_fecha
        tweets_recolectados$user[i] <- rvest::html_text(rvest::html_element(rvest::read_html(articles[[i]]), css = "div.css-175oi2r.r-18u37iz.r-1wbh5a2.r-1ez5h0i > div > div.css-175oi2r.r-1wbh5a2.r-dnmrzs > a > div > span"))
        tweets_recolectados$tweet[i] <- rvest::html_text(rvest::html_element(rvest::read_html(articles[[i]]), css = "div[data-testid='tweetText']"))
        tweets_recolectados$url[i] <- paste0("https://x.com", rvest::html_attr(rvest::html_element(rvest::read_html(articles[[i]]), css = url_tweet), "href"))
      }
      tweets_recolectados <- unique(tweets_recolectados)
      tweets_recolectados <- tweets_recolectados[!is.na(tweets_recolectados$fecha), ]
      saveRDS(tweets_recolectados, paste0(dir, "/historical_hashtag_", hashtag, "_", gsub("-|:|\\.", "_", format(Sys.time(), "%Y_%m_%d_%X")), ".rds"))
      cat("Datos procesados y guardados.\n")
      return(tweets_recolectados)
    } else {
      cat("No hay tweets para procesar.\n")
      return(NULL)
    }
    historicalok$session$close()
    twitter$session$close()
  }
}
