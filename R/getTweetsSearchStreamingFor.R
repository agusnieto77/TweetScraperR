#' Get Iterative Tweets in Streaming
#'
#' @description
#' 
#' <a href="https://lifecycle.r-lib.org/articles/stages.html#experimental" target="_blank"><img src="https://lifecycle.r-lib.org/articles/figures/lifecycle-experimental.svg" alt="[Experimental]"></a>
#'
#' @description
#' **Obsoleta**: preferí getTweetsSearchAPI(), basada en la API de X (datos del JSON, mas robusta).
#'
#' Esta función recolecta tweets de forma iterativa utilizando TweetScraperR,
#' con la opción de cerrar el navegador entre iteraciones.
#'
#' @param iterations Número de iteraciones a realizar
#' @param search Término de búsqueda para los tweets
#' @param n_tweets Número de tweets a recolectar en cada iteración
#' @param sleep Tiempo de espera para la carga de tweets. Por defecto este valor es de 3 segundos.
#' @param dir Directorio donde se guardarán los tweets
#' @param system Sistema operativo ('windows', 'unix', 'macOS'). Se mantiene por compatibilidad; el cierre del navegador ya no depende del sistema operativo.
#' @param kill_system Booleano que indica si se debe cerrar el navegador (solo las sesiones propias del paquete) después de cada iteración (por defecto: FALSE)
#' @param sleep_time Tiempo de espera entre iteraciones en segundos. Por defecto este valor es de 300 segundos.
#'
#' @return No devuelve un valor, pero guarda los tweets en el directorio especificado
#' @export
#'
#' @examples
#' \dontrun{
#' getTweetsSearchStreamingFor(
#'   iterations = 5,
#'   search = "Milei",
#'   n_tweets = 10,
#'   dir = "./data/tweets",
#'   system = "unix",
#'   kill_system = FALSE,
#'   sleep_time = 5
#' )
#' }

getTweetsSearchStreamingFor <- function(
    iterations, 
    search, 
    n_tweets, 
    sleep,
    dir, 
    system = "unix", 
    kill_system = FALSE,
    sleep_time = 300
) {
  .Deprecated(msg = "getTweetsSearchStreamingFor() est\u00e1 obsoleta: us\u00e1 getTweetsSearchAPI() (basada en la API de X, datos estructurados del JSON, m\u00e1s robusta). Ver ?getTweetsSearchAPI.")
  # Crear el directorio si no existe
  if (!dir.exists(dir)) {
    dir.create(dir, recursive = TRUE)
  }
  
  # Bucle principal
  for (i in 1:iterations) {
    cat("Iteraci\u00f3n:", i, "\n")
    
    tryCatch({
      TweetScraperR::getTweetsSearchStreaming(search = search, n_tweets = n_tweets, sleep = sleep, dir = dir)
    }, error = function(e) {
      warning("Error en la iteraci\u00f3n ", i, ": ", conditionMessage(e))
    })
    
    # Solo cerrar el navegador (sesiones propias del paquete) si kill_system es TRUE
    if (kill_system) {
      .close_browser_scoped()
    }
    
    if (i < iterations) {  # No esperar despu\u00e9s de la \u00faltima iteraci\u00f3n
      cat("Esperando", sleep_time, "segundos antes de la pr\u00f3xima iteraci\u00f3n...\n")
      Sys.sleep(sleep_time)
    }
  }
  
  cat("Recolecci\u00f3n de tweets completada.\n")
}
