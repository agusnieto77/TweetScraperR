#' Get Historical Tweets with Hashtags Iteratively
#' 
#' @description
#' 
#' <a href="https://lifecycle.r-lib.org/articles/stages.html#experimental" target="_blank"><img src="https://lifecycle.r-lib.org/articles/figures/lifecycle-experimental.svg" alt="[Experimental]"></a>
#'
#' Esta función realiza búsquedas históricas de tweets con hashtags específicos de forma iterativa,
#' permitiendo recolectar tweets en intervalos de tiempo específicos (días, horas o minutos).
#'
#' @param iterations Número de iteraciones a realizar.
#' @param hashtag Hashtag específico para buscar en los tweets.
#' @param n_tweets Número de tweets a recolectar por iteración.
#' @param since Fecha y hora de inicio para la búsqueda (formato: "YYYY-MM-DD_HH:MM:SS_UTC").
#' @param until Número de unidades de tiempo a avanzar en cada iteración.
#' @param interval_unit Unidad de tiempo para el intervalo ("days", "hours", o "minutes").
#' @param xuser Nombre de usuario de Twitter para autenticación (por defecto: variable de entorno TWITTER_USER o, en su defecto, USER).
#' @param xpass Contraseña de Twitter para autenticación (por defecto: variable de entorno TWITTER_PASS o, en su defecto, PASS).
#' @param dir Directorio para guardar los tweets recolectados (por defecto: directorio de trabajo actual).
#' @param system Sistema operativo ("windows", "unix", o "mac"). Se mantiene por compatibilidad; el cierre del navegador ya no depende del sistema operativo.
#' @param kill_system Booleano que indica si se debe cerrar el navegador (solo las sesiones propias del paquete) después de cada iteración (por defecto: FALSE).
#' @param sleep_time Tiempo de espera entre iteraciones en segundos (por defecto: 300 segundos).
#'
#' @details
#' La función realiza las siguientes operaciones:
#' 1. Valida el formato de la fecha y hora de inicio.
#' 2. Crea el directorio de destino si no existe.
#' 3. Ejecuta búsquedas históricas de tweets con el hashtag especificado de forma iterativa.
#' 4. Calcula la fecha y hora de finalización para cada iteración basándose en el intervalo especificado.
#' 5. Cierra el navegador después de cada iteración si kill_system es TRUE.
#' 6. Espera un tiempo especificado entre iteraciones.
#'
#' @return
#' No devuelve un valor explícito, pero guarda los tweets recolectados en el directorio especificado.
#'
#' @examples
#' \dontrun{
#' getTweetsHistoricalHashtagFor(
#'   iterations = 5,
#'   hashtag = "#8M",
#'   n_tweets = 500,
#'   since = "2023-03-01_00:00:00_UTC",
#'   until = 3,
#'   interval_unit = "days",
#'   dir = "./datos/tweets",
#'   system = "windows",
#'   kill_system = FALSE,
#'   sleep_time = 300
#' )
#' 
#' # Usando intervalos de horas
#' getTweetsHistoricalHashtagFor(
#'   iterations = 12,
#'   hashtag = "#8M",
#'   n_tweets = 500,
#'   since = "2023-03-01_00:00:00_UTC",
#'   until = 2,
#'   interval_unit = "hours",
#'   dir = "./datos/tweets",
#'   system = "windows",
#'   kill_system = FALSE,
#'   sleep_time = 300
#' )
#' }
#' 
#' @export
#' 

getTweetsHistoricalHashtagFor <- function(
    iterations, 
    hashtag, 
    n_tweets, 
    since,
    until,
    interval_unit = "days",
    xuser = Sys.getenv("TWITTER_USER", Sys.getenv("USER")),
    xpass = Sys.getenv("TWITTER_PASS", Sys.getenv("PASS")),
    dir = getwd(), 
    system = "windows", 
    kill_system = FALSE,
    sleep_time = 5*60
) {
  
  # Validar el formato de la fecha inicial
  .validate_datetime(since)
  
  # Crear el directorio si no existe
  if (!dir.exists(dir)) {
    dir.create(dir, recursive = TRUE)
  }
  
  # Bucle principal
  for (i in 1:iterations) {
    cat("Iteraci\u00f3n:", i, "\n")
    
    # Calcular la fecha final para esta iteración
    untilok <- .calculate_untilok(since, until, interval_unit)
    
    # Verificar si se calculó correctamente la fecha
    if (is.null(untilok)) {
      cat("Error al calcular la fecha. Deteniendo el proceso.\n")
      break
    }
    
    # Mostrar el rango de fechas que se procesará
    cat("Procesando per\u00edodo:", since, "->", untilok, "\n")
    
    tryCatch({
      TweetScraperR::getTweetsHistoricalHashtag(
        hashtag = hashtag, 
        n_tweets = n_tweets, 
        since = since,
        until = untilok,
        xuser = xuser,
        xpass = xpass,
        dir = dir
      )
      
      # Actualizar la fecha de inicio para la siguiente iteración
      since <- untilok
      
      # Solo cerrar el navegador (sesiones propias del paquete) si kill_system es TRUE
      if (kill_system) {
        .close_browser_scoped()
      }
      
      if (i < iterations) {  # No esperar despu\u00e9s de la \u00faltima iteraci\u00f3n
        Sys.sleep(3)
        cat("Esperando", sleep_time, "segundos antes de la pr\u00f3xima iteraci\u00f3n...\n")
        Sys.sleep(sleep_time-3)
      }
      
    }, error = function(e) {
      warning("Error en la iteraci\u00f3n ", i, ": ", conditionMessage(e))
      # No actualizamos 'since' si hay un error para reintentar el mismo período
    })
  }
  
  cat("Recolecci\u00f3n de tweets completada.\n")
}
