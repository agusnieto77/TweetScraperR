#' @keywords internal
utils::globalVariables(c(
  "date_grouped",
  "emoji",
  "emoji_url",
  "emoticones",
  "fecha",
  "freq",
  "timeline",
  "tweet_id",
  "twitter"
))

# Entorno interno del paquete para las sesiones de navegador (twitter/timeline)
# de las funciones de login deprecadas. Evita escribir en .GlobalEnv, que viola
# la politica de CRAN (los paquetes no deben modificar el workspace del usuario).
.tsr_env <- new.env(parent = emptyenv())
