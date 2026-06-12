#' Analyze sentiments of tweets
#' 
#' @description
#' 
#' <a href="https://lifecycle.r-lib.org/articles/stages.html#experimental" target="_blank"><img src="https://lifecycle.r-lib.org/articles/figures/lifecycle-experimental.svg" alt="[Experimental]"></a>
#' 
#' Esta funci\u00f3n toma un vector de tweets y utiliza la API de OpenAI para realizar
#' un an\u00e1lisis de sentimiento detallado de cada tweet. El an\u00e1lisis incluye el tono,
#' el sentimiento general, la presencia de expresiones de odio, si el tweet est\u00e1
#' direccionado a alguien espec\u00edfico y si contiene un llamado a la acci\u00f3n.
#'
#' @param tweets Un vector de caracteres que contiene los tweets a analizar.
#' @param api_key Una cadena de caracteres con la clave de API de OpenAI. Por defecto,
#'   se intenta obtener de la variable de entorno OPENAI_API_KEY.
#' @param model Una cadena de caracteres que especifica el modelo de OpenAI a utilizar.
#'   Por defecto es "gpt-4o-mini".
#' @param dir Una cadena de caracteres que especifica el directorio donde se guardar\u00e1n
#'   los archivos RDS con los resultados. Por defecto es el directorio de trabajo actual.
#'
#' @return Un tibble con los resultados del an\u00e1lisis para cada tweet. Cada fila
#'   contiene el tweet original y los resultados del an\u00e1lisis (tono, sentimiento,
#'   presencia de expresiones de odio, si est\u00e1 direccionado, si contiene un llamado
#'   a la acci\u00f3n y una explicaci\u00f3n detallada).
#'
#' @details
#' La funci\u00f3n realiza las siguientes operaciones:
#' 1. Verifica que se haya proporcionado una clave de API v\u00e1lida.
#' 2. Define un prompt detallado para el an\u00e1lisis de los tweets.
#' 3. Define una funci\u00f3n interna `analyzeTweet` que procesa cada tweet individualmente.
#' 4. Procesa los tweets en lotes de 250 para manejar grandes vol\u00famenes de datos.
#' 5. Guarda resultados parciales cada 50 tweets procesados.
#' 6. Devuelve los resultados como un tibble.
#'
#' La funci\u00f3n utiliza la API de OpenAI para realizar el an\u00e1lisis de sentimiento,
#' por lo que requiere una conexi\u00f3n a Internet y una clave de API v\u00e1lida.
#'
#' @examples
#' \dontrun{
#' tweets <- c("\u00a1Qu\u00e9 d\u00eda tan maravilloso! \U0001f60a", "Odio este producto, nunca lo compren. \U0001f620")
#' resultados <- getTweetsSentiments(tweets)
#' print(resultados)
#' }
#'
#' @importFrom httr POST add_headers content
#' @importFrom jsonlite fromJSON
#' @importFrom purrr map_dfr
#' @importFrom tibble tibble
#'
#' @export
#' 

