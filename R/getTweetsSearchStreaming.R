#' Get Live Tweet by Search
#'
#' @description
#'
#' <a href="https://lifecycle.r-lib.org/articles/stages.html#experimental" target="_blank"><img src="https://lifecycle.r-lib.org/articles/figures/lifecycle-experimental.svg" alt="[Experimental]"></a>
#'
#' @description
#' **Obsoleta**: preférí getTweetsSearchAPI(), basada en la API de X (datos del JSON, mas robusta).
#'
#' Esta función recupera tweets basados en una consulta de búsqueda en tiempo real en Twitter.
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
#' en el directorio especificado por el parámetro `dir` si el parámetro `save` es TRUE. Este archivo se nombra
#' de manera única utilizando la consulta de búsqueda y la marca de tiempo del momento en que se realiza la
#' recolección, asegurando que no se sobrescriban archivos anteriores.
#'
#' @param search La consulta de búsqueda para recuperar tweets. Por defecto es "#RStats".
#' @param n_tweets El número máximo de tweets a recuperar. Por defecto es 100.
#' @param sleep Tiempo de espera para la carga de tweets. Por defecto este valor es de 3 segundos.
#' @param xuser Nombre de usuario de Twitter para autenticación. Por defecto es el valor de la variable de entorno TWITTER_USER (o USER si no está definida).
#' @param xpass Contraseña de Twitter para autenticación. Por defecto es el valor de la variable de entorno TWITTER_PASS (o PASS si no está definida).
#' @param dir Directorio para guardar el archivo RDS con las URLs recolectadas.
#' @param timeout Tiempo de espera.
#' @param save Lógico. Indica si se debe guardar el resultado en un archivo RDS (por defecto TRUE).
#'
#' @return Un vector que contiene las URLs de tweets recuperadas.
#' @export
#'
#' @examples
#' \dontrun{
#' getTweetsSearchStreaming(search = "#RStats", n_tweets = 200)
#'
#' # Sin guardar los resultados
#' getTweetsSearchStreaming(search = "#RStats", n_tweets = 200, save = FALSE)
#' }
#'
#' @references
#' Puedes encontrar más información sobre el paquete TweetScrapeR en:
#' <https://github.com/agusnieto77/TweetScraperR>
#'
#' @importFrom rvest read_html_live html_elements html_attr html_text html_element
#' @importFrom dplyr distinct
#' @importFrom tibble tibble
#' @importFrom lubridate as_datetime is.POSIXct
#'

getTweetsSearchStreaming <- function(
    search = "#RStats",
    timeout = 10,
    n_tweets = 100,
    sleep = 3,
    xuser = Sys.getenv("TWITTER_USER", Sys.getenv("USER")),
    xpass = Sys.getenv("TWITTER_PASS", Sys.getenv("PASS")),
    dir = getwd(),
    save = TRUE
) {
  .Deprecated(msg = "getTweetsSearchStreaming() est\u00e1 obsoleta: us\u00e1 getTweetsSearchAPI() (basada en la API de X, datos estructurados del JSON, m\u00e1s robusta). Ver ?getTweetsSearchAPI.")
  twitter <- NULL
  historicalok <- NULL
  on.exit(.close_sessions(historicalok, twitter), add = TRUE)
  twitter <- tryCatch({
    .x_login(xuser, xpass)
  }, error = function(e) {
    message("La cuenta ya est\u00e1 autenticada. ", conditionMessage(e))
    NULL
  })
  articles <- list()
  attempts <- 0
  max_attempts <- 3
  cat("Inici\u00f3 la recolecci\u00f3n de tweets.\n")
  historicalok <- .read_html_live_retry(paste0("https://x.com/search?q=", gsub("#", "%23", search), "&src=typed_query&f=live"))
  primera_pasada <- TRUE
  while (TRUE) {
    if (length(articles) > n_tweets || attempts >= max_attempts) {
      cat("Finaliz\u00f3 la recolecci\u00f3n de tweets.\n")
      break
    }
    ok <- tryCatch({
      if (primera_pasada) {
        primera_pasada <- FALSE
      } else {
        historicalok$session$Page$reload()
      }
      Sys.sleep(sleep)
      nuevos_articles <- as.character(historicalok$html_elements(css = .sel$article))
      urls_tweets <- nuevos_articles
      new_tweets <- length(unique(urls_tweets[!urls_tweets %in% articles]))
      articles <- unique(append(articles, nuevos_articles))
      articles <- articles[!is.na(articles)]
      message("Tweets recolectados: ", length(articles))
      Sys.sleep(timeout)
      if (new_tweets == 0) {
        attempts <- attempts + 1
      } else {
        attempts <- 0
      }
      TRUE
    }, error = function(e) {
      message("Error al recolectar tweet: ", conditionMessage(e))
      FALSE
    })
    if (!ok) {
      attempts <- attempts + 1
    }
  }
  if (length(articles) > 0) {
    tweets_recolectados <- .extract_tweet_data(articles)
    .save_rds(tweets_recolectados, dir, paste0("tweets_search_", substr(gsub("\\s|#", "", search), 1, 12)), save = save)
    cat("Tweets \u00fanicos recolectados:", length(tweets_recolectados$url), "\n")
    return(tweets_recolectados)
  } else {
    cat("No hay tweets para procesar.\n")
    return(NULL)
  }
}
