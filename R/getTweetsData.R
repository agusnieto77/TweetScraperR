#' Get Tweets Data
#'
#' @description
#' 
#' <a href="https://lifecycle.r-lib.org/articles/stages.html#experimental" target="_blank"><img src="https://lifecycle.r-lib.org/articles/figures/lifecycle-experimental.svg" alt="[Experimental]"></a>
#' 
#' Esta función permite recuperar y procesar datos de tweets a partir de un vector de URLs 
#' de tweets proporcionadas. Utilizando las credenciales de unx usuarix de Twitter, la función 
#' realiza la autenticación en Twitter y extrae información detallada de cada tweet. Los datos 
#' extraídos incluyen la fecha del tweet, el nombre de usuarix que lo publicó, el texto del tweet, 
#' las respuestas, reposts, me gusta, URLs asociadas, y otra información relevante.
#' La función también maneja tweets borrados y errores durante el proceso de recolección, y 
#' clasifica las URLs de los tweets en tres categorías: tweets recuperados, tweets borrados, y 
#' tweets que necesitan ser reprocesados. Finalmente, los datos recopilados se guardan en un 
#' archivo RDS en el directorio especificado por le usuarix.
#'
#' @param urls_tweets Vector de URLs de tweets de los cuales se desea obtener datos.
#' @param xuser Nombre de usuarix de Twitter para autenticación. Por defecto es el valor de la variable de entorno del sistema USER.
#' @param xpass Contraseña de Twitter para autenticación. Por defecto es el valor de la variable de entorno del sistema PASS.
#' @param dir directorio para guardar el RDS con las URLs recolectadas
#' @return Un tibble que contiene los datos de los tweets recuperados.
#' 
#' \itemize{
#'   \item \code{tweets_recuperados}: Un tibble con los datos de los tweets recuperados, incluyendo la fecha, nombre de usuario, texto, respuestas, reposts, me gusta, URLs asociadas y otras informaciones recopiladas.
#'   \item \code{tweets_borrados}: Un vector con las URLs de los tweets que fueron detectados como borrados.
#'   \item \code{tweets_a_reprocesar}: Un vector con las URLs de los tweets que no pudieron ser procesados exitosamente y necesitan ser reprocesados.
#'   \item \code{errores}: Un vector con los mensajes de error recopilados durante el proceso de recolección de datos.
#' }
#' 
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
#' @import stringr

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
            Sys.sleep(2)
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
    metrica_res <- '//*[contains(@aria-label, "Respuesta") or contains(@aria-label, "Respuestas")]'
    metrica_rep <- '//*[contains(@aria-label, "Repostear")]'
    metrica_meg <- '//*[contains(@aria-label, "Me gusta")]'
    pattern <- "https?://pbs\\.twimg\\.com/media/[^\\s\"']+(?:\\?[^\\s\"']+)?"
    Sys.sleep(1)
    tweets_db <- tibble::tibble()
    borrados <- c()
    errores <- c()
    contador <- 0
    cat("Inicio de la recolección de datos.\n\n")
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
              Sys.sleep(2)
            } else {
              stop(e)
            }
          })
        }
        Sys.sleep(5)
        raiz <- gsub("\\D", "", sub(".*status/", "", i))
        tuit_out   <- tweets$html_elements(xpath = paste0('//article[.//a[contains(@href, ', '"', raiz, '"', ')]]'))
        if (grepl("i/communities/", i) || length(tuit_out) == 0) {
          borrados <- append(borrados, i)
          cat("El tweet", gsub("https://twitter.com/.*/status/|https://x.com/.*/status/|https://x.com/i/communities/", "", i),"fue BORRADO o se encuentra momentáneamente INACCESIBLE.\n")
          tweets$session$close()
        } else {
          articulo <- tweets$html_elements(xpath = paste0('//article[.//a[contains(@href, ', '"', raiz, '"', ')]]'))
          articulo <- articulo[1]
          urls_tw <- rvest::html_attr(tweets$html_elements(css = "article a"), "href")
          urls_tw <- urls_tw[grep("/status/", urls_tw)]
          urls_tw <- urls_tw[!grepl("/status/.*/analytics|/status/.*/photo|/status/.*/hidden|/status/.*/quotes", urls_tw)]
          fechas <- lubridate::as_datetime(rvest::html_attr(rvest::html_elements(articulo, css = "time"), "datetime"))
          fechas <- fechas[order(fechas, decreasing = TRUE)][1]
          if (lubridate::is.POSIXct(fechas)) {max_fecha <- fechas} else {max_fecha <- NA}
          metr <- rvest::html_attr(rvest::html_element(articulo, xpath = metrica_meg), "aria-label")
          resp <- rvest::html_attr(rvest::html_element(articulo, xpath = metrica_res), "aria-label")
          if (grepl("[0-9]", resp)) {resp_ok <- as.integer(gsub("^(\\d+).*", "\\1", resp))} else {resp_ok <- as.integer(gsub("^(\\d+).*", "\\1", metr))}
          tweets_db <- rbind(
            tweets_db,
            tibble::tibble(
              fecha = max_fecha,
              username = sub("^https://x.com/(.*?)/.*$|^https://twitter.com/(.*?)/.*$", "\\1", i),
              texto = rvest::html_text(rvest::html_elements(articulo, css = 'div[data-testid="tweetText"]'))[1],
              tweet_citado = rvest::html_text(rvest::html_elements(articulo, css = 'div[data-testid="tweetText"]'))[2],
              user_citado = rvest::html_text(rvest::html_elements(articulo, css = 'div.css-175oi2r.r-1wbh5a2.r-dnmrzs > div > div > span'))[3],
              emoticones = list(rvest::html_attr(rvest::html_elements(articulo, css = 'div[data-testid="tweetText"] img'), "alt")),
              links_img_user = list(gsub('src="([^"]+)"', '\\1', regmatches(as.character(articulo), gregexpr('src="(.*?\\.(?:png|jpg))"', as.character(articulo), perl=TRUE))[[1]])),
              links_img_post = list(unique(gsub("&amp;", "&", stringr::str_extract_all(as.character(articulo), pattern)[[1]]))),
              respuestas = resp_ok,
              reposteos = as.integer(gsub("^(\\d+).*", "\\1", rvest::html_attr(rvest::html_element(articulo, xpath = metrica_rep), "aria-label"))),
              megustas = as.integer(gsub(".*?(\\d+) Me gusta.*", "\\1", rvest::html_attr(rvest::html_element(articulo, xpath = metrica_meg), "aria-label"))),
              metricas = metr,
              urls = list(urls_tw),
              hilo = length(urls_tw),
              url = i,
              fecha_captura = Sys.time()
            )
          )
          message("Datos recolectados del tweet: ", gsub("https://twitter.com/|https://x.com/", "", i), " ", contador, " de ", length(urls_tweets))
          tweets$session$close()
        }
      }, error = function(e) {
        errores <<- append(errores, conditionMessage(e))
        cat("Error al procesar el tweet:", gsub("https://twitter.com/.*/status/|https://x.com/.*/status/", "", i),"\n")
        tweets$session$close()
      })
    }
    twitter$session$close()
    if (nrow(tweets_db) > 0) {
      tweets_db$fecha <- lubridate::as_datetime(tweets_db$fecha)
      tweets_db_c <- tweets_db[!is.na(tweets_db$fecha), ]
      urls_tweets_r <- setdiff(urls_tweets, borrados)
      urls_tweets_n <- setdiff(urls_tweets_r, tweets_db_c$url)
      saveRDS(list(tweets_recuperados = tweets_db_c, 
                   tweets_borrados_o_inaccesibles = borrados, 
                   tweets_a_reprocesar = urls_tweets_n,
                   errores = errores),
              paste0(dir, "/tweets_data_", gsub("-|:|\\.", "_", format(Sys.time(), "%Y_%m_%d_%X")), ".rds"))
      cat("\nTerminando el proceso.
      \nTweets recuperados:",
          length(tweets_db_c$url),
          "\nTweets borrados o inaccesibles:",
          length(borrados),
          "\nTweets con errores:",
          length(errores),
          "\nTweets pendientes:",
          length(urls_tweets_n),
          "\n\n")
      return(tweets_db_c)
    } else {
      urls_tweets_n <- setdiff(urls_tweets, borrados)
      saveRDS(list(tweets_borrados = borrados, 
                   tweets_a_reprocesar = urls_tweets_n,
                   errores = errores),
              paste0(dir, "/tweets_data_", gsub("-|:|\\.", "_", format(Sys.time(), "%Y_%m_%d_%X")), ".rds"))
      cat("\nTerminando el proceso.
      \nTweets recuperados:",
          0,
          "\nTweets borrados o inaccesibles:",
          length(borrados),
          "\nTweets con errores:",
          length(errores),
          "\nTweets pendientes:",
          length(urls_tweets_n),
          "\n\n")
    }
  }
}
