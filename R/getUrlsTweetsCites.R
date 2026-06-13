#' Get Tweets URLs Cites
#'
#' @description
#'
#' <a href="https://lifecycle.r-lib.org/articles/stages.html#experimental" target="_blank"><img src="https://lifecycle.r-lib.org/articles/figures/lifecycle-experimental.svg" alt="[Experimental]"></a>
#'
#' Esta función recupera las URLs de las citas a un tweet específico en Twitter (ahora X).
#' Utiliza web scraping para acceder a la página del tweet, iniciar sesión con las credenciales proporcionadas,
#' y recolectar las URLs de las citas al tweet.
#'
#' El proceso incluye:
#' 1. Iniciar sesión en Twitter usando las credenciales proporcionadas.
#' 2. Navegar a la URL del tweet especificado.
#' 3. Extraer las URLs de las citas mediante scraping.
#' 4. Continuar scrolling y recolectando URLs hasta alcanzar el número deseado o no encontrar nuevas URLs.
#'
#' La función guarda las URLs recolectadas en un archivo RDS en el directorio especificado si el parámetro 'save' es TRUE,
#' y las devuelve como un vector de cadenas.
#'
#' @param url URL del tweet del cual se quieren obtener las citas. Por defecto es "https://x.com/Picanumeros/status/1610715405705789442".
#' @param n_urls El número máximo de URLs de citas a recuperar. Por defecto es 100.
#' @param xuser Nombre de usuario de Twitter para autenticación. Por defecto es el valor de la variable de entorno TWITTER_USER y, si no está definida, el de la variable de entorno del sistema USER.
#' @param xpass Contraseña de Twitter para autenticación. Por defecto es el valor de la variable de entorno TWITTER_PASS y, si no está definida, el de la variable de entorno del sistema PASS.
#' @param view Ver el navegador. Por defecto es FALSE.
#' @param dir Directorio donde se guardará el archivo RDS con las URLs recolectadas. Por defecto es el directorio de trabajo actual.
#' @param save Lógico. Indica si se debe guardar el resultado en un archivo RDS (por defecto TRUE).
#'
#' @return Un vector que contiene las URLs de las citas al tweet especificado.
#' @export
#'
#' @examples
#' \dontrun{
#' getUrlsTweetsCites(url = "https://x.com/Picanumeros/status/1610715405705789442", n_urls = 130)
#'
#' # Sin guardar los resultados
#' getUrlsTweetsCites(
#'   url = "https://x.com/Picanumeros/status/1610715405705789442",
#'   n_urls = 130,
#'   save = FALSE
#' )
#' }
#'
#' @references
#' Puedes encontrar más información sobre el paquete TweetScraperR en:
#' <https://github.com/agusnieto77/TweetScraperR>
#'
#' @importFrom rvest read_html_live html_elements html_attr
#'
#' @note
#' Esta función utiliza web scraping y puede ser sensible a cambios en la estructura de la página de Twitter.

getUrlsTweetsCites <- function(
    url = "https://x.com/Picanumeros/status/1610715405705789442",
    n_urls = 100,
    xuser = Sys.getenv("TWITTER_USER", Sys.getenv("USER")),
    xpass = Sys.getenv("TWITTER_PASS", Sys.getenv("PASS")),
    view = FALSE,
    dir = getwd(),
    save = TRUE
) {
  .get_urls_from_url(
    target_url = paste0(url, "/quotes"),
    prefix = "cites_",
    url = url,
    n_urls = n_urls,
    view = view,
    dir = dir,
    save = save
  )
}

#' Motor interno compartido por getUrlsTweetsCites y getUrlsTweetsReplies
#'
#' Pipeline común de ambas funciones (navegación a la URL objetivo,
#' scroll-y-recolección de hrefs y guardado). Las funciones exportadas solo
#' difieren en la URL objetivo (con o sin sufijo "/quotes") y el prefijo
#' del archivo RDS.
#'
#' @param target_url URL a la que se navega (con o sin sufijo "/quotes").
#' @param prefix Prefijo del nombre del archivo RDS ("cites_" o "replies_").
#' @param url URL original del tweet (usada para el nombre del archivo).
#' @param n_urls,view,dir,save Parámetros de las funciones exportadas
#'   (ver su documentación).
#'
#' @return Vector character con las URLs recolectadas.
#' @noRd
.get_urls_from_url <- function(target_url, prefix, url, n_urls, view, dir, save) {
  cat("Inici\u00f3 la recolecci\u00f3n de URLs.\n")

  res <- .pw_collect(target_url, mode = "urls", n_max = n_urls, max_attempts = 3)
  if (isTRUE(res$reason == "not_logged_in")) {
    stop("No hay una sesi\u00f3n activa de X. Import\u00e1 tu sesi\u00f3n con importSessionX(auth_token, ct0) antes de scrapear.")
  }
  if (!isTRUE(res$ok)) {
    stop("No se pudo completar la operaci\u00f3n: ", .pw_or(res$error, .pw_or(res$reason, "error desconocido")))
  }
  cat("Finaliz\u00f3 la recolecci\u00f3n de URLs.\n")

  tweets_urls <- res$items
  tweets_urls <- tweets_urls[grep("/status/", tweets_urls)]
  if (length(tweets_urls) > 0) {
    tweets_urls <- utils::head(tweets_urls, n_urls)
    tweets_urls <- ifelse(grepl("^https?://", tweets_urls), tweets_urls, paste0("https://x.com", tweets_urls))
    .save_rds(
      tweets_urls, dir,
      paste0(prefix, sub("https://x.com/(.*)/status/(.*)", "\\1_\\2", url)),
      save = save, label = "URLs"
    )
  } else {
    warning("No se encontraron URLs de tweets.")
  }
  return(tweets_urls)
}
