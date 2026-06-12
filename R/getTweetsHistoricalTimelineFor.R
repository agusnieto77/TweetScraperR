#' Get Historical Tweets from User Timeline Iteratively
#'
#' @description
#' 
#' <a href="https://lifecycle.r-lib.org/articles/stages.html#experimental" target="_blank"><img src="https://lifecycle.r-lib.org/articles/figures/lifecycle-experimental.svg" alt="[Experimental]"></a>
#' 
#' Esta funci\u00f3n realiza b\u00fasquedas hist\u00f3ricas de tweets de la l\u00ednea de tiempo de un usuario de forma iterativa,
#' permitiendo recolectar tweets en intervalos de tiempo espec\u00edficos (d\u00edas, horas o minutos).
#'
#' @param iterations N\u00famero de iteraciones a realizar.
#' @param username Nombre de usuario de Twitter del cual se recolectar\u00e1n los tweets.
#' @param n_tweets N\u00famero de tweets a recolectar por iteraci\u00f3n.
#' @param since Fecha y hora de inicio para la b\u00fasqueda (formato: "YYYY-MM-DD_HH:MM:SS_UTC").
#' @param until N\u00famero de unidades de tiempo a avanzar en cada iteraci\u00f3n.
#' @param interval_unit Unidad de tiempo para el intervalo ("days", "hours", o "minutes").
#' @param xuser Nombre de usuario de Twitter para autenticaci\u00f3n (por defecto: variable de entorno del sistema "USER").
#' @param xpass Contrase\u00f1a de Twitter para autenticaci\u00f3n (por defecto: variable de entorno del sistema "PASS").
#' @param dir Directorio para guardar los tweets recolectados (por defecto: directorio de trabajo actual).
#' @param system Sistema operativo ("windows", "unix", o "mac").
#' @param kill_system Booleano que indica si se debe cerrar el navegador despu\u00e9s de cada iteraci\u00f3n (por defecto: FALSE).
#' @param sleep_time Tiempo de espera entre iteraciones en segundos (por defecto: 300 segundos).
#'
#' @details
#' La funci\u00f3n realiza las siguientes operaciones:
#' 1. Valida el formato de la fecha y hora de inicio.
#' 2. Crea el directorio de destino si no existe.
#' 3. Ejecuta b\u00fasquedas hist\u00f3ricas de tweets de la l\u00ednea de tiempo del usuario de forma iterativa.
#' 4. Calcula la fecha y hora de finalizaci\u00f3n para cada iteraci\u00f3n bas\u00e1ndose en el intervalo especificado.
#' 5. Cierra el navegador despu\u00e9s de cada iteraci\u00f3n si kill_system es TRUE.
#' 6. Espera un tiempo especificado entre iteraciones.
#'
#' @return
#' No devuelve un valor expl\u00edcito, pero guarda los tweets recolectados en el directorio especificado.
#'
#' @examples
#' \dontrun{
#' # Usando intervalos de d\u00edas
#' getTweetsHistoricalTimelineFor(
#'   iterations = 5,
#'   username = "rstatstweet",
#'   n_tweets = 10,
#'   since = "2018-07-01_00:00:00_UTC",
#'   until = 60,
#'   interval_unit = "days",
#'   dir = "./datos/tweets",
#'   system = "windows",
#'   kill_system = FALSE,
#'   sleep_time = 10
#' )
#' 
#' # Usando intervalos de horas
#' getTweetsHistoricalTimelineFor(
#'   iterations = 12,
#'   username = "rstatstweet",
#'   n_tweets = 10,
#'   since = "2018-07-01_00:00:00_UTC",
#'   until = 2,
#'   interval_unit = "hours",
#'   dir = "./datos/tweets",
#'   system = "windows",
#'   kill_system = FALSE,
#'   sleep_time = 10
#' )
#' }
#' 
#' @importFrom lubridate ymd_hms days hours minutes
#' @importFrom stringr str_detect
#' 
#' @export
#' 

