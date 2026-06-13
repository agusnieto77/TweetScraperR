#' Get Historical Tweets with a Specific Hashtag
#'
#' @description
#'
#' <a href="https://lifecycle.r-lib.org/articles/stages.html#experimental" target="_blank"><img src="https://lifecycle.r-lib.org/articles/figures/lifecycle-experimental.svg" alt="[Experimental]"></a>
#'
#' @description
#' **Obsoleta**: preférí getTweetsSearchAPI(), basada en la API de X (datos del JSON, mas robusta).
#'
#'  Esta función recupera datos de los tweets que contienen un hashtag específico en Twitter,
#'  basado en un rango de fechas especificado. Utiliza autenticación en Twitter mediante el
#'  nombre de usuarix y la contraseña proporcionados, o los valores predeterminados de las
#'  variables de entorno del sistema. Después de autenticar al usuarix, la función realiza
#'  una búsqueda de tweets que contienen el hashtag especificado dentro del rango de fechas
#'  definido por los parámetros `since` y `until`. Las URLs de los tweets encontrados se recogen
#'  hasta alcanzar el número máximo de tweets especificado por el parámetro `n_tweets` o hasta que no
#'  se encuentren nuevos tweets en varios intentos consecutivos. Los resultados se guardan en un
#'  archivo con formato `.rds` en el directorio especificado por el parámetro `dir` si `save` es TRUE.
#'
#' @param hashtag Hashtag de Twitter del cual se desean recuperar los tweets históricos. Por defecto es "#rstats".
#' @param timeout Tiempo de espera entre solicitudes en segundos. Por defecto es 10.
#' @param n_tweets El número máximo de tweets a recuperar. Por defecto es 100.
#' @param since Fecha de inicio para la búsqueda de tweets (en formato "YYYY-MM-DD"). Por defecto es "2018-10-26".
#' @param until Fecha de fin para la búsqueda de tweets (en formato "YYYY-MM-DD"). Por defecto es "2018-10-30".
#' @param xuser Nombre de usuarix de Twitter para autenticación. Por defecto es el valor de la variable de entorno TWITTER_USER (o, en su defecto, USER).
#' @param xpass Contraseña de Twitter para autenticación. Por defecto es el valor de la variable de entorno TWITTER_PASS (o, en su defecto, PASS).
#' @param dir Directorio para guardar el archivo RDS con los datos de los tweets recolectados. Por defecto es el directorio de trabajo actual.
#' @param save Lógico. Indica si se debe guardar el resultado en un archivo RDS (por defecto TRUE).
#' @return Un tibble que contiene los datos de tweets recuperados, junto con la fecha, usuario, contenido del tweet y URL del tweet.
#' @export
#'
#' @examples
#' \dontrun{
#' getTweetsHistoricalHashtag(
#'   hashtag = "#rstats", n_tweets = 150,
#'   since = "2018-10-26", until = "2018-10-30"
#' )
#'
#' # Sin guardar los resultados
#' getTweetsHistoricalHashtag(
#'   hashtag = "#rstats", n_tweets = 150,
#'   since = "2018-10-26", until = "2018-10-30",
#'   save = FALSE
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

getTweetsHistoricalHashtag <- function(
    hashtag = "#rstats",
    timeout = 10,
    n_tweets = 100,
    since = "2018-10-26",
    until = "2018-10-30",
    xuser = Sys.getenv("TWITTER_USER", Sys.getenv("USER")),
    xpass = Sys.getenv("TWITTER_PASS", Sys.getenv("PASS")),
    dir = getwd(),
    save = TRUE
) {
  .Deprecated(msg = "getTweetsHistoricalHashtag() est\u00e1 obsoleta: us\u00e1 getTweetsSearchAPI() (basada en la API de X, datos estructurados del JSON, m\u00e1s robusta). Ver ?getTweetsSearchAPI.")
  hashtagsearch <- paste0("https://x.com/search?q=(%23", gsub("#", "", hashtag), ")%20until%3A", until, "%20since%3A", since, "&src=typed_query&f=live")
  .get_historical(
    query_url = hashtagsearch,
    prefix = paste0("historical_hashtag_", substr(gsub("#", "", hashtag), 1, 12)),
    n_tweets = n_tweets,
    dir = dir,
    save = save,
    empty_msg = "No hay tweets para procesar.\n"
  )
}
