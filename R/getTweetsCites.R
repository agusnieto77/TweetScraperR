#' Get Tweets Cites with Data
#'
#' @description
#'
#' <a href="https://lifecycle.r-lib.org/articles/stages.html#experimental" target="_blank"><img src="https://lifecycle.r-lib.org/articles/figures/lifecycle-experimental.svg" alt="[Experimental]"></a>
#'
#' Esta función recupera las citas a un tweet específico en Twitter (ahora X),
#' incluyendo datos como el texto del tweet, usuario, fecha, y URL.
#' Utiliza web scraping para acceder a la página del tweet, iniciar sesión con las credenciales proporcionadas,
#' y recolectar la información de las citas al tweet.
#'
#' El proceso incluye:
#' 1. Iniciar sesión en Twitter usando las credenciales proporcionadas (si open=TRUE).
#' 2. Navegar a la URL del tweet especificado con "/quotes" para ver las citas.
#' 3. Extraer la información de las citas mediante scraping.
#' 4. Continuar scrolling y recolectando datos hasta alcanzar el número deseado o no encontrar nuevas citas.
#'
#' La función guarda los datos recolectados en un archivo RDS en el directorio especificado si el parámetro 'save' es TRUE,
#' y los devuelve como un data frame.
#'
#' @param url URL del tweet del cual se quieren obtener las citas. Por defecto es "https://x.com/Picanumeros/status/1610715405705789442".
#' @param n_tweets El número máximo de tweets de citas a recuperar. Por defecto es 100.
#' @param timeout Tiempo de espera entre scrolls en segundos. Por defecto es 2.5.
#' @param xuser Nombre de usuario de Twitter para autenticación. Por defecto es el valor de la variable de entorno TWITTER_USER y, si no está definida, el de la variable de entorno del sistema USER.
#' @param xpass Contraseña de Twitter para autenticación. Por defecto es el valor de la variable de entorno TWITTER_PASS y, si no está definida, el de la variable de entorno del sistema PASS.
#' @param view Ver el navegador. Por defecto es FALSE.
#' @param dir Directorio donde se guardará el archivo RDS con los datos recolectados. Por defecto es el directorio de trabajo actual.
#' @param save Lógico. Indica si se debe guardar el resultado en un archivo RDS (por defecto TRUE).
#' @param open Lógico. Indica si se debe abrir una nueva sesión de login en Twitter (por defecto FALSE).
#'
#' @return Un data frame que contiene información sobre las citas al tweet especificado, incluyendo usuario, texto, fecha, URL y fecha de captura.
#' @export
#'
#' @examples
#' \dontrun{
#' getTweetsCites(url = "https://x.com/Picanumeros/status/1610715405705789442", n_tweets = 130)
#'
#' # Sin guardar los resultados
#' getTweetsCites(
#'   url = "https://x.com/Picanumeros/status/1610715405705789442",
#'   n_tweets = 130,
#'   save = FALSE
#' )
#'
#' # Sin abrir una nueva sesión de login
#' getTweetsCites(
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

getTweetsCites <- function(
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
  .get_tweets_from_url(
    target_url = paste0(url, "/quotes"),
    tipo_label = "citas",
    prefix = "cites_",
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

#' Motor interno compartido por getTweetsCites y getTweetsReplies
#'
#' Pipeline común de ambas funciones (navegación a la URL objetivo mediante el
#' motor Playwright reutilizando la sesión importada, recolección de articles,
#' extracción y guardado). Las funciones exportadas solo difieren en la URL
#' objetivo (con o sin sufijo "/quotes"), la etiqueta de los mensajes y el
#' prefijo del archivo RDS.
#'
#' @param target_url URL a la que se navega (con o sin sufijo "/quotes").
#' @param tipo_label Etiqueta para los mensajes ("citas" o "respuesta").
#' @param prefix Prefijo del nombre del archivo RDS ("cites_" o "replies_").
#' @param url URL original del tweet (usada para el nombre del archivo).
#' @param n_tweets,timeout,xuser,xpass,view,dir,save,open Parámetros de las
#'   funciones exportadas (ver su documentación).
#'
#' @return Tibble con los tweets recolectados, o NULL si no hubo articles.
#' @noRd
.get_tweets_from_url <- function(target_url, tipo_label, prefix, url,
                                 n_tweets, timeout, xuser, xpass, view,
                                 dir, save, open) {
  cat(paste0("Inici\u00f3 la recolecci\u00f3n de tweets de ", tipo_label, ".\n"))

  res <- .pw_collect(target_url, mode = "articles", n_max = n_tweets, max_attempts = 3)
  if (isTRUE(res$reason == "not_logged_in")) {
    stop("No hay una sesi\u00f3n activa de X. Import\u00e1 tu sesi\u00f3n con importSessionX(auth_token, ct0) antes de scrapear.")
  }
  if (!isTRUE(res$ok)) {
    stop("No se pudo completar la operaci\u00f3n: ", .pw_or(res$error, .pw_or(res$reason, "error desconocido")))
  }

  cat(paste0("Finaliz\u00f3 la recolecci\u00f3n de tweets de ", tipo_label, ".\n"))
  cat("Procesando datos...\n")

  articles <- res$items

  # Procesar los artículos recolectados
  if (length(articles) > 0) {
    tweets_recolectados <- .extract_tweet_data(articles)

    # Guardar resultados si save es TRUE
    .save_rds(
      tweets_recolectados, dir,
      paste0(prefix, sub("https://x.com/(.*)/status/(.*)", "\\1_\\2", url)),
      save = save
    )

    cat(paste0("Tweets de ", tipo_label, " \u00fanicos recolectados:"), length(tweets_recolectados$url), "\n")

    # Devolver el data frame
    return(tweets_recolectados)
  } else {
    cat("No hay art\u00edculos para procesar.\n")
    return(NULL)
  }
}
