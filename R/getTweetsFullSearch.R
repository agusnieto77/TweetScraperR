#' Get Tweets from a Full Search
#' 
#' @description
#' 
#' <a href="https://lifecycle.r-lib.org/articles/stages.html#experimental" target="_blank"><img src="https://lifecycle.r-lib.org/articles/figures/lifecycle-experimental.svg" alt="[Experimental]"></a>
#' 
#' Esta función realiza una búsqueda avanzada de tweets en Twitter (X) utilizando
#' varios criterios de búsqueda y recolecta los tweets que coinciden con estos criterios.
#'
#' @param search_all Cadena de texto. Busca tweets que contengan todas estas palabras (por defecto "R Project").
#' @param search_exact Cadena de texto. Busca tweets que contengan esta frase exacta (por defecto NULL).
#' @param search_any Cadena de texto. Busca tweets que contengan cualquiera de estas palabras (por defecto NULL).
#' @param no_search Cadena de texto. Excluye tweets que contengan estas palabras (por defecto NULL).
#' @param hashtag Cadena de texto. Busca tweets con estos hashtags (por defecto NULL).
#' @param lan Cadena de texto. Filtra tweets por idioma (por defecto NULL).
#' @param from Cadena de texto. Busca tweets de estos usuarios (por defecto NULL).
#' @param to Cadena de texto. Busca tweets dirigidos a estos usuarios (por defecto NULL).
#' @param men Cadena de texto. Busca tweets que mencionan a estos usuarios (por defecto NULL).
#' @param rep Número entero. Número mínimo de respuestas que debe tener un tweet (por defecto 0).
#' @param fav Número entero. Número mínimo de favoritos que debe tener un tweet (por defecto 0).
#' @param rt Número entero. Número mínimo de retweets que debe tener un tweet (por defecto 0).
#' @param timeout Número entero. Tiempo de espera en segundos entre solicitudes (por defecto 10).
#' @param n_tweets Número entero. Número máximo de tweets a recolectar (por defecto 100).
#' @param since Fecha. Fecha de inicio para la búsqueda (por defecto 7 días antes de la fecha actual).
#' @param until Fecha. Fecha de fin para la búsqueda (por defecto la fecha actual).
#' @param xuser Cadena de texto. Nombre de usuario para la autenticación en Twitter (por defecto se toma de la variable de entorno USER).
#' @param xpass Cadena de texto. Contraseña para la autenticación en Twitter (por defecto se toma de la variable de entorno PASS).
#' @param dir Cadena de texto. Directorio donde se guardarán los resultados (por defecto el directorio de trabajo actual).
#'
#' @return Un tibble con los tweets recolectados, incluyendo las columnas:
#'   \item{art_html}{HTML del artículo del tweet}
#'   \item{fecha}{Fecha y hora del tweet}
#'   \item{user}{Nombre de usuario del autor del tweet}
#'   \item{tweet}{Texto del tweet}
#'   \item{url}{URL del tweet}
#'   \item{fecha_captura}{Fecha y hora de la captura del tweet}
#'
#' @details
#' La función primero intenta autenticarse en Twitter utilizando las credenciales proporcionadas.
#' Luego, construye una URL de búsqueda basada en los parámetros proporcionados y realiza la búsqueda.
#' Los tweets se recolectan iterativamente, scrolleando la página hasta que se alcance el número
#' deseado de tweets o se agoten los intentos.
#' Los tweets recolectados se procesan para extraer la información relevante y se guardan en un archivo RDS.
#'
#' @note
#' Esta función requiere una conexión a Internet y credenciales válidas de Twitter.
#'
#' @export
#'
#' @examples
#' \dontrun{
#' tweets <- getTweetsFullSearch(
#'   search_all = "clima cambio",
#'   hashtag = "#medioambiente",
#'   lan = "es",
#'   n_tweets = 100,
#'   since = Sys.Date() - 30
#' )
#' }
#'
#' @import rvest
#' @import lubridate
#' @import tibble
#' @import dplyr

getTweetsFullSearch <- function(
    search_all = "R Project",
    search_exact = NULL,
    search_any = NULL,
    no_search = NULL,
    hashtag = NULL,
    lan = NULL,
    from = NULL,
    to = NULL,
    men = NULL,
    rep = 0,
    fav = 0,
    rt = 0,
    timeout = 10,
    n_tweets = 100,
    since = Sys.Date()-7,
    until = Sys.Date(),
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
    search_all <- ifelse(nchar(search_all)<1, "", paste0(gsub(" ", "%20", search_all), "%20")) 
    search_exact <- ifelse(is.null(search_exact), "", paste0("%22", gsub(" ", "%20", search_exact), "%22", "%20")) 
    search_any <- ifelse(is.null(search_any), "", paste0("(", gsub(" ", "%20OR%20", search_any), ")", "%20"))  
    no_search <- ifelse(is.null(no_search), "", paste0(gsub(" ", "%20", gsub("(\\w+)", "-\\1", no_search)), "%20")) 
    hashtag <- ifelse(is.null(hashtag), "", paste0("(", gsub(" ", "%20OR%20", gsub("(\\w+)", "%23\\1", gsub("#", "", hashtag))), ")", "%20")) 
    lan <- ifelse(is.null(lan), "", paste0("%20lang%3A", lan))
    from <- ifelse(is.null(from), "", paste0("(", gsub(" ", "%20OR%20", gsub("(\\w+)", "from%3A\\1", gsub("@", "", from))), ")", "%20"))
    to <- ifelse(is.null(to), "", paste0("(", gsub(" ", "%20OR%20", gsub("(\\w+)", "to%3A\\1", gsub("@", "", to))), ")", "%20"))
    men <- ifelse(is.null(men), "", paste0("(", gsub(" ", "%20OR%20", gsub("@", "%40", gsub("@@", "@", paste0("@", men)))), ")", "%20"))
    term_search <- paste0("https://x.com/search?f=live&q=", search_all, search_exact, search_any, no_search, hashtag, from, to, men, "min_replies%3A", rep, "%20min_faves%3A", fav, "%20min_retweets%3A", rt, lan, "%20since%3A", since, "%20until%3A", until, "&src=typed_query")
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
      saveRDS(tweets_recolectados, paste0(dir, "/full_search_", "_", gsub("-|:|\\.", "_", format(Sys.time(), "%Y_%m_%d_%X")), ".rds"))
      cat("Datos procesados y guardados.\n")
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
