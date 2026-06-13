#' Close Twitter Session
#'
#' @description
#'
#' <a href="https://lifecycle.r-lib.org/articles/stages.html#experimental" target="_blank"><img src="https://lifecycle.r-lib.org/articles/figures/lifecycle-experimental.svg" alt="[Experimental]"></a>
#'
#' @description
#' **Obsoleta**: el login automatizado por navegador ya no funciona porque X lo bloquea por fingerprint.
#' Usá `importSessionX(auth_token, ct0)` para cargar tu sesión desde el navegador.
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
  .Deprecated(msg = "closeTwitter() qued\u00f3 obsoleta: X bloquea el login automatizado. Us\u00e1 importSessionX(auth_token, ct0) para cargar tu sesi\u00f3n desde el navegador. Ver ?importSessionX.")
  tryCatch({
    twitter <- get0("twitter", envir = .tsr_env)
    print(twitter$session$close())  # Intenta cerrar la sesi\u00f3n
    Sys.sleep(1)
    if (exists("twitter", envir = .tsr_env)) rm("twitter", envir = .tsr_env)  # Elimina el objeto twitter
    message("Sesi\u00f3n de Twitter cerrada correctamente.")
  }, error = function(e) {
    message("Error al intentar cerrar la sesi\u00f3n de Twitter: ", e$message)
  })
}
