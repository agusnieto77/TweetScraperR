#' closeTwitter {TweetScraperR}
#' 
#' Close Twitter Session
#' 
#' @description
#' 
#' <a href="https://lifecycle.r-lib.org/articles/stages.html#experimental" target="_blank"><img src="https://lifecycle.r-lib.org/articles/figures/lifecycle-experimental.svg" alt="[Experimental]"></a>
#' 
#' Esta función cierra la sesión activa de Twitter y elimina la variable global `twitter` del entorno. 
#' Es útil para liberar recursos y limpiar el entorno después de haber realizado operaciones de recolección
#' de datos en Twitter.
#' 
#' Usage
#' closeTwitter()
#' 
#' @return 
#' Esta función no devuelve valores. Imprime un mensaje de confirmación al cerrar la sesión 
#' y elimina la variable `twitter` del entorno global.
#' 
#' @examples
#' \dontrun{
#' closeTwitter()
#' }
#' 
#' @export

closeTwitter <- function() {
  tryCatch({
    print(twitter$session$close())  # Intenta cerrar la sesión
    Sys.sleep(1)
    rm(twitter, envir = .GlobalEnv)  # Elimina el objeto twitter del entorno global
    message("Sesión de Twitter cerrada correctamente.")
  }, error = function(e) {
    message("Error al intentar cerrar la sesión de Twitter: ", e$message)
  })
}
