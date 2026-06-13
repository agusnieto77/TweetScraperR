#' Get Tweets Replies with Data
#'
#' @description
#'
#' <a href="https://lifecycle.r-lib.org/articles/stages.html#experimental" target="_blank"><img src="https://lifecycle.r-lib.org/articles/figures/lifecycle-experimental.svg" alt="[Experimental]"></a>
#'
#' @description
#' **Obsoleta**: preféri getTweetsRepliesAPI(), basada en la API de X (datos del JSON, mas robusta).
#'
#' Esta función recupera las respuestas a un tweet específico en Twitter (ahora X),
#' incluyendo datos como el texto del tweet, usuario, fecha, y URL.
#' Utiliza web scraping para acceder a la página del tweet, iniciar sesión con las credenciales proporcionadas,
#' y recolectar la información de las respuestas al tweet.
#'
#' El proceso incluye:
#' 1. Iniciar sesión en Twitter usando las credenciales proporcionadas (si open=TRUE).
#' 2. Navegar a la URL del tweet especificado.
#' 3. Extraer la información de las respuestas mediante scraping.
#' 4. Continuar scrolling y recolectando datos hasta alcanzar el número deseado o no encontrar nuevas respuestas.
#'
#' La función guarda los datos recolectados en un archivo RDS en el directorio especificado si el parámetro 'save' es TRUE,
#' y los devuelve como un data frame.
#'
#' @param url URL del tweet del cual se quieren obtener las respuestas. Por defecto es "https://x.com/Picanumeros/status/1610715405705789442".
#' @param n_tweets El número máximo de tweets de respuestas a recuperar. Por defecto es 100.
#' @param timeout Tiempo de espera entre scrolls en segundos. Por defecto es 2.5.
#' @param xuser Nombre de usuario de Twitter para autenticación. Por defecto es el valor de la variable de entorno TWITTER_USER y, si no está definida, el de la variable de entorno del sistema USER.
#' @param xpass Contraseña de Twitter para autenticación. Por defecto es el valor de la variable de entorno TWITTER_PASS y, si no está definida, el de la variable de entorno del sistema PASS.
#' @param view Ver el navegador. Por defecto es FALSE.
#' @param dir Directorio donde se guardará el archivo RDS con los datos recolectados. Por defecto es el directorio de trabajo actual.
#' @param save Lógico. Indica si se debe guardar el resultado en un archivo RDS (por defecto TRUE).
#' @param open Lógico. Indica si se debe abrir una nueva sesión de login en Twitter (por defecto FALSE).
#'
#' @return Un data frame que contiene información sobre las respuestas al tweet especificado, incluyendo usuario, texto, fecha, URL y fecha de captura.
#' @export
#'
#' @examples
#' \dontrun{
#' getTweetsReplies(url = "https://x.com/Picanumeros/status/1610715405705789442", n_tweets = 130)
#'
#' # Sin guardar los resultados
#' getTweetsReplies(
#'   url = "https://x.com/Picanumeros/status/1610715405705789442",
#'   n_tweets = 130,
#'   save = FALSE
#' )
#'
#' # Sin abrir una nueva sesión de login
#' getTweetsReplies(
#'   url = "https://x.com/Picanumeros/status/1610715405705789442",
#'   n_tweets = 130,
#'   open = TRUE
#' )
#' }
#'
#' @references
#' Puedes encontrar más información sobre el paquete TweetScraperR en:
#' <https://github.com/agusnieto77/TweetScraperR>
#'
#' @importFrom rvest read_html_live html_elements html_element html_attr html_text
#' @importFrom tibble tibble
#' @importFrom dplyr distinct
#' @importFrom lubridate as_datetime is.POSIXct
#'
#' @note
#' Esta función utiliza web scraping y puede ser sensible a cambios en la estructura de la página de Twitter.

getTweetsReplies <- function(
    url = "https://x.com/Picanumeros/status/1610715405705789442",
    n_tweets = 100,
    timeout = 2.5,
    xuser = Sys.getenv("TWITTER_USER", Sys.getenv("USER")),
    xpass = Sys.getenv("TWITTER_PASS", Sys.getenv("PASS")),
    view = FALSE,
    dir = getwd(),
    save = TRUE,
    open = FALSE
) {
  .Deprecated(msg = "getTweetsReplies() est\u00e1 obsoleta: us\u00e1 getTweetsRepliesAPI() (basada en la API de X, datos estructurados del JSON, m\u00e1s robusta). Ver ?getTweetsRepliesAPI.")
  .get_tweets_from_url(
    target_url = url,
    tipo_label = "respuesta",
    prefix = "replies_",
    url = url,
    n_tweets = n_tweets,
    timeout = timeout,
    xuser = xuser,
    xpass = xpass,
    view = view,
    dir = dir,
    save = save,
    open = open
  )
}