getTweetsHistoricalTimelineFor <- function(
    iterations, 
    username, 
    n_tweets, 
    since,
    until,
    interval_unit = "days",
    xuser = Sys.getenv("USER"),
    xpass = Sys.getenv("PASS"),
    dir = getwd(), 
    system = "windows", 
    kill_system = FALSE,
    sleep_time = 5*60
) {
  
  # Validar el formato de 'since'
  validate_datetime <- function(datetime_str) {
    pattern <- "^\\d{4}-\\d{2}-\\d{2}_\\d{2}:\\d{2}:\\d{2}_UTC$"
    if (!stringr::str_detect(datetime_str, pattern)) {
      stop("El formato de 'since' es incorrecto. Debe ser 'YYYY-MM-DD_HH:MM:SS_UTC'")
    }
  }
  
  # Funci\u00f3n para convertir el formato UTC a datetime
  parse_datetime <- function(datetime_str) {
    # Remover "_UTC" y reemplazar "_" por " "
    clean_str <- gsub("_UTC$", "", datetime_str)
    clean_str <- gsub("_", " ", clean_str)
    # Parsear la fecha
    lubridate::ymd_hms(clean_str)
  }
  
  # Funci\u00f3n para formatear datetime al formato UTC
  format_datetime <- function(datetime) {
    paste0(gsub(" ", "_", format(datetime, "%Y-%m-%d_%H:%M:%S")), "_UTC")
  }
  
  # Funci\u00f3n para calcular la fecha/hora final seg\u00fan la unidad de intervalo
  calculate_untilok <- function(since, until, interval_unit) {
    tryCatch({
      # Parsear la fecha de inicio
      since_datetime <- parse_datetime(since)
      
      # Calcular la nueva fecha seg\u00fan el intervalo
      if (interval_unit == "days") {
        untilok <- since_datetime + lubridate::days(until)
      } else if (interval_unit == "hours") {
        untilok <- since_datetime + lubridate::hours(until)
      } else if (interval_unit == "minutes") {
        untilok <- since_datetime + lubridate::minutes(until)
      } else {
        stop("interval_unit debe ser 'days', 'hours' o 'minutes'")
      }
      
      # Formatear la fecha resultante
      format_datetime(untilok)
    }, error = function(e) {
      warning("Error al calcular la fecha: ", e$message)
      return(NULL)
    })
  }
  
  # Validar el formato de la fecha inicial
  validate_datetime(since)
  
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
    
    # Calcular la fecha final para esta iteraci\u00f3n
    untilok <- calculate_untilok(since, until, interval_unit)
    
    # Verificar si se calcul\u00f3 correctamente la fecha
    if (is.null(untilok)) {
      cat("Error al calcular la fecha. Deteniendo el proceso.\n")
      break
    }
    
    # Mostrar el rango de fechas que se procesar\u00e1
    cat("Procesando tweets de @", username, " per\u00edodo: ", since, " -> ", untilok, "\n")
    
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
      
      # Actualizar la fecha de inicio para la siguiente iteraci\u00f3n
      since <- untilok
      
      # Solo cerrar el navegador si kill_system es TRUE
      if (kill_system) {
        close_browser(system)
      }
      
      if (i < iterations) {  # No esperar despu\u00e9s de la \u00faltima iteraci\u00f3n
        Sys.sleep(3)
        cat("Esperando", sleep_time, "segundos antes de la pr\u00f3xima iteraci\u00f3n...\n")
        Sys.sleep(sleep_time-3)
      }
      
    }, error = function(e) {
      warning("Error en la iteraci\u00f3n ", i, " para usuario @", username, ": ", conditionMessage(e))
      # No actualizamos 'since' si hay un error para reintentar el mismo per\u00edodo
    })
  }
  
  cat("Recolecci\u00f3n de tweets completada para usuario @", username, ".\n")
}
