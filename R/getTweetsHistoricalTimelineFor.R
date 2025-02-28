#' Get Historical Tweets from User Timeline Iteratively
#'
#' @description
#' 
#' <a href="https://lifecycle.r-lib.org/articles/stages.html#experimental" target="_blank"><img src="https://lifecycle.r-lib.org/articles/figures/lifecycle-experimental.svg" alt="[Experimental]"></a>
#' 
#' Esta función realiza búsquedas históricas de tweets de la línea de tiempo de un usuario de forma iterativa,
#' permitiendo recolectar tweets en intervalos de tiempo específicos.
#'
#' @param iterations Número de iteraciones a realizar.
#' @param username Nombre de usuario de Twitter del cual se recolectarán los tweets.
#' @param n_tweets Número de tweets a recolectar por iteración.
#' @param since Fecha de inicio para la búsqueda (formato: "YYYY-MM-DD").
#' @param until Número de días a avanzar en cada iteración.
#' @param xuser Nombre de usuario de Twitter para autenticación (por defecto: variable de entorno del sistema "USER").
#' @param xpass Contraseña de Twitter para autenticación (por defecto: variable de entorno del sistema "PASS").
#' @param dir Directorio para guardar los tweets recolectados (por defecto: directorio de trabajo actual).
#' @param system Sistema operativo ("windows", "unix", o "mac").
#' @param kill_system Booleano que indica si se debe cerrar el navegador después de cada iteración (por defecto: FALSE).
#' @param sleep_time Tiempo de espera entre iteraciones en segundos (por defecto: 300 segundos).
#'
#' @details
#' La función realiza las siguientes operaciones:
#' 1. Verifica e instala los paquetes necesarios.
#' 2. Crea el directorio de destino si no existe.
#' 3. Ejecuta búsquedas históricas de tweets de la línea de tiempo del usuario de forma iterativa.
#' 4. Cierra el navegador después de cada iteración si kill_system es TRUE.
#' 5. Espera un tiempo especificado entre iteraciones.
#'
#' @return
#' No devuelve un valor explícito, pero guarda los tweets recolectados en el directorio especificado.
#'
#' @examples
#' \dontrun{
#' getTweetsHistoricalTimelineFor(
#'   iterations = 5,
#'   username = "rstatstweet",
#'   n_tweets = 10,
#'   since = "2018-07-01",
#'   until = 60,
#'   dir = "./datos/tweets",
#'   system = "windows",
#'   kill_system = FALSE,
#'   sleep_time = 10
#' )
#' }
#' 
#' @export
#' 

getTweetsHistoricalTimelineFor <- function(
    iterations, 
    username, 
    n_tweets, 
    since,
    until,
    xuser = Sys.getenv("USER"),
    xpass = Sys.getenv("PASS"),
    dir = getwd(), 
    system = "windows", 
    kill_system = FALSE,
    sleep_time = 5*60
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
    untilok <- as.Date(since) + until
    untilok <- as.character(untilok)
    tryCatch({
      TweetScraperR::getTweetsHistoricalTimeline(
        username = username, 
        n_tweets = n_tweets, 
        since = since,
        until = untilok,
        xuser = xuser,
        xpass = xpass,
        dir = dir
      )
    }, error = function(e) {
      warning("Error en la iteración ", i, ": ", conditionMessage(e))
    })
    
    since = untilok
    
    # Solo cerrar el navegador si kill_system es TRUE
    if (kill_system) {
      close_browser(system)
    }
    
    if (i < iterations) {  # No esperar después de la última iteración
      Sys.sleep(3)
      cat("Esperando", sleep_time, "segundos antes de la próxima iteración...\n")
      Sys.sleep(sleep_time-3)
    }
  }
  
  cat("Recolección de tweets completada.\n")
}
