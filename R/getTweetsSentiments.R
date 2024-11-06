#' Analyze sentiments of tweets
#' 
#' @description
#' 
#' <a href="https://lifecycle.r-lib.org/articles/stages.html#experimental" target="_blank"><img src="https://lifecycle.r-lib.org/articles/figures/lifecycle-experimental.svg" alt="[Experimental]"></a>
#' 
#' Esta función toma un vector de tweets y utiliza la API de OpenAI para realizar
#' un análisis de sentimiento detallado de cada tweet. El análisis incluye el tono,
#' el sentimiento general, la presencia de expresiones de odio, si el tweet está
#' direccionado a alguien específico y si contiene un llamado a la acción.
#'
#' @param tweets Un vector de caracteres que contiene los tweets a analizar.
#' @param api_key Una cadena de caracteres con la clave de API de OpenAI. Por defecto,
#'   se intenta obtener de la variable de entorno OPENAI_API_KEY.
#' @param model Una cadena de caracteres que especifica el modelo de OpenAI a utilizar.
#'   Por defecto es "gpt-4o-mini".
#' @param dir Una cadena de caracteres que especifica el directorio donde se guardará
#'   el archivo RDS con los resultados. Por defecto es el directorio de trabajo actual.
#'
#' @return Un tibble con los resultados del análisis para cada tweet. Cada fila
#'   contiene el tweet original y los resultados del análisis (tono, sentimiento,
#'   presencia de expresiones de odio, si está direccionado, si contiene un llamado
#'   a la acción y una explicación detallada).
#'
#' @details
#' La función realiza las siguientes operaciones:
#' 1. Verifica que se haya proporcionado una clave de API válida.
#' 2. Define un prompt detallado para el análisis de los tweets.
#' 3. Define una función interna `analyze_tweet` que procesa cada tweet individualmente.
#' 4. Utiliza `purrr::map_dfr` para aplicar `analyze_tweet` a cada tweet en el vector de entrada.
#' 5. Guarda los resultados en un archivo RDS en el directorio especificado.
#' 6. Devuelve los resultados como un tibble.
#'
#' La función utiliza la API de OpenAI para realizar el análisis de sentimiento,
#' por lo que requiere una conexión a Internet y una clave de API válida.
#'
#' @examples
#' \dontrun{
#' tweets <- c("¡Qué día tan maravilloso! 😊", "Odio este producto, nunca lo compren. 😠")
#' resultados <- getTweetsSentiments(tweets)
#' print(resultados)
#' }
#'
#' @importFrom httr POST add_headers content
#' @importFrom jsonlite fromJSON
#' @importFrom purrr map_dfr
#' @importFrom dplyr mutate
#' @importFrom tibble as_tibble
#'
#' @export
#' 

getTweetsSentiments <- function(tweets, api_key = Sys.getenv("OPENAI_API_KEY"), 
                                model = "gpt-4o-mini", dir = getwd()) {
  # Verificación de la clave de API
  if (api_key == "") {
    stop("Se requiere una clave de API de OpenAI. Por favor, proporciónela como argumento o configure la variable de entorno OPENAI_API_KEY.")
  }
  
  # Definición del prompt para el análisis de tweets
  tweet_analysis_prompt <- "# PROMPT: Analiza el tweet proporcionado e identifica el tono principal, el sentimiento expresado por el autor, si contiene expresiones de odio, si está direccionado a alguien específico y si contiene un llamado a la acción.\n\n
  [... Contenido del prompt ...]"
  
  # Función interna para analizar un solo tweet
  analyze_tweet <- function(tweet) {
    # Preparación del cuerpo de la solicitud a la API
    body <- list(
      model = model,
      messages = list(
        list(
          role = "system",
          content = tweet_analysis_prompt
        ),
        list(
          role = "user",
          content = tweet
        )
      ),
      response_format = list(
        type = "json_schema",
        json_schema = list(
          name = "tweet_analysis",
          strict = TRUE,
          schema = list(
            type = "object",
            properties = list(
              tono = list(type = "string"),
              sentimiento = list(type = "string"),
              expresiones_de_odio = list(type = "boolean"),
              direccionado = list(type = "boolean"),
              llama_a_accion = list(type = "boolean"),
              explicacion = list(type = "string")
            ),
            required = c("tono", "sentimiento", "expresiones_de_odio", "direccionado", "llama_a_accion", "explicacion"),
            additionalProperties = FALSE
          )
        )
      ),
      temperature = 0,
      max_tokens = 2048,
      top_p = 0,
      frequency_penalty = 0,
      presence_penalty = 0
    )
    
    # Realización de la solicitud POST a la API de OpenAI
    response <- httr::POST(
      url = "https://api.openai.com/v1/chat/completions",
      httr::add_headers(Authorization = paste("Bearer", api_key)),
      body = body,
      encode = "json"
    )
    
    # Manejo de errores en la solicitud
    if (httr::status_code(response) != 200) {
      warning("Error en la solicitud a la API de OpenAI para el tweet: ", substr(tweet, 1, 50), "...")
      return(NULL)
    }
    
    # Procesamiento de la respuesta
    result <- httr::content(response, "text", encoding = "UTF-8")
    json_data <- jsonlite::fromJSON(result)
    json_data <- jsonlite::fromJSON(json_data$choices$message$content)
    
    # Creación del tibble con los resultados
    tibble::as_tibble(json_data) |>
      dplyr::mutate(tweet = tweet, .before = tono)
  }
  
  # Aplicación de la función de análisis a todos los tweets
  results <- purrr::map_dfr(tweets, analyze_tweet, .progress = TRUE)
  
  # Guardado de los resultados en un archivo RDS
  saveRDS(results, paste0(dir, "/results_analyze_tweet_", format(Sys.time(), "%Y_%m_%d_%H_%M_%S"), ".rds"))
  
  # Devolución de los resultados
  return(results)
}
