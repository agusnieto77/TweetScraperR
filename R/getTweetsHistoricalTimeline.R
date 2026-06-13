#' Get Historical Tweets from a User Timeline
#'
#' @description
#'
#' <a href="https://lifecycle.r-lib.org/articles/stages.html#experimental" target="_blank"><img src="https://lifecycle.r-lib.org/articles/figures/lifecycle-experimental.svg" alt="[Experimental]"></a>
#'
#' Esta función permite recuperar tweets históricos de Twitter que coinciden con una búsqueda específica en el timeline de unx usuarix en particular.
#' Puedes especificar el nombre de usuarix de Twitter del que deseas obtener los tweets históricos. La función recupera los tweets antiguos publicados
#' por ese usuarix dentro del período de tiempo especificado. Es útil para investigaciones históricas, análisis de tendencias a lo largo del tiempo
#' y cualquier otro análisis que requiera acceso a los datos históricos de unx usuarix en particular en Twitter. Cabe destacar que esta función no
#' captura tweets de otras cuentas que han sido retuiteados por le usuarix especificadx.
#'
#' @param username Nombre de usuario de Twitter del que se desean recuperar los tweets. Por defecto es "rstatstweet".
#' @param timeout Tiempo de espera entre solicitudes en segundos. Por defecto es 10.
#' @param n_tweets El número máximo de tweets a recuperar. Por defecto es 100.
#' @param since Fecha de inicio para la búsqueda de tweets (en formato "YYYY-MM-DD"). Por defecto es "2018-10-26".
#' @param until Fecha de fin para la búsqueda de tweets (en formato "YYYY-MM-DD"). Por defecto es "2023-10-30".
#' @param xuser Nombre de usuarix de Twitter para autenticación. Por defecto es el valor de la variable de entorno TWITTER_USER (o, en su defecto, USER).
#' @param xpass Contraseña de Twitter para autenticación. Por defecto es el valor de la variable de entorno TWITTER_PASS (o, en su defecto, PASS).
#' @param dir Directorio para guardar el archivo RDS con las tweets recolectados. Por defecto es el directorio de trabajo actual.
#' @param save Lógico. Indica si se debe guardar el resultado en un archivo RDS (por defecto TRUE).
#' @return Un tibble que contiene los datos de tweets recuperados, junto con la fecha, usuario, contenido del tweet y URL del tweet.
#' @export
#'
#' @examples
#' \dontrun{
#' getTweetsHistoricalTimeline(
#'   username = "rstatstweet", n_tweets = 50,
#'   since = "2018-10-26", until = "2023-10-30"
#' )
#'
#' # Sin guardar los resultados
#' getTweetsHistoricalTimeline(
#'   username = "rstatstweet", n_tweets = 50,
#'   since = "2018-10-26", until = "2023-10-30",
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

getTweetsHistoricalTimeline <- function(
    username = "rstatstweet",
    timeout = 10,
    n_tweets = 100,
    since = "2018-10-26",
    until = "2018-10-30",
    xuser = Sys.getenv("TWITTER_USER", Sys.getenv("USER")),
    xpass = Sys.getenv("TWITTER_PASS", Sys.getenv("PASS")),
    dir = getwd(),
    save = TRUE
) {
  user_name <- paste0("https://x.com/search?f=live&q=%28from%3A", username, "%29+until%3A", until, "+since%3A", since, "&src=typed_query")
  .get_historical(
    query_url = user_name,
    prefix = paste0("historical_timeline_", username),
    n_tweets = n_tweets,
    dir = dir,
    save = save
  )
}
