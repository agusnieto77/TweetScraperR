#' Analyze images of tweets
#'
#' @description
#' 
#' <a href="https://lifecycle.r-lib.org/articles/stages.html#experimental" target="_blank"><img src="https://lifecycle.r-lib.org/articles/figures/lifecycle-experimental.svg" alt="[Experimental]"></a>
#' 
#' Esta función analiza imágenes asociadas con tweets. Procesa un vector de URLs de imágenes o rutas de archivos locales,
#' envía estas imágenes a la API de OpenAI para su análisis y devuelve un informe detallado sobre
#' el contenido de cada imagen.
#'
#' @param img_sources Un vector de caracteres que contiene las URLs de las imágenes o rutas de archivos locales a analizar.
#' @param modelo Una cadena de caracteres que contiene el modelo de OpenAI. Por defecto es "gpt-4-vision-preview".
#' @param api_key Una cadena de caracteres que contiene la clave de API de OpenAI.
#'   Por defecto es `Sys.getenv("OPENAI_API_KEY")`.
#' @param dir Una cadena de caracteres que especifica el directorio donde se
#'   guardarán los resultados. Por defecto es `getwd()`.
#'
#' @return Un tibble con las siguientes columnas:
#'   \item{clasificacion}{La clasificación de la imagen}
#'   \item{contiene_texto}{Un booleano que indica si la imagen contiene texto}
#'   \item{texto_contenido}{El contenido de texto de la imagen (si lo hay, limitado a 10 palabras)}
#'   \item{contenido_discriminatorio}{Un booleano que indica la presencia de contenido discriminatorio}
#'   \item{contenido_violento}{Un booleano que indica la presencia de contenido violento}
#'   \item{contenido_pornografico}{Un booleano que indica la presencia de contenido pornográfico}
#'   \item{contenido_inapropiado}{Un booleano que indica la presencia de contenido inapropiado}
#'   \item{descripcion}{Una descripción detallada de la imagen}
#'   \item{url}{La URL o ruta del archivo de la imagen analizada}
#'
#' @details
#' La función realiza los siguientes pasos:
#' \enumerate{
#'   \item Verifica la presencia de una clave de API válida.
#'   \item Procesa el vector de URLs de imágenes o rutas de archivos locales, eliminando valores NA.
#'   \item Convierte los archivos locales a formato base64 si es necesario.
#'   \item Define un prompt de sistema detallado para la API de OpenAI, instruyéndola sobre cómo analizar las imágenes.
#'   \item Para cada imagen:
#'     \itemize{
#'       \item Envía una solicitud a la API de OpenAI con la URL de la imagen o los datos base64.
#'       \item Procesa la respuesta de la API para extraer los resultados del análisis.
#'     }
#'   \item Combina todos los resultados en un solo tibble.
#'   \item Guarda los resultados como un archivo RDS en el directorio especificado.
#' }
#'
#' El análisis de la imagen incluye:
#' \itemize{
#'   \item Clasificación del tipo de imagen (por ejemplo, foto, meme, captura de pantalla)
#'   \item Detección de texto en la imagen (limitado a 10 palabras si es extenso)
#'   \item Identificación de contenido discriminatorio, violento, pornográfico o inapropiado
#'   \item Una descripción detallada del contenido de la imagen
#' }
#'
#' @note
#' Esta función requiere una conexión a internet activa y una clave de API de OpenAI válida para funcionar correctamente.
#' La función está diseñada para manejar errores y continuar procesando otras imágenes si una falla.
#'
#' @examples
#' \dontrun{
#' # Ejemplo de uso con un vector de URLs de imágenes
#' urls <- c("https://ejemplo.com/imagen1.jpg", "https://ejemplo.com/imagen2.jpg")
#' resultados <- getTweetsImagesAnalysis(urls)
#'
#' # Ejemplo de uso con rutas de archivos locales
#' archivos_locales <- c("./imagen1.jpg", "./imagen2.png")
#' resultados_locales <- getTweetsImagesAnalysis(archivos_locales)
#' }
#'
#' @importFrom httr POST add_headers content
#' @importFrom jsonlite fromJSON toJSON base64_enc
#' @importFrom purrr map_dfr
#' @importFrom dplyr mutate
#' @importFrom tibble as_tibble
#'
#' @export
#' 

