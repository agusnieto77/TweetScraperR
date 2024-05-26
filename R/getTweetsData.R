#' Get Tweets Data
#'
#' @description
#' 
#' <a href="https://lifecycle.r-lib.org/articles/stages.html#experimental" target="_blank"><img src="https://lifecycle.r-lib.org/articles/figures/lifecycle-experimental.svg" alt="[Experimental]"></a>
#' 
#' Esta función recupera datos de tweets a partir de URLs de tweets proporcionadas.
#'
#' @param urls_tweets Vector de URLs de tweets de los cuales se desea obtener datos.
#' @param xuser Nombre de usuario de Twitter para autenticación. Por defecto es el valor de la variable de entorno del sistema USER.
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
  metrica_res <- '//*[contains(@aria-label, "Respuesta") or contains(@aria-label, "Respuestas")]'
  metrica_rep <- '//*[contains(@aria-label, "Repostear")]'
  metrica_meg <- '//*[contains(@aria-label, "Me gusta")]'
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
        urls_tw <- rvest::html_attr(tweets$html_elements(css = "article a"), "href")
        urls_tw <- urls_tw[grep("/status/", urls_tw)]
        tweets_db <- rbind(
          tweets_db,
          tibble::tibble(
            fecha = max(rvest::html_attr(rvest::html_elements(articulo, css = "time"), "datetime")),
            username = sub("^https://x.com/(.*?)/.*$|^https://twitter.com/(.*?)/.*$", "\\1", i),
            texto = rvest::html_text(rvest::html_elements(articulo, css = 'div[data-testid="tweetText"]')),
            emoticones = list(rvest::html_attr(rvest::html_elements(articulo, css = 'div[data-testid="tweetText"] img'), "alt")),
            links_img = list(gsub('src="([^"]+)"', '\\1', regmatches(as.character(articulo), gregexpr('src="(.*?\\.(?:png|jpg))"', as.character(articulo), perl=TRUE))[[1]])),
            respuestas = as.integer(gsub("^(\\d+).*", "\\1", rvest::html_attr(rvest::html_element(articulo, xpath = metrica_res), "aria-label"))),
            reposteos = as.integer(gsub("^(\\d+).*", "\\1", rvest::html_attr(rvest::html_element(articulo, xpath = metrica_rep), "aria-label"))),
            megustas = as.integer(gsub(".*?(\\d+) Me gusta.*", "\\1", rvest::html_attr(rvest::html_element(articulo, xpath = metrica_meg), "aria-label"))),
            metricas = rvest::html_attr(rvest::html_element(articulo, xpath = metrica_meg), "aria-label"),
            urls = list(urls_tw),
            hilo = length(urls_tw),
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
  tweets_db$fecha <- lubridate::as_datetime(tweets_db$fecha)
  tweets_db_c <- tweets_db[!is.na(tweets_db$fecha), ]
  urls_tweets_r <- setdiff(urls_tweets, borrados)
  urls_tweets_n <- setdiff(urls_tweets_r, tweets_db_c$url)
  saveRDS(list(tweets_recuperados = tweets_db_c, 
               tweets_borrados = borrados, 
               tweets_a_reprocesar = urls_tweets_n,
               errores = errores),
          paste0(dir, "/tweets_data_", gsub("-|:|\\.", "_", format(Sys.time(), "%Y_%m_%d_%X")), ".rds"))
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