getTweetsSentiments <- function(tweets, api_key = Sys.getenv("OPENAI_API_KEY"), 
                                model = "gpt-4o-mini", dir = getwd()) {
  # Verificaci\u00f3n de la clave de API
  if (api_key == "") {
    stop("Se requiere una clave de API de OpenAI. Por favor, proporci\u00f3nela como argumento o configure la variable de entorno OPENAI_API_KEY.")
  }
  
  # Definici\u00f3n del prompt para el an\u00e1lisis de tweets
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
  ### Ejemplo 1:\n- **Input (Tweet)**: \"\u00a1Qu\u00e9 d\u00eda tan incre\u00edble! Todo ha salido perfecto \U0001f603\"\n- **Output**:\n```json\n{\n  \"tono\": \"Alegr\u00eda\",\n  \"sentimiento\": \"Positivo\",\n \"expresiones_de_odio\": false,\n  \"direccionado\": false,\n  \"llama_a_accion\": false,\n  \"explicacion\": \"Las expresiones 'incre\u00edble' y 'todo ha salido perfecto', junto con el emotic\u00f3n \U0001f603, sugieren un tono alegre y satisfecho. El tweet no est\u00e1 dirigido a nadie en particular y no contiene un llamado a la acci\u00f3n. Es una expresi\u00f3n general de felicidad sin un objetivo espec\u00edfico.\"\n}\n```\n\n
  ### Ejemplo 2:\n- **Input (Tweet)**: \"@PoliticoX, tus pol\u00edticas son un desastre. \u00a1Todos deber\u00edamos salir a protestar contra este gobierno corrupto! \U0001f92c #FueraGobierno\"\n- **Output**:\n```json\n{\n  \"tono\": \"Enojo\",\n  \"sentimiento\": \"Negativo\",\n  \"expresiones_de_odio\": true,\n  \"direccionado\": true,\n  \"llama_a_accion\": true,\n  \"explicacion\": \"El tweet muestra un tono de enojo evidente por el uso del emotic\u00f3n \U0001f92c y el lenguaje fuerte. El sentimiento es claramente negativo, criticando las pol\u00edticas y acusando de corrupci\u00f3n. Contiene expresiones de odio al llamar 'desastre' a las pol\u00edticas y 'corrupto' al gobierno. Est\u00e1 direccionado espec\u00edficamente a @PoliticoX y al gobierno. Hay un llamado expl\u00edcito a la acci\u00f3n al instar a 'salir a protestar'. El uso del hashtag #FueraGobierno refuerza tanto el direccionamiento como el llamado a la acci\u00f3n.\"\n}\n```\n\n
  ### Ejemplo 3:\n- **Input (Tweet)**: \"Pero caguenlos bien a palos a esos zurdos de mierda\"\n- **Output**:\n```json\n{\n  \"tono\": \"Ira\",\n  \"sentimiento\": \"Negativo\",\n  \"expresiones_de_odio\": true,\n  \"direccionado\": true,\n  \"llama_a_accion\": true,\n  \"explicacion\": \"El tweet muestra un tono de ira evidente por el uso de lenguaje agresivo y vulgar. El sentimiento es claramente negativo, incitando a la violencia. Contiene expresiones de odio al referirse despectivamente a un grupo pol\u00edtico como 'zurdos de mierda'. Est\u00e1 direccionado espec\u00edficamente a este grupo. Hay un llamado expl\u00edcito a la acci\u00f3n violenta con la frase 'caguenlos bien a palos', lo que constituye una incitaci\u00f3n directa a la agresi\u00f3n f\u00edsica.\"\n}\n```\n\n
  ### Ejemplo 4:\n- **Input (Tweet)**: \"Esta de moda q los kirchos se hagan las tetas?? jajaja revolucion WOKE, los osos, jajaja M\u00e1ximo se las hizo, el cabeza blanca tambien!! qu\u00e9 otro kircho se hizo las tetas?\"\n- **Output**:\n```json\n{\n  \"tono\": \"Sarcasmo\",\n  \"sentimiento\": \"Negativo\",\n  \"expresiones_de_odio\": true,\n  \"direccionado\": true,\n  \"llama_a_accion\": false,\n  \"explicacion\": \"El tweet utiliza un tono sarc\u00e1stico, evidenciado por el uso repetido de 'jajaja' y la pregunta ret\u00f3rica. El sentimiento es negativo, burl\u00e1ndose de un grupo pol\u00edtico y sus seguidores. Contiene expresiones de odio al referirse despectivamente a los 'kirchos' (kirchneristas) y hacer comentarios burlescos sobre sus cuerpos. Est\u00e1 claramente direccionado a este grupo pol\u00edtico, mencionando incluso a individuos espec\u00edficos como 'M\u00e1ximo' y 'el cabeza blanca'. No hay un llamado expl\u00edcito a la acci\u00f3n, sino que se centra en la burla y el cuestionamiento.\"\n}\n```\n\n
  ### Ejemplo 5:\n- **Input (Tweet)**: \"Pero el puto de aguiar, en otro video se hacia el picante que no iban por la vereda y ac\u00e1 lo ves conteniendo a los simios. Este payaso esta usando de la mala.\"\n- **Output**:\n```json\n{\n  \"tono\": \"Enojo\",\n  \"sentimiento\": \"Negativo\",\n  \"expresiones_de_odio\": true,\n  \"direccionado\": true,\n  \"llama_a_accion\": false,\n  \"explicacion\": \"El tweet muestra un tono de enojo, utilizando lenguaje ofensivo y acusatorio. El sentimiento es claramente negativo, criticando las acciones de una persona espec\u00edfica. Contiene expresiones de odio al usar t\u00e9rminos despectivos como 'puto' y 'simios'. Est\u00e1 direccionado espec\u00edficamente a 'aguiar' y a un grupo al que se refiere como 'simios'. No hay un llamado expl\u00edcito a la acci\u00f3n, pero s\u00ed una fuerte cr\u00edtica y acusaci\u00f3n de hipocres\u00eda ('se hac\u00eda el picante' vs 'conteniendo a los simios'). La frase final sugiere que la persona est\u00e1 actuando de mala fe.\"\n}\n```\n\n
  # Notes\n\n- Procura analizar los elementos clave del tweet en su totalidad, prestando atenci\u00f3n a sarcasmo, juegos de palabras y emoticones.\n- Recuerda que algunas expresiones pueden tener significados impl\u00edcitos y depender del contexto para clasificarse correctamente.\n- Al evaluar si el mensaje est\u00e1 direccionado, considera tanto menciones expl\u00edcitas (@usuario) como referencias impl\u00edcitas a personas, grupos o entidades espec\u00edficas.\n- Para determinar si hay un llamado a la acci\u00f3n, busca verbos imperativos o sugerencias directas de acciones a tomar."
  
  # Funci\u00f3n interna para analizar un solo tweet
  analyzeTweet <- function(tweet) {
    # Preparaci\u00f3n del cuerpo de la solicitud a la API
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
    
    # Realizaci\u00f3n de la solicitud POST a la API de OpenAI
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
    tryCatch({
      json_data <- jsonlite::fromJSON(result, simplifyVector = FALSE)
      content <- json_data$choices[[1]]$message$content
      parsed_content <- jsonlite::fromJSON(content, simplifyVector = FALSE)
      
      # Creaci\u00f3n del tibble con los resultados
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
  
  # Configuraci\u00f3n para el procesamiento por lotes
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
      partial <- batch_results
      saveRDS(partial, paste0(dir, "/partial_results_tweets_analyze_", format(Sys.time(), "%Y_%m_%d_%H_%M_%S"), ".rds"))
      
      message(paste("Procesados", end, "de", total_tweets, "tweets"))
    }
    results <- do.call(rbind, results)
  } else {
    results <- purrr::map_dfr(tweets, analyzeTweet, .progress = TRUE)
    saveRDS(results, paste0(dir, "/results_tweets_analyze_", format(Sys.time(), "%Y_%m_%d_%H_%M_%S"), ".rds"))
  }
  
  message("\nEl an\u00e1lisis de tweets ha finalizado.\n")
  
  return(results)
}
