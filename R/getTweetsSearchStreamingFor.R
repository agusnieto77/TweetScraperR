#' Get Iterative Tweets in Streaming
#'
#' @description
#' 
#' <a href="https://lifecycle.r-lib.org/articles/stages.html#experimental" target="_blank"><img src="https://lifecycle.r-lib.org/articles/figures/lifecycle-experimental.svg" alt="[Experimental]"></a>
#' 
#' Esta funci\u00f3n recolecta tweets de forma iterativa utilizando TweetScraperR,
#' con la opci\u00f3n de cerrar el navegador entre iteraciones.
#'
#' @param iterations N\u00famero de iteraciones a realizar
#' @param search T\u00e9rmino de b\u00fasqueda para los tweets
#' @param n_tweets N\u00famero de tweets a recolectar en cada iteraci\u00f3n
#' @param sleep Tiempo de espera para la carga de tweets. Por defecto este valor es de 3 segundos.
#' @param dir Directorio donde se guardar\u00e1n los tweets
#' @param system Sistema operativo ('windows', 'unix', 'macOS')
#' @param kill_system Booleano que indica si se debe cerrar el navegador despu\u00e9s de cada iteraci\u00f3n (por defecto: FALSE)
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
  # Crear el directorio si no existe
  if (!dir.exists(dir)) {
    dir.create(dir, recursive = TRUE)
  }
  
  # Funci\u00f3n para cerrar el navegador seg\u00fan el sistema operativo
  close_browser <- function(system) {
    if (system == "windows") {
      system("taskkill /F /IM chrome.exe", intern = TRUE, ignore.stderr = TRUE)
    } else if (system == "unix") {
      system("pkill chrome")
    } else if (system == "mac") {
      system("pkill -x 'Google Chrome'")
    } else {
      warning("Sistema operativo no reconocido. No se cerrar\u00e1 el navegador.")
    }
  }
  
  # Bucle principal
  for (i in 1:iterations) {
    cat("Iteraci\u00f3n:", i, "\n")
    
    tryCatch({
      TweetScraperR::getTweetsSearchStreaming(search = search, n_tweets = n_tweets, sleep = sleep, dir = dir)
    }, error = function(e) {
      warning("Error en la iteraci\u00f3n ", i, ": ", conditionMessage(e))
    })
    
    # Solo cerrar el navegador si kill_system es TRUE
    if (kill_system) {
      close_browser(system)
    }
    
    if (i < iterations) {  # No esperar despu\u00e9s de la \u00faltima iteraci\u00f3n
      cat("Esperando", sleep_time, "segundos antes de la pr\u00f3xima iteraci\u00f3n...\n")
      Sys.sleep(sleep_time)
    }
  }
  
  cat("Recolecci\u00f3n de tweets completada.\n")
}
