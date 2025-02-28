#' Get Historical Tweets from a Specific Search
#' 
#' @description
#' 
#' <a href="https://lifecycle.r-lib.org/articles/stages.html#experimental" target="_blank"><img src="https://lifecycle.r-lib.org/articles/figures/lifecycle-experimental.svg" alt="[Experimental]"></a>
#' 
#' Esta función permite recuperar tweets históricos de Twitter (ahora X) que coinciden con una búsqueda específica. 
#' Puedes especificar términos de búsqueda relevantes para tus necesidades de análisis, y la función recuperará 
#' tweets antiguos que coincidan con esos criterios. Esto es útil para investigaciones históricas, análisis de 
#' tendencias a lo largo del tiempo y cualquier otro análisis que requiera acceso a datos históricos de Twitter.
#' 
#' La función ahora incluye un proceso de autenticación automático y manejo de errores mejorado.
#' 
#' @param search Término de búsqueda para los tweets deseados. Por defecto es "R Project".
#' @param timeout Tiempo de espera entre solicitudes en segundos. Por defecto es 10.
#' @param n_tweets El número máximo de tweets a recuperar. Por defecto es 100.
#' @param since Fecha de inicio para la búsqueda de tweets (en formato "YYYY-MM-DD"). Por defecto es "2018-10-26".
#' @param until Fecha de fin para la búsqueda de tweets (en formato "YYYY-MM-DD"). Por defecto es "2023-10-30".
#' @param live Booleano que indica si se deben buscar tweets más recientes (TRUE) o destacados (FALSE). Por defecto es TRUE.
#' @param xuser Nombre de usuarix de Twitter para autenticación. Por defecto es el valor de la variable de entorno del sistema USER.
#' @param xpass Contraseña de Twitter para autenticación. Por defecto es el valor de la variable de entorno del sistema PASS.
#' @param dir Directorio para guardar el archivo RDS con los tweets recolectados. Por defecto es el directorio de trabajo actual.
#' @param save Lógico. Indica si se debe guardar el resultado en un archivo RDS (por defecto TRUE).
#' @return Un tibble que contiene los datos de tweets recuperados, incluyendo la fecha, usuario, contenido del tweet, URL del tweet y fecha de captura.
#'
#' @examples
#' \dontrun{
#' getTweetsHistoricalSearch(search = "R Project", n_tweets = 50, since = "2018-10-26", until = "2023-10-30", live = TRUE)
#' 
#' # Sin guardar los resultados
#' getTweetsHistoricalSearch(search = "R Project", n_tweets = 50, since = "2018-10-26", until = "2023-10-30", live = TRUE, save = FALSE)
#' }
#'
#' @references
#' Puedes encontrar más información sobre el paquete TweetScrapeR en:
#' <https://github.com/agusnieto77/TweetScraperR>
#'
#' @importFrom rvest read_html_live html_elements html_attr html_text html_element read_html
#' @importFrom lubridate as_datetime is.POSIXct
#' @importFrom tibble tibble
#' @importFrom dplyr distinct
#' 
#' @details
#' La función ahora incluye las siguientes mejoras y características:
#' 
#' 1. Autenticación automática: La función intenta autenticarse automáticamente en Twitter (X) usando las credenciales proporcionadas.
#' 2. Manejo de errores mejorado: Se han implementado múltiples bloques try-catch para manejar diferentes tipos de errores que pueden ocurrir durante la ejecución.
#' 3. Reintento automático: En caso de errores de tiempo de espera, la función reintentará automáticamente la operación.
#' 4. Opción de búsqueda en vivo: Se ha añadido un parámetro `live` para permitir la búsqueda de tweets más recientes (TRUE) o destacados (FALSE).
#' 5. Procesamiento de datos mejorado: Se ha mejorado el proceso de extracción y almacenamiento de datos de los tweets.
#' 6. Límite de intentos: Se ha implementado un límite de intentos para evitar bucles infinitos en caso de problemas persistentes.
#' 7. Feedback en tiempo real: La función ahora proporciona mensajes informativos sobre el progreso de la recolección de tweets.
#' 8. Control de guardado: Se ha añadido un parámetro `save` para controlar si los resultados se guardan en un archivo RDS.
#' 
#' Nota: Esta función depende de la estructura actual de la página web de Twitter (X). Cambios en la estructura del sitio pueden afectar su funcionamiento.
#' 
#' @export
#' 

getTweetsHistoricalSearch <- function(
    search = "R Project",
    timeout = 10,
    n_tweets = 100,
    since = "2018-10-26",
    until = "2023-10-30",
    live = TRUE,
    xuser = Sys.getenv("USER"),
    xpass = Sys.getenv("PASS"),
    dir = getwd(),
    save = TRUE
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
    term_search <- if(live) {
      paste0("https://x.com/search?f=live&q=", search, "%20since%3A", since, "%20until%3A", until, "&src=typed_query")
    } else {
      paste0("https://x.com/search?f=top&q=", search, "%20since%3A", since, "%20until%3A", until, "&src=typed_query")
    }
    success3 <- FALSE
    while (!success3) {
      tryCatch({
        historicalok <- rvest::read_html_live(term_search)
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
    cat("Inició la recolección de tweets.\n")
    success <- TRUE
    while (TRUE) {
      if (length(articles) >= n_tweets || attempts >= max_attempts) {
        cat("Finalizó la recolección de tweets.\n")
        cat("Procesando datos...\n")
        break
      }
      tryCatch({
        Sys.sleep(1.5)
        tryCatch({
          nuevos_articles <- as.character(historicalok$html_elements(css = "article"))
        }, error = function(e) {
          message("Error al procesar artículos: ", e$message)
          nuevos_articles <- character(0)
        })
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
        message("Error al recolectar tweet")
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
      tweets_recolectados <- dplyr::distinct(tweets_recolectados, url, .keep_all = TRUE)
      tweets_recolectados <- tweets_recolectados[!is.na(tweets_recolectados$fecha), ]
      if (save) {
        saveRDS(tweets_recolectados, paste0(dir, "/historical_search_", substr(gsub("\\s", "_", search), 1, 12), "_", gsub("-|:|\\.", "_", format(Sys.time(), "%Y_%m_%d_%X")), ".rds"))
        cat("Datos procesados y guardados.\n")
      } else {
        cat("Datos procesados. No se han guardado en un archivo RDS.\n")
      }
      cat("Tweets únicos recolectados:", length(tweets_recolectados$url), "\n")
      return(tweets_recolectados)
    } else {
      cat("No hay artículos para procesar.\n")
      return(NULL)
    }
    historicalok$session$close()
    twitter$session$close()
  }
}
