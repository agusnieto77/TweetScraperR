#' openTwitter {TweetScraperR}
#' 
#' Open Twitter Login Page
#' 
#' @description
#' 
#' <a href="https://lifecycle.r-lib.org/articles/stages.html#experimental" target="_blank"><img src="https://lifecycle.r-lib.org/articles/figures/lifecycle-experimental.svg" alt="[Experimental]"></a>
#' 
#' Esta función permite abrir la página de inicio de sesión de Twitter en un navegador web y 
#' guardar la instancia HTML en el entorno global. Es útil para iniciar el proceso de autenticación 
#' antes de realizar la recolección de datos de Twitter.
#' 
#' @param view Logical. If TRUE (default), returns a view of the HTML instance. If FALSE, returns the HTML instance itself.
#' 
#' @usage openTwitter(view = TRUE)
#' 
#' @return 
#' Si `view` es TRUE, devuelve una vista de la instancia HTML de la página de inicio de sesión de Twitter.
#' Si `view` es FALSE, devuelve la instancia HTML directamente.
#' En ambos casos, la información de la sesión se guarda en la variable global `twitter` para su uso posterior.
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

openTwitter <- function(view = TRUE) {
  tryCatch({
    twitter <- rvest::read_html_live("https://x.com/i/flow/login")
    
    assign("twitter", twitter, envir = .GlobalEnv)
    
    if (view) {
      return(twitter$view())
    } else {
      return(twitter)
    }
  }, error = function(e) {
    message("Error al abrir la página de Twitter: ", e$message)
    return(NULL)
  })
}
