# Helper interno de scroll-y-recoleccion ----------------------------------

#' Loop generico de scroll y recoleccion de elementos
#'
#' Unifica el loop legacy duplicado en los scrapers: extrae elementos con
#' extract_fn(session) (vector character: HTML de articles o hrefs), deduplica
#' acumulando con unique/append, scrollea, informa el conteo y duerme. El
#' contador de intentos usa el idioma scoping-safe
#' ok <- tryCatch({...; TRUE}, error = function(e) FALSE) - nunca se asignan
#' contadores dentro de un handler (eso era el bug de loops infinitos).
#'
#' Termina cuando length(collected) >= n_max o attempts >= max_attempts.
#' stall_threshold parametriza la divergencia legacy: una pasada con
#' nuevos <= stall_threshold incrementa attempts (0 para la familia de URLs,
#' 1 para la familia de tweets historicos/citas).
#'
#' @param session Sesion live (LiveHTML) ya posicionada en la pagina objetivo.
#' @param extract_fn Funcion de un argumento (la sesion) que devuelve un
#'   vector character con los elementos de la pasada actual.
#' @param n_max Numero maximo de elementos a recolectar.
#' @param max_attempts Pasadas consecutivas sin novedades antes de cortar.
#' @param scroll_px Pixeles a scrollear por pasada.
#' @param wait Segundos de espera entre pasadas.
#' @param stall_threshold Umbral de estancamiento (nuevos <= umbral suma intento).
#' @param count_label Etiqueta del mensaje de progreso.
#'
#' @return Vector character con los elementos unicos recolectados.
#' @noRd
.scroll_collect <- function(session, extract_fn, n_max, max_attempts = 3,
                            scroll_px = 4000, wait = 2.5, stall_threshold = 0,
                            count_label = "Tweets recolectados") {
  collected <- character(0)
  attempts <- 0
  while (length(collected) < n_max && attempts < max_attempts) {
    nuevos <- 0L
    ok <- tryCatch({
      extraidos <- tryCatch({
        extract_fn(session)
      }, error = function(e) {
        message("Error al procesar art\u00edculos: ", conditionMessage(e))
        character(0)
      })
      nuevos <- length(unique(extraidos[!extraidos %in% collected]))
      collected <- unique(append(collected, extraidos))
      collected <- collected[!is.na(collected)]
      session$scroll_by(top = scroll_px, left = 0)
      message(count_label, ": ", length(collected))
      Sys.sleep(wait)
      TRUE
    }, error = function(e) {
      message("Error al recolectar tweet: ", conditionMessage(e))
      FALSE
    })
    if (!ok || nuevos <= stall_threshold) {
      attempts <- attempts + 1
    } else {
      attempts <- 0
    }
  }
  collected
}
