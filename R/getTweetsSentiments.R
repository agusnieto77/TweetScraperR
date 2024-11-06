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
  Clasifica el tono, sentimiento, presencia de odio, si está direccionado y si hay un llamado a la acción, proporcionando una breve explicación de tus clasificaciones y señalando elementos clave que influyeron en tu análisis.\n\n# Clasificación\n\n
  - **Tono**: Elige una de las siguientes opciones:\n  - Alegría\n  - Tristeza\n  - Ira\n  - Sorpresa\n  - Disgusto\n  - Miedo\n  - Humor\n  - Sarcasmo\n  - Entusiasmo\n  - Enojo\n  - Informativo\n  - Otros\n\n- **Sentimiento**: Clasifica el sentimiento en una de las siguientes categorías:\n
  - Positivo\n  - Negativo\n  - Neutral\n\n- **Expresiones de Odio**: Determina si el tweet tiene expresiones de odio con un valor booleano:\n  - `true` - contiene expresiones de odio\n  - `false` - no contiene expresiones de odio\n\n- **Direccionado**: Indica si el mensaje está dirigido a alguien o algo específico:\n
  - `true` - el mensaje está direccionado a una persona, grupo o entidad específica\n  - `false` - el mensaje no está direccionado a nadie en particular\n\n- **Llama a acción**: Indica si el mensaje contiene un llamado explícito a tomar acciones directas:\n  - `true` - contiene un llamado a la acción\n
  - `false` - no contiene un llamado a la acción\n\n# Explicación\n\nProporciona una explicación breve de cada clasificación realizada, señalando elementos clave del tweet como palabras, frases, emoticones, o elementos del contexto que hayan influido en tu decisión.\n\n# Pasos\n\n
  1. **Analiza el Contenido del Tweet**: Evalúa el sentimiento comunicativo y la intención del autor según contexto, tono de palabras, uso de emoticones, y el lenguaje utilizado.\n2. **Identifica el Tono del Tweet**: Selecciona uno de los tonos predefinidos que mejor describe el propósito comunicativo del autor.\n
  3. **Determina el Sentimiento General**: Clasifica si el sentimiento predominante es positivo, negativo, o neutral.\n4. **Evalúa Expresiones de Odio**: Define si el contenido incita o contiene expresiones de odio y si su propósito es ser ofensivo.\n
  5. **Identifica si está Direccionado**: Determina si el mensaje está dirigido a una persona, grupo o entidad específica, o si es un comentario general.\n6. **Evalúa el Llamado a la Acción**: Analiza si el tweet contiene un llamado explícito a tomar acciones directas.\n
  7. **Formula la Explicación**: Describe brevemente los elementos clave que influyeron en cada clasificación, tales como la selección de palabras o el uso del lenguaje.\n\n# Output Format\n\nEl resultado debe presentarse en formato JSON de la siguiente manera:\n\n
  ```json\n{\n  \"tono\": \"[Tono elegido]\",\n  \"sentimiento\": \"[Sentimiento elegido]\",\n  \"expresiones_de_odio\": [true/false],\n  \"direccionado\": [true/false],\n  \"llama_a_accion\": [true/false],\n
  \"explicacion\": \"[Explicación detallada, mencionando palabras clave, frases, emoticones y otros elementos clave que respaldan la clasificación]\"\n}\  ```\n\n# Examples\n\n
  ### Ejemplo 1:\n- **Input (Tweet)**: \"¡Qué día tan increíble! Todo ha salido perfecto 😃\"\n- **Output**:\n```json\n{\n  \"tono\": \"Alegría\",\n  \"sentimiento\": \"Positivo\",\n \"expresiones_de_odio\": false,\n  \"direccionado\": false,\n  \"llama_a_accion\": false,\n  \"explicacion\": \"Las expresiones 'increíble' y 'todo ha salido perfecto', junto con el emoticón 😃, sugieren un tono alegre y satisfecho. El tweet no está dirigido a nadie en particular y no contiene un llamado a la acción. Es una expresión general de felicidad sin un objetivo específico.\"\n}\n```\n\n
  ### Ejemplo 2:\n- **Input (Tweet)**: \"@PoliticoX, tus políticas son un desastre. ¡Todos deberíamos salir a protestar contra este gobierno corrupto! 🤬 #FueraGobierno\"\n- **Output**:\n```json\n{\n  \"tono\": \"Enojo\",\n  \"sentimiento\": \"Negativo\",\n  \"expresiones_de_odio\": true,\n  \"direccionado\": true,\n  \"llama_a_accion\": true,\n  \"explicacion\": \"El tweet muestra un tono de enojo evidente por el uso del emoticón 🤬 y el lenguaje fuerte. El sentimiento es claramente negativo, criticando las políticas y acusando de corrupción. Contiene expresiones de odio al llamar 'desastre' a las políticas y 'corrupto' al gobierno. Está direccionado específicamente a @PoliticoX y al gobierno. Hay un llamado explícito a la acción al instar a 'salir a protestar'. El uso del hashtag #FueraGobierno refuerza tanto el direccionamiento como el llamado a la acción.\"\n}\n```\n\n
  ### Ejemplo 3:\n- **Input (Tweet)**: \"Pero caguenlos bien a palos a esos zurdos de mierda\"\n- **Output**:\n```json\n{\n  \"tono\": \"Ira\",\n  \"sentimiento\": \"Negativo\",\n  \"expresiones_de_odio\": true,\n  \"direccionado\": true,\n  \"llama_a_accion\": true,\n  \"explicacion\": \"El tweet muestra un tono de ira evidente por el uso de lenguaje agresivo y vulgar. El sentimiento es claramente negativo, incitando a la violencia. Contiene expresiones de odio al referirse despectivamente a un grupo político como 'zurdos de mierda'. Está direccionado específicamente a este grupo. Hay un llamado explícito a la acción violenta con la frase 'caguenlos bien a palos', lo que constituye una incitación directa a la agresión física.\"\n}\n```\n\n
  ### Ejemplo 4:\n- **Input (Tweet)**: \"Esta de moda q los kirchos se hagan las tetas?? jajaja revolucion WOKE, los osos, jajaja Máximo se las hizo, el cabeza blanca tambien!! qué otro kircho se hizo las tetas?\"\n- **Output**:\n```json\n{\n  \"tono\": \"Sarcasmo\",\n  \"sentimiento\": \"Negativo\",\n  \"expresiones_de_odio\": true,\n  \"direccionado\": true,\n  \"llama_a_accion\": false,\n  \"explicacion\": \"El tweet utiliza un tono sarcástico, evidenciado por el uso repetido de 'jajaja' y la pregunta retórica. El sentimiento es negativo, burlándose de un grupo político y sus seguidores. Contiene expresiones de odio al referirse despectivamente a los 'kirchos' (kirchneristas) y hacer comentarios burlescos sobre sus cuerpos. Está claramente direccionado a este grupo político, mencionando incluso a individuos específicos como 'Máximo' y 'el cabeza blanca'. No hay un llamado explícito a la acción, sino que se centra en la burla y el cuestionamiento.\"\n}\n```\n\n
  ### Ejemplo 5:\n- **Input (Tweet)**: \"Pero el puto de aguiar, en otro video se hacia el picante que no iban por la vereda y acá lo ves conteniendo a los simios. Este payaso esta usando de la mala.\"\n- **Output**:\n```json\n{\n  \"tono\": \"Enojo\",\n  \"sentimiento\": \"Negativo\",\n  \"expresiones_de_odio\": true,\n  \"direccionado\": true,\n  \"llama_a_accion\": false,\n  \"explicacion\": \"El tweet muestra un tono de enojo, utilizando lenguaje ofensivo y acusatorio. El sentimiento es claramente negativo, criticando las acciones de una persona específica. Contiene expresiones de odio al usar términos despectivos como 'puto' y 'simios'. Está direccionado específicamente a 'aguiar' y a un grupo al que se refiere como 'simios'. No hay un llamado explícito a la acción, pero sí una fuerte crítica y acusación de hipocresía ('se hacía el picante' vs 'conteniendo a los simios'). La frase final sugiere que la persona está actuando de mala fe.\"\n}\n```\n\n
  # Notes\n\n- Procura analizar los elementos clave del tweet en su totalidad, prestando atención a sarcasmo, juegos de palabras y emoticones.\n- Recuerda que algunas expresiones pueden tener significados implícitos y depender del contexto para clasificarse correctamente.\n- Al evaluar si el mensaje está direccionado, considera tanto menciones explícitas (@usuario) como referencias implícitas a personas, grupos o entidades específicas.\n- Para determinar si hay un llamado a la acción, busca verbos imperativos o sugerencias directas de acciones a tomar."
  
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
