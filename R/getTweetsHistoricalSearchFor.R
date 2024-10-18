#' Get Historical Tweets Iteratively
#'
#' Esta función realiza búsquedas históricas de tweets de forma iterativa,
#' permitiendo recolectar tweets en intervalos de tiempo específicos.
#'
#' @param iterations Número de iteraciones a realizar.
#' @param search Término de búsqueda para los tweets.
#' @param n_tweets Número de tweets a recolectar por iteración.
#' @param since Fecha de inicio para la búsqueda (formato: "YYYY-MM-DD").
#' @param until Número de días a avanzar en cada iteración.
#' @param xuser Nombre de usuario de Twitter para autenticación (por defecto: variable de entorno del sistema "USER").
#' @param xpass Contraseña de Twitter para autenticación (por defecto: variable de entorno del sistema "PASS").
#' @param dir Directorio para guardar los tweets recolectados (por defecto: directorio de trabajo actual).
#' @param system Sistema operativo ("windows", "unix", o "mac").
#' @param sleep_time Tiempo de espera entre iteraciones en segundos (por defecto: 300 segundos).
#'
#' @details
#' La función realiza las siguientes operaciones:
#' 1. Verifica e instala los paquetes necesarios.
#' 2. Crea el directorio de destino si no existe.
#' 3. Ejecuta búsquedas históricas de tweets de forma iterativa.
#' 4. Cierra el navegador después de cada iteración.
#' 5. Espera un tiempo especificado entre iteraciones.
#'
#' @return
#' No devuelve un valor explícito, pero guarda los tweets recolectados en el directorio especificado.
#'
#' @examples
#' \dontrun{
#' getTweetsHistoricalSearchFor(
#'   iterations = 5,
#'   search = "cambio climático",
#'   n_tweets = 1000,
#'   since = "2023-01-01",
#'   until = 7,
#'   dir = "./datos/tweets",
#'   system = "windows",
#'   sleep_time = 300
#' )
#' }
#'
#' @import rvest dplyr tibble lubridate
#' @export

getTweetsHistoricalSearchFor <- function(
    iterations, 
    search, 
    n_tweets, 
    since,
    until,
    xuser = Sys.getenv("USER"),
    xpass = Sys.getenv("PASS"),
    dir = getwd(), 
    system = "windows", 
    sleep_time = 5*60
) {
  # Verificar que TweetScraperR esté instalado
  # Lista de paquetes necesarios
  required_packages <- c("rvest", "dplyr", "tibble", "lubridate")
  
  # Función para instalar paquetes si no están instalados
  install_if_missing <- function(package) {
    if (!requireNamespace(package, quietly = TRUE)) {
      install.packages(package, dependencies = TRUE)
    }
  }
  
  # Instalar y cargar paquetes necesarios
  sapply(required_packages, install_if_missing)
  
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
      TweetScraperR::getTweetsHistoricalSearch(
        search = search, 
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
    
    close_browser(system)
    
    if (i < iterations) {  # No esperar después de la última iteración
      Sys.sleep(3)
      cat("Esperando", sleep_time, "segundos antes de la próxima iteración...\n")
      Sys.sleep(sleep_time-3)
    }
  }
  
  cat("Recolección de tweets completada.\n")
}
