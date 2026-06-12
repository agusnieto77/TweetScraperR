#' Open Twitter Login Page
#'
#' @description
#'
#' <a href="https://lifecycle.r-lib.org/articles/stages.html#experimental" target="_blank"><img src="https://lifecycle.r-lib.org/articles/figures/lifecycle-experimental.svg" alt="[Experimental]"></a>
#'
#' Esta funci\u00f3n permite abrir la p\u00e1gina de inicio de sesi\u00f3n de Twitter en un navegador web y
#' guardar la instancia HTML en el entorno global. Es \u00fatil para iniciar el proceso de autenticaci\u00f3n
#' antes de realizar la recolecci\u00f3n de datos de Twitter.
#'
#' @param view Logical. If TRUE (default), returns a view of the HTML instance. If FALSE, returns the HTML instance itself.
#'
#' @usage openTwitter(view = TRUE)
#'
#' @return
#' Si `view` es TRUE, devuelve una vista de la instancia HTML de la p\u00e1gina de inicio de sesi\u00f3n de Twitter.
#' Si `view` es FALSE, devuelve la instancia HTML directamente.
#' En ambos casos, la informaci\u00f3n de la sesi\u00f3n se guarda en la variable global `twitter` para su uso posterior.
#'
#' @examples
#' \dontrun{
#' # Para obtener la vista (comportamiento predeterminado)
#' openTwitter()
#'
#' # Para obtener el objeto twitter sin la vista
#' twitter <- openTwitter(view = FALSE)
#' }
#'
#' @export
#'
#' @importFrom rvest read_html_live
#'

openTwitter <- function(view = TRUE) {
  max_attempts <- 3
  attempts <- 0
  while (attempts < max_attempts) {
    attempts <- attempts + 1
    tryCatch({
      twitter <- rvest::read_html_live("https://x.com/i/flow/login")
      assign("twitter", twitter, envir = .GlobalEnv)
      if (view) {
        return(twitter$view())
      } else {
        return(message('Objeto "twitter" creado.'))
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