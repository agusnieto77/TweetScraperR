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
#' Usage
#' openTwitter()
#' 
#' @return 
#' Devuelve una vista de la instancia HTML de la página de inicio de sesión de Twitter. 
#' La información de la sesión se guarda en la variable global `twitter` para su uso posterior.
#' 
#' @examples
#' \dontrun{
#' openTwitter()
#' }
#' 
#' @export

openTwitter <- function() {
  tryCatch({
    twitter <- rvest::read_html_live("https://x.com/i/flow/login")
    
    assign("twitter", twitter, envir = .GlobalEnv)
    
    return(twitter$view())
  }, error = function(e) {
    message("Error al abrir la página de Twitter: ", e$message)
    return(NULL)
  })
}
