#' Close Twitter Session
#'
#' @description
#'
#' <a href="https://lifecycle.r-lib.org/articles/stages.html#experimental" target="_blank"><img src="https://lifecycle.r-lib.org/articles/figures/lifecycle-experimental.svg" alt="[Experimental]"></a>
#'
#' Esta funci\u00f3n cierra la sesi\u00f3n activa de Twitter y elimina la variable global `twitter` del entorno.
#' Es \u00fatil para liberar recursos y limpiar el entorno despu\u00e9s de haber realizado operaciones de recolecci\u00f3n
#' de datos en Twitter.
#'
#' Usage
#' closeTwitter()
#'
#' @return
#' Esta funci\u00f3n no devuelve valores. Imprime un mensaje de confirmaci\u00f3n al cerrar la sesi\u00f3n
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
    print(twitter$session$close())  # Intenta cerrar la sesi\u00f3n
    Sys.sleep(1)
    rm(twitter, envir = .GlobalEnv)  # Elimina el objeto twitter del entorno global
    message("Sesi\u00f3n de Twitter cerrada correctamente.")
  }, error = function(e) {
    message("Error al intentar cerrar la sesi\u00f3n de Twitter: ", e$message)
  })
}
