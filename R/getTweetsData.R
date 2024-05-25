#' Get Tweets Data
#'
#' Esta función recupera datos de tweets a partir de URLs de tweets proporcionadas.
#'
#' @param urls_tweets Vector de URLs de tweets de los cuales se desea obtener datos.
#' @param xuser Nombre de usuario de Twitter para autenticación. Por defecto es el valor de la variable de entorno del sistema USER.
#' @param xpass Contraseña de Twitter para autenticación. Por defecto es el valor de la variable de entorno del sistema PASS.
#' @param dir directorio para guardar el RDS con las URLs recolectadas
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
    success <- TRUE
  }, error = function(e) {
    message("La cuenta ya está autenticada")
  })
  tweet_original <- "/html/body/div/div/div/div/main/div/div/div/div/div/section/div/div/div/div/div/article/div/div/div/div[1]/div/div/span"
  fech <- "time"
  username <- "/html/body/div/div/div/div/main/div/div/div/div/div/section/div/div/div[1]/div/div/article/div/div/div/div/div/div/div/div/div/div/div/div/a/div/span"
  name <- "/html/body/div[1]/div/div/div/main/div/div/div/div/div/section/div/div/div[1]/div/div/article/div/div/div/div/div/div/div/div/div/div/div/a/div/div/span/span"
  metrica_res <- "div:nth-child(1) > button > div > div.css-175oi2r.r-xoduu5.r-1udh08x > span > span > span"
  metrica_rep <- "div:nth-child(2) > button > div > div.css-175oi2r.r-xoduu5.r-1udh08x > span > span > span"
  metrica_meg <- "div:nth-child(3) > button > div > div.css-175oi2r.r-xoduu5.r-1udh08x > span > span > span"
  Sys.sleep(1)
  tweets_db <- tibble::tibble()
  borrados <- c()
  errores <- c()
  contador <- 0
  for (i in urls_tweets) {
    contador <- contador + 1
    tryCatch({
      success3 <- FALSE
      while (!success3) {
        tryCatch({
          tweets <- rvest::read_html_live(i)
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
      Sys.sleep(2.5)
      if (!grepl("error-detail", paste(na.omit(rvest::html_attr(tweets$html_elements(css = "div.css-175oi2r div.css-175oi2r div.css-175oi2r"), "data-testid")), collapse = " "))) {
        articulo <- tweets$html_elements(xpath = paste0('//article[.//a[@href="/', gsub("https://twitter.com/|https://x.com/", "", i), '"]]'))
        ymdhms <- tweets$html_elements(xpath = paste0('//a[@href="/', gsub("https://twitter.com/|https://x.com/", "", i), '"]'))
        tweets_db <- rbind(
          tweets_db,
          tibble::tibble(
            fecha = max(lubridate::as_datetime(rvest::html_attr(rvest::html_elements(articulo, css = fech), "datetime"))),
            username = sub("^https://x.com/(.*?)/.*$|^https://twitter.com/(.*?)/.*$", "\\1", i),
            texto = rvest::html_text(html_elements(articulo, css = "span"))[7],
            respuestas = as.numeric(gsub("^(\\d+).*", "\\1", rvest::html_attr(html_element(articulo, xpath = '//*[contains(@aria-label, "Respuestas")]'), "aria-label"))),
            reposteos = as.numeric(gsub("^(\\d+).*", "\\1", rvest::html_attr(html_element(articulo, xpath = '//*[contains(@aria-label, "Repostear")]'), "aria-label"))),
            megustas = as.numeric(gsub("^(\\d+).*", "\\1", rvest::html_attr(html_element(articulo, xpath = '//*[contains(@aria-label, "Me gusta")]'), "aria-label"))),
            url = i
          )
        )
        message("Datos recolectados del tweet: ", gsub("https://twitter.com/|https://x.com/", "", i), " ", contador, " de ", length(urls_tweets))
        tweets$session$close()
      } else {
        borrados <- append(borrados, i)
        cat("El tweet", gsub("https://twitter.com/.*/status/|https://x.com/.*/status/", "", i),"fue BORRADO.\n")
        tweets$session$close()
      }
    }, error = function(e) {
      errores <<- append(errores, conditionMessage(e))
      cat("Error al procesar el tweet:", gsub("https://twitter.com/.*/status/|https://x.com/.*/status/", "", i), "\n", e$message, "\n")
      tweets$session$close()
    })
  }
  twitter$session$close()
  convertir_mil <- function(x) {
    ifelse(grepl("mil|K", x), as.numeric(gsub("[^0-9.]", "", x)) * 1000, as.numeric(x))
  }
  tweets_db$respuestas <- ifelse(is.na(tweets_db$respuestas) | tweets_db$respuestas == "", "0", tweets_db$respuestas)
  tweets_db$reposteos <- ifelse(is.na(tweets_db$reposteos) | tweets_db$reposteos == "", "0", tweets_db$reposteos)
  tweets_db$megustas <- ifelse(is.na(tweets_db$megustas) | tweets_db$megustas == "", "0", tweets_db$megustas)
  tweets_db$respuestas <- sapply(gsub(",", ".", gsub("\\.", "", tweets_db$respuestas)), convertir_mil)
  tweets_db$reposteos <- sapply(gsub(",", ".", gsub("\\.", "", tweets_db$reposteos)), convertir_mil)
  tweets_db$megustas <- sapply(gsub(",", ".", gsub("\\.", "", tweets_db$megustas)), convertir_mil)
  tweets_db_c <- tweets_db[!is.na(tweets_db$fecha), ]
  saveRDS(tweets_db_c, paste0("db_tweets_", gsub("-|:|\\.", "_", format(Sys.time(), "%Y_%m_%d_%X")), ".rds"))
  saveRDS(borrados, paste0("url_tweets_del_", gsub("-|:|\\.", "_", format(Sys.time(), "%Y_%m_%d_%X")), ".rds"))
  urls_tweets_r <- setdiff(urls_tweets, borrados)
  urls_tweets_n <- setdiff(urls_tweets_r, tweets_db_c$url)
  saveRDS(urls_tweets_n, paste0("url_tweets_na_", gsub("-|:|\\.", "_", format(Sys.time(), "%Y_%m_%d_%X")), ".rds"))
  saveRDS(errores, paste0("error_", gsub("-|:|\\.", "_", format(Sys.time(), "%Y_%m_%d_%X")), ".rds"))
  cat("\nTerminando el proceso.
      \nTweets recuperados:",
      length(tweets_db_c$url),
      "\nTweets borrados:",
      length(borrados),
      "\nTweets con errores:",
      length(errores),
      "\nTweets pendientes:",
      length(urls_tweets_n),
      "\n\n")
  return(tweets_db_c)
  }
}
