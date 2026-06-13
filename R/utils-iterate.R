# Helpers internos para las funciones iterativas (*For) -------------------
#
# Promovidos verbatim de los helpers locales de getTweetsHistoricalSearchFor.R
# (lineas 76-126), mas un cierre de navegador acotado al paquete que
# reemplaza los pkill/taskkill globales.

#' Valida el formato 'YYYY-MM-DD_HH:MM:SS_UTC' de un datetime
#' @noRd
.validate_datetime <- function(datetime_str) {
  pattern <- "^\\d{4}-\\d{2}-\\d{2}_\\d{2}:\\d{2}:\\d{2}_UTC$"
  if (!stringr::str_detect(datetime_str, pattern)) {
    stop("El formato de 'since' es incorrecto. Debe ser 'YYYY-MM-DD_HH:MM:SS_UTC'")
  }
}

#' Convierte el formato 'YYYY-MM-DD_HH:MM:SS_UTC' a datetime
#' @noRd
.parse_datetime <- function(datetime_str) {
  # Remover "_UTC" y reemplazar "_" por " "
  clean_str <- gsub("_UTC$", "", datetime_str)
  clean_str <- gsub("_", " ", clean_str)
  # Parsear la fecha
  lubridate::ymd_hms(clean_str)
}

#' Formatea un datetime al formato 'YYYY-MM-DD_HH:MM:SS_UTC'
#' @noRd
.format_datetime <- function(datetime) {
  paste0(gsub(" ", "_", format(datetime, "%Y-%m-%d_%H:%M:%S")), "_UTC")
}

#' Calcula la fecha/hora final segun la unidad de intervalo
#'
#' Devuelve el datetime resultante en formato 'YYYY-MM-DD_HH:MM:SS_UTC',
#' o NULL (con warning) si el calculo falla.
#'
#' @noRd
.calculate_untilok <- function(since, until, interval_unit) {
  tryCatch({
    # Parsear la fecha de inicio
    since_datetime <- .parse_datetime(since)

    # Calcular la nueva fecha segun el intervalo
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
    .format_datetime(untilok)
  }, error = function(e) {
    warning("Error al calcular la fecha: ", e$message)
    return(NULL)
  })
}

#' Cierra SOLO las sesiones chromote propias del paquete
#'
#' Reemplazo seguro de los pkill/taskkill globales de las funciones *For:
#' cierra las sesiones live pasadas como argumentos y, si existe, el objeto
#' chromote por defecto del proceso R (el navegador headless que abrio este
#' paquete), sin tocar otras instancias de Chrome del usuario. Todo dentro
#' de tryCatch silencioso.
#'
#' @param ... Objetos LiveHTML (o NULL) a cerrar antes del navegador.
#'
#' @return NULL, de forma invisible.
#' @noRd
.close_browser_scoped <- function(...) {
  .close_sessions(...)
  tryCatch({
    if (chromote::has_default_chromote_object()) {
      chromote::default_chromote_object()$close()
    }
  }, error = function(e) NULL)
  invisible(NULL)
}
