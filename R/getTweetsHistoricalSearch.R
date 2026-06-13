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
#' @param xuser Nombre de usuarix de Twitter para autenticación. Por defecto es el valor de la variable de entorno TWITTER_USER (o, en su defecto, USER).
#' @param xpass Contraseña de Twitter para autenticación. Por defecto es el valor de la variable de entorno TWITTER_PASS (o, en su defecto, PASS).
#' @param dir Directorio para guardar el archivo RDS con los tweets recolectados. Por defecto es el directorio de trabajo actual.
#' @param save Lógico. Indica si se debe guardar el resultado en un archivo RDS (por defecto TRUE).
#' @return Un tibble que contiene los datos de tweets recuperados, incluyendo la fecha, usuario, contenido del tweet, URL del tweet y fecha de captura.
#'
#' @examples
#' \dontrun{
#' getTweetsHistoricalSearch(
#'   search = "R Project", n_tweets = 50,
#'   since = "2018-10-26", until = "2023-10-30",
#'   live = TRUE
#' )
#'
#' # Sin guardar los resultados
#' getTweetsHistoricalSearch(
#'   search = "R Project", n_tweets = 50,
#'   since = "2018-10-26", until = "2023-10-30",
#'   live = TRUE, save = FALSE
#' )
#' }
#'
#' @references
#' Puedes encontrar más información sobre el paquete TweetScrapeR en:
#' <https://github.com/agusnieto77/TweetScraperR>
#'
#' @importFrom rvest read_html_live html_elements html_attr html_text html_element
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
    xuser = Sys.getenv("TWITTER_USER", Sys.getenv("USER")),
    xpass = Sys.getenv("TWITTER_PASS", Sys.getenv("PASS")),
    dir = getwd(),
    save = TRUE
) {
  search <- gsub("#", "%23", search)
  term_search <- if(live) {
    paste0("https://x.com/search?f=live&q=", search, "%20since%3A", since, "%20until%3A", until, "&src=typed_query")
  } else {
    paste0("https://x.com/search?f=top&q=", search, "%20since%3A", since, "%20until%3A", until, "&src=typed_query")
  }
  .get_historical(
    query_url = term_search,
    prefix = paste0("historical_search_", substr(gsub("\\s", "_", search), 1, 12)),
    n_tweets = n_tweets,
    dir = dir,
    save = save
  )
}

#' Motor interno compartido por la familia de recolectores historicos
#'
#' Pipeline comun de getTweetsHistoricalSearch, getTweetsHistoricalHashtag,
#' getTweetsHistoricalTimeline y getTweetsFullSearch sobre el motor Playwright:
#' recoleccion de articles con .pw_collect (reusa la sesion importada con
#' importSessionX, sin re-login), extraccion parse-once con .extract_tweet_data
#' y guardado RDS. Cada funcion exportada solo construye su URL de busqueda y su
#' prefijo de archivo. La unica divergencia legacy que se preserva es el mensaje
#' de vacio (empty_msg), distinto en getTweetsHistoricalHashtag.
#'
#' @param query_url URL de busqueda ya construida.
#' @param prefix Prefijo (ya sanitizado) del nombre del archivo RDS.
#' @param n_tweets Numero maximo de tweets a recolectar.
#' @param dir Directorio donde guardar el archivo RDS.
#' @param save Logico. Indica si se guarda el resultado en un archivo RDS.
#' @param max_attempts Numero maximo de intentos de recoleccion del motor.
#' @param empty_msg Mensaje cat() cuando no hay articulos para procesar.
#'
#' @return Tibble con los tweets recolectados, o NULL si no hubo articulos.
#' @noRd
.get_historical <- function(query_url, prefix, n_tweets, dir, save,
                            max_attempts = 3,
                            empty_msg = "No hay art\u00edculos para procesar.\n") {
  cat("Inici\u00f3 la recolecci\u00f3n de tweets.\n")
  res <- .pw_collect(query_url, mode = "articles", n_max = n_tweets, max_attempts = max_attempts)
  if (isTRUE(res$reason == "not_logged_in")) {
    stop("No hay una sesi\u00f3n activa de X. Import\u00e1 tu sesi\u00f3n con importSessionX(auth_token, ct0) antes de scrapear.")
  }
  if (!isTRUE(res$ok)) {
    stop("No se pudo completar la operaci\u00f3n: ", .pw_or(res$error, .pw_or(res$reason, "error desconocido")))
  }
  cat("Finaliz\u00f3 la recolecci\u00f3n de tweets.\n")
  cat("Procesando datos...\n")
  articles <- res$items
  if (length(articles) > 0) {
    tweets_recolectados <- .extract_tweet_data(articles)
    # Contrato legacy: art_html era columna lista (articles <- list() en los
    # clones originales). Se restaura el tipo antes de guardar y devolver.
    tweets_recolectados$art_html <- as.list(tweets_recolectados$art_html)
    .save_rds(tweets_recolectados, dir, prefix, save = save)
    cat("Tweets \u00fanicos recolectados:", length(tweets_recolectados$url), "\n")
    return(tweets_recolectados)
  } else {
    cat(empty_msg)
    return(NULL)
  }
}
