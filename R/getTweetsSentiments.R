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
#' @param dir Una cadena de caracteres que especifica el directorio donde se guardarán
#'   los archivos RDS con los resultados. Por defecto es el directorio de trabajo actual.
#' @param save Lógico. Indica si se deben guardar los resultados (totales y parciales)
#'   en archivos RDS dentro de `dir`. Por defecto es TRUE.
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
#' 3. Define una función interna `analyzeTweet` que procesa cada tweet individualmente.
#' 4. Procesa los tweets en lotes de 250 para manejar grandes volúmenes de datos.
#' 5. Guarda resultados parciales cada 50 tweets procesados.
#' 6. Devuelve los resultados como un tibble.
#'
#' La función utiliza la API de OpenAI para realizar el análisis de sentimiento,
#' por lo que requiere una conexión a Internet y una clave de API válida.
#'
#' @note
#' Esta función transmite el contenido de los tweets analizados a la API de
#' OpenAI (un servicio de terceros). Tenga en cuenta esta transferencia de
#' datos al trabajar con contenido de terceros o datos personales.
#'
#' @examples
#' \dontrun{
#' tweets <- c(
#'   "¡Qué día tan maravilloso! \U0001f60a",
#'   "Odio este producto, nunca lo compren. \U0001f620"
#' )
#' resultados <- getTweetsSentiments(tweets)
#' print(resultados)
#' }
#'
#' @importFrom jsonlite fromJSON
#' @importFrom purrr map_dfr
#' @importFrom tibble tibble
#'
#' @export
#'

