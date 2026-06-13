# Helper interno para la API de chat de OpenAI ----------------------------

#' POST a la API de chat completions de OpenAI
#'
#' Unifica la solicitud HTTP duplicada en getTweetsSentiments y
#' getTweetsImagesAnalysis: POST con Bearer header y encode = "json",
#' manejo legacy de status != 200 (warning + NULL) y parseo de la
#' respuesta. Devuelve el message content del primer choice, o NULL con
#' warning si la solicitud o el parseo fallan. El caller es responsable de
#' parsear ese content (p.ej. el JSON del modelo) y de los mensajes con
#' contexto propio (tweet/imagen).
#'
#' @param body Lista R con el cuerpo de la solicitud (model, messages, etc.).
#' @param api_key API key de OpenAI.
#' @param timeout Timeout de la solicitud HTTP en segundos.
#'
#' @return El message content (character) del primer choice, o NULL.
#' @noRd
.openai_chat <- function(body, api_key, timeout = 60) {
  response <- httr::POST(
    url = "https://api.openai.com/v1/chat/completions",
    httr::add_headers(Authorization = paste("Bearer", api_key)),
    body = body,
    encode = "json",
    httr::timeout(timeout)
  )

  if (httr::status_code(response) != 200) {
    warning("Error en la solicitud a la API de OpenAI")
    return(NULL)
  }

  result <- httr::content(response, "text", encoding = "UTF-8")
  tryCatch({
    json_data <- jsonlite::fromJSON(result, simplifyVector = FALSE)
    json_data$choices[[1]]$message$content
  }, error = function(e) {
    warning("Error al procesar la respuesta de la API: ", e$message)
    return(NULL)
  })
}
