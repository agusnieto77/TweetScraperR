#' Get Iterative Tweets in Streaming
#'
#' @description
#' 
#' <a href="https://lifecycle.r-lib.org/articles/stages.html#experimental" target="_blank"><img src="https://lifecycle.r-lib.org/articles/figures/lifecycle-experimental.svg" alt="[Experimental]"></a>
#' 
#' Esta función recolecta tweets de forma iterativa utilizando TweetScraperR,
#' con la opción de cerrar el navegador entre iteraciones.
#'
#' @param iterations Número de iteraciones a realizar
#' @param search Término de búsqueda para los tweets
#' @param n_tweets Número de tweets a recolectar en cada iteración
#' @param dir Directorio donde se guardarán los tweets
#' @param system Sistema operativo ('windows', 'unix', 'macOS')
#' @param kill_system Booleano que indica si se debe cerrar el navegador después de cada iteración (por defecto: FALSE)
#' @param sleep_time Tiempo de espera entre iteraciones en segundos
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
    dir, 
    system = "unix", 
    kill_system = FALSE,
    sleep_time = 300
) {
  # Crear el directorio si no existe
  if (!dir.exists(dir)) {
    dir.create(dir, recursive = TRUE)
  }
  
  # Función para cerrar el navegador según el sistema operativo
  close_browser <- function(system) {
    if (system == "windows") {
      system("taskkill /F /IM chrome.exe", intern = TRUE, ignore.stderr = TRUE)
    } else if (system == "unix") {
      system("pkill chrome")
    } else if (system == "mac") {
      system("pkill -x 'Google Chrome'")
    } else {
      warning("Sistema operativo no reconocido. No se cerrará el navegador.")
    }
  }
  
  # Bucle principal
  for (i in 1:iterations) {
    cat("Iteración:", i, "\n")
    
    tryCatch({
      TweetScraperR::getTweetsSearchStreaming(search = search, n_tweets = n_tweets, dir = dir)
    }, error = function(e) {
      warning("Error en la iteración ", i, ": ", conditionMessage(e))
    })
    
    # Solo cerrar el navegador si kill_system es TRUE
    if (kill_system) {
      close_browser(system)
    }
    
    if (i < iterations) {  # No esperar después de la última iteración
      cat("Esperando", sleep_time, "segundos antes de la próxima iteración...\n")
      Sys.sleep(sleep_time)
    }
  }
  
  cat("Recolección de tweets completada.\n")
}