getTweetsSentiments <- function(tweets, api_key = Sys.getenv("OPENAI_API_KEY"),
                                model = "gpt-4o-mini", dir = getwd(), save = TRUE) {
  # Verificación de la clave de API
  if (api_key == "") {
    stop("Se requiere una clave de API de OpenAI. Por favor, proporci\u00f3nela como argumento o configure la variable de entorno OPENAI_API_KEY.")
  }
  
  # Definición del prompt para el análisis de tweets
  tweet_analysis_prompt <- "# PROMPT: Analiza el tweet proporcionado e identifica el tono principal, el sentimiento expresado por el autor, si contiene expresiones de odio, si est\u00e1 direccionado a alguien espec\u00edfico y si contiene un llamado a la acci\u00f3n.\n\n
  Clasifica el tono, sentimiento, presencia de odio, si est\u00e1 direccionado y si hay un llamado a la acci\u00f3n, proporcionando una breve explicaci\u00f3n de tus clasificaciones y se\u00f1alando elementos clave que influyeron en tu an\u00e1lisis.\n\n# Clasificaci\u00f3n\n\n
  - **Tono**: Elige una de las siguientes opciones:\n  - Alegr\u00eda\n  - Tristeza\n  - Ira\n  - Sorpresa\n  - Disgusto\n  - Miedo\n  - Humor\n  - Sarcasmo\n  - Entusiasmo\n  - Enojo\n  - Informativo\n  - Otros\n\n- **Sentimiento**: Clasifica el sentimiento en una de las siguientes categor\u00edas:\n
  - Positivo\n  - Negativo\n  - Neutral\n\n- **Expresiones de Odio**: Determina si el tweet tiene expresiones de odio con un valor booleano:\n  - `true` - contiene expresiones de odio\n  - `false` - no contiene expresiones de odio\n\n- **Direccionado**: Indica si el mensaje est\u00e1 dirigido a alguien o algo espec\u00edfico:\n
  - `true` - el mensaje est\u00e1 direccionado a una persona, grupo o entidad espec\u00edfica\n  - `false` - el mensaje no est\u00e1 direccionado a nadie en particular\n\n- **Llama a acci\u00f3n**: Indica si el mensaje contiene un llamado expl\u00edcito a tomar acciones directas:\n  - `true` - contiene un llamado a la acci\u00f3n\n
  - `false` - no contiene un llamado a la acci\u00f3n\n\n# Explicaci\u00f3n\n\nProporciona una explicaci\u00f3n breve de cada clasificaci\u00f3n realizada, se\u00f1alando elementos clave del tweet como palabras, frases, emoticones, o elementos del contexto que hayan influido en tu decisi\u00f3n.\n\n# Pasos\n\n
  1. **Analiza el Contenido del Tweet**: Eval\u00faa el sentimiento comunicativo y la intenci\u00f3n del autor seg\u00fan contexto, tono de palabras, uso de emoticones, y el lenguaje utilizado.\n2. **Identifica el Tono del Tweet**: Selecciona uno de los tonos predefinidos que mejor describe el prop\u00f3sito comunicativo del autor.\n
  3. **Determina el Sentimiento General**: Clasifica si el sentimiento predominante es positivo, negativo, o neutral.\n4. **Eval\u00faa Expresiones de Odio**: Define si el contenido incita o contiene expresiones de odio y si su prop\u00f3sito es ser ofensivo.\n
  5. **Identifica si est\u00e1 Direccionado**: Determina si el mensaje est\u00e1 dirigido a una persona, grupo o entidad espec\u00edfica, o si es un comentario general.\n6. **Eval\u00faa el Llamado a la Acci\u00f3n**: Analiza si el tweet contiene un llamado expl\u00edcito a tomar acciones directas.\n
  7. **Formula la Explicaci\u00f3n**: Describe brevemente los elementos clave que influyeron en cada clasificaci\u00f3n, tales como la selecci\u00f3n de palabras o el uso del lenguaje.\n\n# Output Format\n\nEl resultado debe presentarse en formato JSON de la siguiente manera:\n\n
  ```json\n{\n  \"tono\": \"[Tono elegido]\",\n  \"sentimiento\": \"[Sentimiento elegido]\",\n  \"expresiones_de_odio\": [true/false],\n  \"direccionado\": [true/false],\n  \"llama_a_accion\": [true/false],\n
  \"explicacion\": \"[Explicaci\u00f3n detallada, mencionando palabras clave, frases, emoticones y otros elementos clave que respaldan la clasificaci\u00f3n]\"\n}\  ```\n\n# Examples\n\n
  ### Ejemplo 1:\n- **Input (Tweet)**: \"¡Qué día tan increíble! Todo ha salido perfecto \U0001f603\"\n- **Output**:\n```json\n{\n  \"tono\": \"Alegría\",\n  \"sentimiento\": \"Positivo\",\n \"expresiones_de_odio\": false,\n  \"direccionado\": false,\n  \"llama_a_accion\": false,\n  \"explicacion\": \"Las expresiones 'increíble' y 'todo ha salido perfecto', junto con el emoticón \U0001f603, sugieren un tono alegre y satisfecho. El tweet no está dirigido a nadie en particular y no contiene un llamado a la acción. Es una expresión general de felicidad sin un objetivo específico.\"\n}\n```\n\n
  ### Ejemplo 2:\n- **Input (Tweet)**: \"@PoliticoX, tus políticas son un desastre. ¡Todos deberíamos salir a protestar contra este gobierno corrupto! \U0001f92c #FueraGobierno\"\n- **Output**:\n```json\n{\n  \"tono\": \"Enojo\",\n  \"sentimiento\": \"Negativo\",\n  \"expresiones_de_odio\": true,\n  \"direccionado\": true,\n  \"llama_a_accion\": true,\n  \"explicacion\": \"El tweet muestra un tono de enojo evidente por el uso del emoticón \U0001f92c y el lenguaje fuerte. El sentimiento es claramente negativo, criticando las políticas y acusando de corrupción. Contiene expresiones de odio al llamar 'desastre' a las políticas y 'corrupto' al gobierno. Está direccionado específicamente a @PoliticoX y al gobierno. Hay un llamado explícito a la acción al instar a 'salir a protestar'. El uso del hashtag #FueraGobierno refuerza tanto el direccionamiento como el llamado a la acción.\"\n}\n```\n\n
  ### Ejemplo 3:\n- **Input (Tweet)**: \"Pero caguenlos bien a palos a esos zurdos de mierda\"\n- **Output**:\n```json\n{\n  \"tono\": \"Ira\",\n  \"sentimiento\": \"Negativo\",\n  \"expresiones_de_odio\": true,\n  \"direccionado\": true,\n  \"llama_a_accion\": true,\n  \"explicacion\": \"El tweet muestra un tono de ira evidente por el uso de lenguaje agresivo y vulgar. El sentimiento es claramente negativo, incitando a la violencia. Contiene expresiones de odio al referirse despectivamente a un grupo político como 'zurdos de mierda'. Está direccionado específicamente a este grupo. Hay un llamado explícito a la acción violenta con la frase 'caguenlos bien a palos', lo que constituye una incitación directa a la agresión física.\"\n}\n```\n\n
  ### Ejemplo 4:\n- **Input (Tweet)**: \"Esta de moda q los kirchos se hagan las tetas?? jajaja revolucion WOKE, los osos, jajaja Máximo se las hizo, el cabeza blanca tambien!! qué otro kircho se hizo las tetas?\"\n- **Output**:\n```json\n{\n  \"tono\": \"Sarcasmo\",\n  \"sentimiento\": \"Negativo\",\n  \"expresiones_de_odio\": true,\n  \"direccionado\": true,\n  \"llama_a_accion\": false,\n  \"explicacion\": \"El tweet utiliza un tono sarcástico, evidenciado por el uso repetido de 'jajaja' y la pregunta retórica. El sentimiento es negativo, burlándose de un grupo político y sus seguidores. Contiene expresiones de odio al referirse despectivamente a los 'kirchos' (kirchneristas) y hacer comentarios burlescos sobre sus cuerpos. Está claramente direccionado a este grupo político, mencionando incluso a individuos específicos como 'Máximo' y 'el cabeza blanca'. No hay un llamado explícito a la acción, sino que se centra en la burla y el cuestionamiento.\"\n}\n```\n\n
  ### Ejemplo 5:\n- **Input (Tweet)**: \"Pero el puto de aguiar, en otro video se hacia el picante que no iban por la vereda y acá lo ves conteniendo a los simios. Este payaso esta usando de la mala.\"\n- **Output**:\n```json\n{\n  \"tono\": \"Enojo\",\n  \"sentimiento\": \"Negativo\",\n  \"expresiones_de_odio\": true,\n  \"direccionado\": true,\n  \"llama_a_accion\": false,\n  \"explicacion\": \"El tweet muestra un tono de enojo, utilizando lenguaje ofensivo y acusatorio. El sentimiento es claramente negativo, criticando las acciones de una persona específica. Contiene expresiones de odio al usar términos despectivos como 'puto' y 'simios'. Está direccionado específicamente a 'aguiar' y a un grupo al que se refiere como 'simios'. No hay un llamado explícito a la acción, pero sí una fuerte crítica y acusación de hipocresía ('se hacía el picante' vs 'conteniendo a los simios'). La frase final sugiere que la persona está actuando de mala fe.\"\n}\n```\n\n
  # Notes\n\n- Procura analizar los elementos clave del tweet en su totalidad, prestando atención a sarcasmo, juegos de palabras y emoticones.\n- Recuerda que algunas expresiones pueden tener significados implícitos y depender del contexto para clasificarse correctamente.\n- Al evaluar si el mensaje está direccionado, considera tanto menciones explícitas (@usuario) como referencias implícitas a personas, grupos o entidades específicas.\n- Para determinar si hay un llamado a la acción, busca verbos imperativos o sugerencias directas de acciones a tomar."
  
  # Función interna para analizar un solo tweet
  analyzeTweet <- function(tweet) {
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
      response_format = list(type = "json_object")
    )
    
    # Realización de la solicitud a la API de OpenAI mediante el helper interno
    # (timeout generoso y tryCatch para que un error de transporte degrade al
    # camino NULL existente en lugar de abortar el lote completo)
    content <- tryCatch(
      .openai_chat(body, api_key, timeout = 300),
      error = function(e) {
        warning("Error en la solicitud a la API de OpenAI: ", conditionMessage(e))
        NULL
      }
    )

    # Manejo de errores en la solicitud
    if (is.null(content)) {
      warning("Error en la solicitud a la API de OpenAI para el tweet: ", substr(tweet, 1, 50), "...")
      return(NULL)
    }

    # Procesamiento de la respuesta
    tryCatch({
      parsed_content <- jsonlite::fromJSON(content, simplifyVector = FALSE)

      # Creación del tibble con los resultados
      tibble::tibble(
        tweet = tweet,
        tono = parsed_content$tono,
        sentimiento = parsed_content$sentimiento,
        expresiones_de_odio = parsed_content$expresiones_de_odio,
        direccionado = parsed_content$direccionado,
        llama_a_accion = parsed_content$llama_a_accion,
        explicacion = parsed_content$explicacion
      )
    }, error = function(e) {
      warning("Error al procesar la respuesta de la API para el tweet: ", substr(tweet, 1, 50), "...")
      warning("Error: ", e$message)
      return(NULL)
    })
  }
  
  # Configuración para el procesamiento por lotes
  total_tweets <- length(tweets)
  batch_size <- 250
  
  message("\nAnalizando los tweets...")
  
  if (total_tweets > batch_size) {
    results <- list()
    for (i in seq(1, total_tweets, by = batch_size)) {
      end <- min(i + batch_size - 1, total_tweets)
      batch_results <- purrr::map_dfr(tweets[i:end], analyzeTweet, .progress = TRUE)
      results[[length(results) + 1]] <- batch_results
      
      # Guardar resultados parciales cada 50 tweets
      if (save) {
        partial <- batch_results
        saveRDS(partial, paste0(dir, "/partial_results_tweets_analyze_", format(Sys.time(), "%Y_%m_%d_%H_%M_%S"), ".rds"))
      }

      message(paste("Procesados", end, "de", total_tweets, "tweets"))
    }
    results <- do.call(rbind, results)
  } else {
    results <- purrr::map_dfr(tweets, analyzeTweet, .progress = TRUE)
    if (save) {
      saveRDS(results, paste0(dir, "/results_tweets_analyze_", format(Sys.time(), "%Y_%m_%d_%H_%M_%S"), ".rds"))
    }
  }
  
  message("\nEl an\u00e1lisis de tweets ha finalizado.\n")
  
  return(results)
}
