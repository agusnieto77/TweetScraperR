# Helper interno de guardado en RDS ---------------------------------------

#' Guarda un objeto en un .rds con nombre timestampeado
#'
#' Unifica el bloque legacy de guardado: construye
#' file.path(dir, paste0(prefix, "_", timestamp, ".rds")) con formato de
#' fecha explicito %Y_%m_%d_%H_%M_%S (NO %X, que es locale-dependiente),
#' guarda con saveRDS si save = TRUE y emite los mensajes cat legacy
#' (variante mayoritaria "Datos ..." y variante femenina "URLs ...").
#'
#' @param object Objeto a guardar.
#' @param dir Directorio de destino.
#' @param prefix Prefijo del nombre de archivo (ya sanitizado por el caller).
#' @param save Logico. Si FALSE no guarda y emite el mensaje legacy de no guardado.
#' @param label Etiqueta del mensaje: "Datos" (por defecto) o "URLs".
#'
#' @return La ruta del archivo, de forma invisible (se haya guardado o no).
#' @noRd
.save_rds <- function(object, dir, prefix, save = TRUE, label = "Datos") {
  path <- file.path(dir, paste0(prefix, "_", format(Sys.time(), "%Y_%m_%d_%H_%M_%S"), ".rds"))
  if (identical(label, "URLs")) {
    msg_guardado <- "URLs procesadas y guardadas.\n"
    msg_no_guardado <- "URLs procesadas. No se han guardado en un archivo RDS.\n"
  } else {
    msg_guardado <- paste0(label, " procesados y guardados.\n")
    msg_no_guardado <- paste0(label, " procesados. No se han guardado en un archivo RDS.\n")
  }
  if (save) {
    saveRDS(object, path)
    cat(msg_guardado)
  } else {
    cat(msg_no_guardado)
  }
  invisible(path)
}
