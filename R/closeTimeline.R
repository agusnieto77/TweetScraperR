#' Close Timeline Session
#'
#' @description
#' 
#' <a href="https://lifecycle.r-lib.org/articles/stages.html#experimental" target="_blank"><img src="https://lifecycle.r-lib.org/articles/figures/lifecycle-experimental.svg" alt="[Experimental]"></a>
#'
#' @description
#' **Obsoleta**: el login automatizado por navegador ya no funciona porque X lo bloquea por fingerprint.
#' Usá `importSessionX(auth_token, ct0)` para cargar tu sesión desde el navegador.
#'
#' Esta función cierra la sesión de la línea de tiempo de Twitter previamente abierta
#' con la función `openTimeline()`. Intenta cerrar la sesión del navegador y elimina
#' el objeto 'timeline' del entorno global.
#'
#' @return
#' No devuelve ningún valor, pero imprime mensajes en la consola sobre el resultado
#' de la operación.
#'
#' @details
#' La función realiza las siguientes acciones:
#' 1. Intenta cerrar la sesión del navegador asociada al objeto 'timeline'.
#' 2. Espera un segundo para asegurar que la sesión se cierre correctamente.
#' 3. Elimina el objeto 'timeline' del entorno global.
#' 4. Muestra un mensaje de éxito si todas las operaciones se realizan correctamente.
#'
#' Si ocurre algún error durante el proceso, se captura y se muestra un mensaje de error.
#'
#' @note
#' Esta función asume que existe un objeto 'timeline' en el entorno global,
#' creado previamente por la función `openTimeline()`. Si el objeto no existe,
#' se producirá un error.
#'
#' @examples
#' \dontrun{
#' # Primero, abrir una línea de tiempo
#' openTimeline("rstatstweet")
#' 
#' # Luego, cerrar la línea de tiempo
#' closeTimeline()
#' }
#'
#' @seealso 
#' \code{\link{openTimeline}} para abrir una línea de tiempo de Twitter.
#'
#' @export
#' 
closeTimeline <- function() {
  .Deprecated(msg = "closeTimeline() qued\u00f3 obsoleta: X bloquea el login automatizado. Us\u00e1 importSessionX(auth_token, ct0) para cargar tu sesi\u00f3n desde el navegador. Ver ?importSessionX.")
  tryCatch({
    timeline <- get0("timeline", envir = .tsr_env)
    print(timeline$session$close())  # Intenta cerrar la sesi\u00f3n
    Sys.sleep(1)
    if (exists("timeline", envir = .tsr_env)) rm("timeline", envir = .tsr_env)  # Elimina el objeto timeline
    message("Timeline cerrado correctamente.")
  }, error = function(e) {
    message("Error al intentar cerrar el Timeline: ", e$message)
  })
}