getTweetsImagesAnalysis <- function(img_sources, modelo = "gpt-4o-mini", api_key = Sys.getenv("OPENAI_API_KEY"), dir = getwd()) {
  if (api_key == "") {
    stop("Se requiere una clave de API de OpenAI. Por favor, proporciónela como argumento o configure la variable de entorno OPENAI_API_KEY.")
  }
  
  img_sources <- unlist(img_sources)
  img_sources <- img_sources[!is.na(img_sources)]
  
  fileToBase64 <- function(file_path) {
    tryCatch({
      if (file.exists(file_path)) {
        raw_data <- readBin(file_path, "raw", file.info(file_path)$size)
        base64_data <- jsonlite::base64_enc(raw_data)
        return(paste0("data:image/jpeg;base64,", base64_data))
      } else {
        return(file_path)
      }
    }, error = function(e) {
      warning(paste("Error al procesar el archivo:", file_path, "-", e$message))
      return(NA)
    })
  }
  
  img_sources <- sapply(img_sources, fileToBase64)
  img_sources <- img_sources[!is.na(img_sources)]
  
  describe_system_prompt <- "
  Eres un sistema que genera descripciones detalladas de imágenes y su contenido, considerando diferentes aspectos relevantes.

  Recibirás la imagen junto con el tuit original donde fue insertada. Debes analizar y proporcionar una clasificación exhaustiva de la imagen, evaluando su contexto y contenido de acuerdo con los siguientes campos.

  # Detalles a evaluar

  1. **Clasificación de la imagen**: Selecciona una categoría adecuada para la imagen. Las posibles clasificaciones incluyen uno de los siguientes: 
     - Foto
     - Meme
     - Captura de pantalla
     - Dibujo
     - Gráfico
     - Flyer
     - Placa de texto
     - Otro

  2. **Indicador de si contiene texto**: Determina si la imagen contiene texto o no.
     - Campos disponibles: `[TRUE / FALSE]`

  3. **Texto contenido**: Si la imagen incluye texto breve (pocas oraciones o frases), escribe el texto que aparece. Si el texto es muy extenso o es una onomatopeya repetida, solo transcribir un fragmento de no más de 10 palabras seguido de tres puntos (ejemplo: JAJAJAJA...) NUNCA transcribir un texto largo.

  4. **Contenido discriminatorio**: Evalúa si la imagen contiene contenido discriminatorio, como símbolos, insultos, mensajes peyorativos o cualquier elemento que fomente desigualdad o estigmatización.
     - Campos disponibles: `[TRUE / FALSE]`

  5. **Contenido violento**: Determina si existe contenido asociado con violencia explícita o implícita, incluyendo amenazas, representaciones de daño físico, o cualquier acto de agresión visual o textual.
     - Campos disponibles: `[TRUE / FALSE]`

  6. **Contenido pornográfico**: Indica si la imagen contiene contenido sexual explícito o pornográfico, o cualquier elemento que pueda interpretarse como material de connotación sexual.
     - Campos disponibles: `[TRUE / FALSE]`

  7. **Contenido inapropiado**: Evalúa si la imagen contiene elementos visuales o textuales que puedan considerarse ofensivos o perturbadores en un contexto general, fuera de las categorías explícitas de violencia, discriminación o contenido sexual. Esto incluye:

     - **Humor de mal gusto**: Chistes sobre temas sensibles como enfermedades, accidentes, muertes, o tragedias recientes.

     - **Contenido perturbador**: Imágenes o referencias a sustancias ilícitas o parafernalia de drogas, automutilación, o temas de salud mental tratados de forma insensible.

     - **Lenguaje vulgar o insultos**: Frases o palabras que, sin ser necesariamente discriminatorias, son groseras, vulgares, o despectivas.

     - **Referencias a temas controvertidos**: Elementos que podrían herir sensibilidades, como símbolos religiosos tratados de manera irrespetuosa o el uso irónico de banderas y otros símbolos nacionales o culturales.

     - **Representaciones visuales perturbadoras**: Escenas que, sin ser violentas ni explícitas, pueden incomodar, como personajes en poses inusuales o distorsionadas, en un contexto que sugiere desesperanza, o rostros con expresiones exageradas de miedo o dolor.

     Estos elementos se deben identificar cuando el contenido es inadecuado para audiencias amplias o puede resultar ofensivo en contextos culturales y sociales diversos.
     - Campos disponibles: `[TRUE / FALSE]`

  8. **Descripción detallada de la imagen**: Redacta una descripción detallada de lo que aparece en la imagen. Incluye detalles visuales importantes, contexto, colores, personas, objetos, etc., asegurando claridad y exhaustividad.

  # Output Format

  El resultado debe ser un JSON con los siguientes campos:

  ```json
  {
    \"clasificacion\": \"[clasificación de imagen]\",
    \"contiene_texto\": [true/false],
    \"texto_contenido\": \"[contenido del texto si aplica]\",
    \"contenido_discriminatorio\": [true/false],
    \"contenido_violento\": [true/false],
    \"contenido_pornografico\": [true/false],
    \"contenido_inapropiado\": [true/false],
    \"descripcion_detallada\": \"[descripción detallada de la imagen]\"
  }
  ```
  # Notas
  - Analiza la imagen con atención para evaluar cada criterio de manera correcta.
  - Sé lo más explícito posible en la descripción.
  - Si la imagen contiene texto extenso, solo transcribir hasta diez palabras, nunca más de 10 palabras.
  "
  
  analyzeImage <- function(img_source) {
    tryCatch({
      body <- list(
        model = modelo,
        messages = list(
          list(
            role = "system",
            content = describe_system_prompt
          ),
          list(
            role = "user",
            content = list(
              list(
                type = "image_url",
                image_url = list(
                  url = img_source
                )
              )
            )
          )
        ),
        response_format = list(
          type = "json_schema",
          json_schema = list(
            name = "tweet_images_analysis",
            strict = TRUE,
            schema = list(
              type = "object",
              properties = list(
                clasificacion = list(type = "string"),
                contiene_texto = list(type = "boolean"),
                texto_contenido = list(type = "string"),
                contenido_discriminatorio = list(type = "boolean"),
                contenido_violento = list(type = "boolean"),
                contenido_pornografico = list(type = "boolean"),
                contenido_inapropiado = list(type = "boolean"),
                descripcion = list(type = "string")
              ),
              required = c("clasificacion", "contiene_texto", "texto_contenido",
                           "contenido_discriminatorio", "contenido_violento", "contenido_pornografico",
                           "contenido_inapropiado", "descripcion"),
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
      response <- httr::POST(
        url = "https://api.openai.com/v1/chat/completions",
        httr::add_headers(
          Authorization = paste("Bearer", api_key),
          "Content-Type" = "application/json"
        ),
        body = jsonlite::toJSON(body, auto_unbox = TRUE),
        encode = "json"
      )
      
      if (httr::status_code(response) != 200) {
        error_content <- httr::content(response, "parsed")
        stop("Error en la solicitud a la API: ",
             httr::status_code(response), " - ",
             if (!is.null(error_content$error$message)) error_content$error$message else "Error desconocido")
      }
      
      content <- httr::content(response, "text", encoding = "UTF-8")
      parsed_content <- jsonlite::fromJSON(content, simplifyVector = FALSE)
      
      result_json <- tryCatch({
        jsonlite::fromJSON(parsed_content$choices[[1]]$message$content, simplifyVector = TRUE)
      }, error = function(e) {
        warning(paste("Error al analizar JSON para la imagen:", img_source, "-", e$message))
        return(list(
          clasificacion = NA_character_,
          contiene_texto = NA,
          texto_contenido = NA_character_,
          contenido_discriminatorio = NA,
          contenido_violento = NA,
          contenido_pornografico = NA,
          contenido_inapropiado = NA,
          descripcion = NA_character_
        ))
      })
      
      result_tibble <- tibble::as_tibble(result_json)
      
      result_tibble |>
        dplyr::mutate(url = img_source)
    }, error = function(e) {
      warning(paste("Error al analizar la imagen:", img_source, "-", e$message))
      tibble::tibble(
        clasificacion = NA_character_,
        contiene_texto = NA,
        texto_contenido = NA_character_,
        contenido_discriminatorio = NA,
        contenido_violento = NA,
        contenido_pornografico = NA,
        contenido_inapropiado = NA,
        descripcion = NA_character_,
        url = img_source
      )
    })
  }
  
  message("\nAnalizando las imágenes...\n")
  
  results <- purrr::map_dfr(img_sources, analyzeImage, .progress = TRUE)
  
  saveRDS(results, paste0(dir, "/results_images_analyze_", format(Sys.time(), "%Y_%m_%d_%H_%M_%S"), ".rds"))
  
  return(results)
}
