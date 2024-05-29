#' Get Live Tweet URLs by Search
#' 
#' @description
#' 
#' <a href="https://lifecycle.r-lib.org/articles/stages.html#experimental" target="_blank"><img src="https://lifecycle.r-lib.org/articles/figures/lifecycle-experimental.svg" alt="[Experimental]"></a>
#' 
#' Esta función recupera URLs de tweets basados en una consulta de búsqueda en tiempo real en Twitter. 
#' Utiliza autenticación en Twitter mediante el nombre de usuario y la contraseña proporcionados, 
#' o los valores predeterminados de las variables de entorno del sistema. Después de autenticar al usuario, 
#' la función realiza la búsqueda especificada por el parámetro `search` y recoge las URLs de los tweets que 
#' coinciden con la consulta.
#' El proceso de recolección de URLs se ejecuta en un bucle que continúa hasta que se alcanza el número máximo 
#' de URLs especificado por el parámetro `n_tweets` o hasta que se realizan varios intentos consecutivos sin 
#' encontrar nuevas URLs, indicando que no hay más resultados disponibles en ese momento. La función incorpora 
#' mecanismos de manejo de errores y tiempos de espera para asegurar que las conexiones y búsquedas se realicen 
#' de manera robusta y continua.
#' Las URLs de los tweets recolectados se almacenan en un vector y se guardan en un archivo con formato `.rds` 
#' en el directorio especificado por el parámetro `dir`. Este archivo se nombra de manera única utilizando la 
#' consulta de búsqueda y la marca de tiempo del momento en que se realiza la recolección, asegurando que no 
#' se sobrescriban archivos anteriores.
#' 
#' @param search La consulta de búsqueda para recuperar tweets. Por defecto es "#RStats".
#' @param n_tweets El número máximo de tweets a recuperar. Por defecto es 100.
#' @param xuser Nombre de usuario de Twitter para autenticación. Por defecto es el valor de la variable de entorno del sistema USER.
#' @param xpass Contraseña de Twitter para autenticación. Por defecto es el valor de la variable de entorno del sistema PASS.
#' @param dir Directorio para guardar el archivo RDS con las URLs recolectadas.
#' @return Un vector que contiene las URLs de tweets recuperadas.
#' @export
#'
#' @examples
#' \dontrun{
#' getTweetsSearchStreaming(search = "#RStats", n_tweets = 200)
#' }
#'
#' @references
#' Puedes encontrar más información sobre el paquete TweetScrapeR en:
#' <https://github.com/agusnieto77/TweetScraperR>
#'
#' @import rvest

getTweetsSearchStreaming <- function(
    search = "#RStats",
    timeout = 10,
    n_tweets = 100,
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
    message("La cuenta ya está autenticada")
  })
  articles <- list()
  attempts <- 0
  max_attempts <- 3
  cat("Inició la recolección de tweets.\n")
  success <- TRUE
  while (TRUE) {
    if (length(articles) > n_tweets || attempts >= max_attempts) {
      cat("Finalizó la recolección de tweets.\n")
      break
    }
      success3 <- FALSE
      while (!success3) {
        tryCatch({
          historicalok <- rvest::read_html_live(paste0("https://x.com/search?q=", gsub("#", "%23", search), "&src=typed_query&f=live"))
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
      tryCatch({
        Sys.sleep(1.5)
        nuevos_articles <- as.character(historicalok$html_elements(css = "article"))
        urls_tweets <- nuevos_articles
        new_tweets <- length(unique(urls_tweets[!urls_tweets %in% articles]))
        articles <- unique(append(articles, nuevos_articles))
        articles <- articles[!is.na(articles)]
        message("Tweets recolectados: ", length(articles))
        historicalok$session$close()
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
  url_tweet <- "div.css-175oi2r > div > div.css-175oi2r > a.css-146c3p1.r-bcqeeo.r-1ttztb7.r-qvutc0.r-37j5jr.r-a023e6"
  if (length(articles) > 0) {
    tweets_recolectados <- tibble::tibble(
      art_html = articles,
      fecha =  lubridate::as_datetime("2008-11-09 09:12:30 UTC"),
      user = "",
      tweet = "",
      url = "",
      fecha_captura = Sys.time()
    )
    for (i in 1:length(tweets_recolectados$art_html)) {
      fechas <- lubridate::as_datetime(rvest::html_attr(rvest::html_elements(rvest::read_html(articles[[i]]), css = "time"), "datetime"))
      fechas <- fechas[order(fechas, decreasing = TRUE)][1]
      if (lubridate::is.POSIXct(fechas)) {max_fecha <- fechas} else {max_fecha <- NA}
      tweets_recolectados$fecha[i] <- max_fecha
      tweets_recolectados$user[i] <- rvest::html_text(rvest::html_element(rvest::read_html(articles[[i]]), css = "div.css-175oi2r.r-18u37iz.r-1wbh5a2.r-1ez5h0i > div > div.css-175oi2r.r-1wbh5a2.r-dnmrzs > a > div > span"))
      tweets_recolectados$tweet[i] <- rvest::html_text(rvest::html_element(rvest::read_html(articles[[i]]), css = "div[data-testid='tweetText']"))
      tweets_recolectados$url[i] <- paste0("https://x.com", rvest::html_attr(rvest::html_element(rvest::read_html(articles[[i]]), css = url_tweet), "href"))
      tweets_recolectados$fecha_captura[i] <- Sys.time()
    }
    tweets_recolectados <- unique(tweets_recolectados)
    tweets_recolectados <- tweets_recolectados[!is.na(tweets_recolectados$fecha), ]
    saveRDS(tweets_recolectados, paste0(dir, "/tweets_search_", gsub("\\s|#", "", search), "_", gsub("-|:|\\.", "_", format(Sys.time(), "%Y_%m_%d_%X")), ".rds"))
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
