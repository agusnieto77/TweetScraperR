#' Close Timeline Session
#'
#' @description
#' 
#' <a href="https://lifecycle.r-lib.org/articles/stages.html#experimental" target="_blank"><img src="https://lifecycle.r-lib.org/articles/figures/lifecycle-experimental.svg" alt="[Experimental]"></a>
#' 
#' Esta funci\u00f3n cierra la sesi\u00f3n de la l\u00ednea de tiempo de Twitter previamente abierta
#' con la funci\u00f3n `openTimeline()`. Intenta cerrar la sesi\u00f3n del navegador y elimina
#' el objeto 'timeline' del entorno global.
#'
#' @return
#' No devuelve ning\u00fan valor, pero imprime mensajes en la consola sobre el resultado
#' de la operaci\u00f3n.
#'
#' @details
#' La funci\u00f3n realiza las siguientes acciones:
#' 1. Intenta cerrar la sesi\u00f3n del navegador asociada al objeto 'timeline'.
#' 2. Espera un segundo para asegurar que la sesi\u00f3n se cierre correctamente.
#' 3. Elimina el objeto 'timeline' del entorno global.
#' 4. Muestra un mensaje de \u00e9xito si todas las operaciones se realizan correctamente.
#'
#' Si ocurre alg\u00fan error durante el proceso, se captura y se muestra un mensaje de error.
#'
#' @note
#' Esta funci\u00f3n asume que existe un objeto 'timeline' en el entorno global,
#' creado previamente por la funci\u00f3n `openTimeline()`. Si el objeto no existe,
#' se producir\u00e1 un error.
#'
#' @examples
#' \dontrun{
#' # Primero, abrir una l\u00ednea de tiempo
#' openTimeline("rstatstweet")
#' 
#' # Luego, cerrar la l\u00ednea de tiempo
#' closeTimeline()
#' }
#'
#' @seealso 
#' \code{\link{openTimeline}} para abrir una l\u00ednea de tiempo de Twitter.
#'
#' @export
#' 
closeTimeline <- function() {
  tryCatch({
    print(timeline$session$close())  # Intenta cerrar la sesi\u00f3n
    Sys.sleep(1)
    rm(timeline, envir = .GlobalEnv)  # Elimina el objeto timeline del entorno global
    message("Timeline cerrado correctamente.")
  }, error = function(e) {
    message("Error al intentar cerrar el Timeline: ", e$message)
  })
}
