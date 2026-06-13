#' Get Users Retweets with Data
#'
#' @description
#'
#' <a href="https://lifecycle.r-lib.org/articles/stages.html#experimental" target="_blank"><img src="https://lifecycle.r-lib.org/articles/figures/lifecycle-experimental.svg" alt="[Experimental]"></a>
#'
#' Esta función recupera los retweets a un tweet específico en Twitter (ahora X),
#' incluyendo datos como el user name, name y URL.
#' Utiliza web scraping para acceder a la página del tweet, iniciar sesión con las credenciales proporcionadas,
#' y recolectar la información de los retweets al tweet.
#'
#' El proceso incluye:
#' 1. Iniciar sesión en Twitter usando las credenciales proporcionadas (si open=TRUE).
#' 2. Navegar a la URL del tweet especificado con "/retweets" para ver los retweets.
#' 3. Extraer la información de los retweets mediante scraping.
#' 4. Continuar scrolling y recolectando datos hasta alcanzar el número deseado o no encontrar nuevas citas.
#'
#' La función guarda los datos recolectados en un archivo RDS en el directorio especificado si el parámetro 'save' es TRUE,
#' y los devuelve como un data frame.
#'
#' @param url URL del tweet del cual se quieren obtener los retweets. Por defecto es "https://x.com/tipsder/status/1672311054922293254".
#' @param n_users El número máximo de users a recuperar. Por defecto es 100.
#' @param timeout Tiempo de espera entre scrolls en segundos. Por defecto es 2.5.
#' @param xuser Nombre de usuario de Twitter para autenticación. Por defecto es el valor de la variable de entorno TWITTER_USER y, si no está definida, el de la variable de entorno del sistema USER.
#' @param xpass Contraseña de Twitter para autenticación. Por defecto es el valor de la variable de entorno TWITTER_PASS y, si no está definida, el de la variable de entorno del sistema PASS.
#' @param view Ver el navegador. Por defecto es FALSE.
#' @param dir Directorio donde se guardará el archivo RDS con los datos recolectados. Por defecto es el directorio de trabajo actual.
#' @param save Lógico. Indica si se debe guardar el resultado en un archivo RDS (por defecto TRUE).
#' @param open Lógico. Indica si se debe abrir una nueva sesión de login en Twitter (por defecto FALSE).
#'
#' @return Un data frame que contiene información sobre los users que rt el tweet especificado, incluyendo usuario, URL y fecha de captura.
#' @export
#'
#' @examples
#' \dontrun{
#' getTweetsRetweets(url = "https://x.com/tipsder/status/1672311054922293254", n_users = 20)
#'
#' # Sin guardar los resultados
#' getTweetsRetweets(
#'   url = "https://x.com/tipsder/status/1672311054922293254",
#'   n_users = 20,
#'   save = FALSE
#' )
#'
#' # Sin abrir una nueva sesión de login
#' getTweetsRetweets(
#'   url = "https://x.com/tipsder/status/1672311054922293254",
#'   n_users = 20,
#'   open = TRUE
#' )
#' }
#'
#' @references
#' Puedes encontrar más información sobre el paquete TweetScraperR en:
#' <https://github.com/agusnieto77/TweetScraperR>
#'
#' @importFrom rvest html_elements html_element html_attr html_text
#' @importFrom tibble tibble
#' @importFrom dplyr distinct
#' @importFrom lubridate as_datetime is.POSIXct
#'
#' @note
#' Esta función utiliza web scraping y puede ser sensible a cambios en la estructura de la página de Twitter.

getTweetsRetweets <- function(
    url = "https://x.com/tipsder/status/1672311054922293254",
    n_users = 100,
    timeout = 2.5,
    xuser = Sys.getenv("TWITTER_USER", Sys.getenv("USER")),
    xpass = Sys.getenv("TWITTER_PASS", Sys.getenv("PASS")),
    view = FALSE,
    dir = getwd(),
    save = TRUE,
    open = FALSE
) {
  urlrt <- paste0(url, "/retweets")
  cat("Inici\u00f3 la recolecci\u00f3n de users.\n")
  res <- .pw_collect(urlrt, mode = "users", n_max = n_users, max_attempts = 3)
  if (isTRUE(res$reason == "not_logged_in")) stop("No hay una sesi\u00f3n activa de X. Import\u00e1 tu sesi\u00f3n con importSessionX(auth_token, ct0) antes de scrapear.")
  if (!isTRUE(res$ok)) stop("No se pudo completar la operaci\u00f3n: ", .pw_or(res$error, .pw_or(res$reason, "error desconocido")))
  cat("Finaliz\u00f3 la recolecci\u00f3n de users.\n")
  cat("Procesando datos...\n")
  users <- res$items

  # Procesar los artículos recolectados
  if (length(users) > 0) {
    # Crear un data frame para almacenar los datos
    users_recolectados <- tibble::tibble(
      art_html = users,
      user_name = "",
      user = "",
      url_user = "",
      url_rt = url,
      fecha_captura = Sys.time()
    )

    user_name <- "span.css-1jxf684.r-bcqeeo.r-1ttztb7.r-qvutc0.r-poiln3"
    user      <- "div.css-146c3p1.r-dnmrzs.r-1udh08x.r-1udbk01.r-3s2u2q.r-bcqeeo.r-1ttztb7.r-qvutc0.r-37j5jr.r-a023e6.r-rjixqe.r-16dba41.r-18u37iz.r-1wvb978 span.css-1jxf684.r-bcqeeo.r-1ttztb7.r-qvutc0.r-poiln3"
    url_user  <- "div.css-175oi2r.r-1wbh5a2.r-dnmrzs a"

    # Extraer información de cada artículo (parseando el HTML una sola vez)
    for (i in 1:length(users_recolectados$art_html)) {
      tryCatch({
        doc <- rvest::read_html(users[[i]])

        # Extraer usuario
        users_recolectados$user_name[i] <- rvest::html_text(rvest::html_element(doc, css = user_name))

        # Extraer texto del tweet
        users_recolectados$user[i] <- rvest::html_text(rvest::html_element(doc, css = user))

        # Extraer URL
        users_recolectados$url_user[i] <- paste0("https://x.com", rvest::html_attr(rvest::html_element(doc, css = url_user), "href"))
      }, error = function(e) {
        message("Error al procesar el art\u00edculo ", i, ": ", e$message)
      })
    }

    # Eliminar duplicados
    users_recolectados <- dplyr::distinct(users_recolectados, url_user, .keep_all = TRUE)

    # Guardar resultados si save es TRUE
    .save_rds(
      users_recolectados, dir,
      paste0("rt_", sub("https://x.com/(.*)/status/(.*)", "\\1_\\2", url)),
      save = save
    )

    cat("Users \u00fanicos recolectados:", length(users_recolectados$url_user), "\n")

    # Devolver el data frame
    return(users_recolectados)
  } else {
    cat("No hay art\u00edculos para procesar.\n")
    return(NULL)
  }
}
