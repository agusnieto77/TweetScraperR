#' Open Timeline User
#'
#' @description
#' 
#' <a href="https://lifecycle.r-lib.org/articles/stages.html#experimental" target="_blank"><img src="https://lifecycle.r-lib.org/articles/figures/lifecycle-experimental.svg" alt="[Experimental]"></a>
#' 
#' Esta funci\u00f3n abre la l\u00ednea de tiempo de un usuario espec\u00edfico de Twitter (X) y crea un objeto
#' que contiene la informaci\u00f3n de la p\u00e1gina. Intenta abrir la p\u00e1gina hasta tres veces en caso de error.
#'
#' @param username Character. El nombre de usuario de Twitter cuya l\u00ednea de tiempo se desea abrir.
#'                 Por defecto es "rstatstweet".
#' @param view Logical. Si es TRUE (por defecto), muestra la vista de la p\u00e1gina web.
#'             Si es FALSE, solo crea el objeto sin mostrar la vista.
#'
#' @return Si view es TRUE, devuelve la vista de la p\u00e1gina web.
#'         Si view es FALSE, devuelve un mensaje indicando que se ha creado el objeto "timeline".
#'         En caso de error despu\u00e9s de tres intentos, devuelve NULL.
#'
#' @details
#' La funci\u00f3n utiliza `rvest::read_html_live()` para leer la p\u00e1gina web de la l\u00ednea de tiempo
#' del usuario especificado. Crea un objeto global llamado "timeline" que contiene la informaci\u00f3n
#' de la p\u00e1gina. Si ocurre un error al intentar abrir la p\u00e1gina, la funci\u00f3n reintentar\u00e1 hasta
#' tres veces antes de fallar.
#'
#' @note
#' Esta funci\u00f3n requiere una conexi\u00f3n a Internet activa y puede estar sujeta a las limitaciones
#' de acceso impuestas por Twitter (X).
#'
#' @examples
#' \dontrun{
#' # Abrir la l\u00ednea de tiempo de un usuario espec\u00edfico y mostrar la vista
#' openTimeline("hadleywickham")
#'
#' # Crear el objeto timeline sin mostrar la vista
#' openTimeline("rstudio", view = FALSE)
#' }
#'
#' @importFrom rvest read_html_live
#'
#' @export
#' 
#' 
openTimeline <- function(username = "rstatstweet", view = TRUE) {
  max_attempts <- 3
  attempts <- 0
  while (attempts < max_attempts) {
    attempts <- attempts + 1
    tryCatch({
      timeline <- rvest::read_html_live(paste0("https://x.com/", username))
      assign("timeline", timeline, envir = .GlobalEnv)
      if (view) {
        return(timeline$view())
      } else {
        return(message('Objeto "timeline" creado.'))
      }
    }, error = function(e) {
      if (attempts < max_attempts) {
        message("Error al abrir la p\u00e1gina de Twitter (intento ", attempts, " de ", max_attempts, "): ", e$message)
        message("Reintentando...")
        Sys.sleep(2)
      } else {
        message("No se pudo abrir la p\u00e1gina de Twitter luego de 3 intentos. Por favor, intente m\u00e1s tarde.")
        return(NULL)
      }
    })
  }
  return(NULL)
}
