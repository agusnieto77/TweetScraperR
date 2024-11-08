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
#' @param modelo Una cadena de caracteres que contiene el modelo de OpenAI. Por defecto es "gpt-4o-mini".
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
#'   \item{palabras_clave}{Una cadena de texto con 2 a 4 palabras clave separadas por punto y coma}
#'   \item{img}{La URL o nombre del archivo de la imagen analizada}
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
#'   \item Guarda los resultados como archivos RDS en el directorio especificado, con resultados parciales cada 7 imágenes si el total es mayor a 7.
#' }
#'
#' El análisis de la imagen incluye:
#' \itemize{
#'   \item Clasificación del tipo de imagen (por ejemplo, foto, meme, captura de pantalla)
#'   \item Detección de texto en la imagen (limitado a 10 palabras si es extenso)
#'   \item Identificación de contenido discriminatorio, violento, pornográfico o inapropiado
#'   \item Una descripción detallada del contenido de la imagen
#'   \item Generación de palabras clave descriptivas
#' }
#'
#' @note
#' Esta función requiere una conexión a internet activa y una clave de API de OpenAI válida para funcionar correctamente.
#' La función está diseñada para manejar errores y continuar procesando otras imágenes si una falla.
#' El tiempo de espera para las solicitudes HTTP está configurado en 300 segundos (5 minutos).
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
#' @importFrom httr POST add_headers content HEAD timeout
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
  timeout  <- 300
  img_sources <- unlist(img_sources)
  img_sources <- img_sources[!is.na(img_sources)]
  
  checkURL <- function(url) {
    tryCatch({
      response <- httr::HEAD(url, httr::timeout(timeout))
      status <- httr::status_code(response)
      return(status == 200)
    }, error = function(e) {
      warning(paste("Error al verificar la URL:", url, "-", e$message))
      return(FALSE)
    })
  }
  
  processImage <- function(file_path) {
    tryCatch({
      if (file.exists(file_path)) {
        raw_data <- readBin(file_path, "raw", file.info(file_path)$size)
        base64_data <- jsonlite::base64_enc(raw_data)
        return(list(
          data = paste0("data:image/jpeg;base64,", base64_data),
          img = basename(file_path)
        ))
      } else if (checkURL(file_path)) {
        return(list(
          data = file_path,
          img = file_path
        ))
      } else {
        message(paste("URL no válida o archivo no encontrado:", file_path))
        return(NA)
      }
    }, error = function(e) {
      message(paste("Error al procesar el archivo o URL:", file_path, "-", e$message))
      return(NA)
    })
  }
  
  img_sources <- lapply(img_sources, processImage)
  img_sources <- img_sources[!is.na(img_sources)]
  
  describe_system_prompt <- "
  Eres un sistema que genera descripciones detalladas de imágenes y su contenido, considerando varios aspectos relevantes.

  Recibirás una imagen junto con el tuit en el que fue compartida. Debes analizar y proporcionar una clasificación exhaustiva de la imagen, evaluando su contexto y contenido según los siguientes criterios.

  # Detalles a Evaluar

  1. **Clasificación de la imagen**: Selecciona una categoría adecuada para la imagen. Las posibles clasificaciones incluyen una de las siguientes: 
      - **Foto**: Imágenes realistas capturadas con una cámara o dispositivo como un smartphone, que representan escenas del mundo real, tales como paisajes, retratos, escenas urbanas, vehículos, objetos diversos, entre otros.
      - **Meme**: Imagen con un mensaje humorístico o irónico, generalmente tiene texto superpuesto.
      - **Captura de pantalla**: Representación directa de la pantalla de un dispositivo, normalmente incluye una interfaz de usuario visible.
      - **Dibujo**: Ilustraciones hechas a mano, ya sean digitales o tradicionales, no necesariamente creadas como un gráfico de información.
      - **Gráfico**: Representación visual de datos, como diagramas, gráficos circulares, de barra, etc.
      - **Flyer**: Imagen que tiene un diseño publicitario, promocional, o informativo que se asemeja a un volante.
      - **Placa de texto**: Imagen que consiste principalmente de texto, frecuentemente usada para citas, advertencias, o declaraciones.
      - **Otro**: Categoría reservada para imágenes que no encajan ninguna de las definiciones anteriores.

  2. **Indicador de si contiene texto**: Determina si la imagen contiene texto.
     - Valores: `[TRUE / FALSE]`

  3. **Texto contenido**: Si la imagen incluye texto breve (pocas oraciones o frases), transcribe el texto que aparece. Si el texto es extenso o se repite (como en una onomatopeya), transcribe solo un fragmento de hasta 50 (cincuenta) palabras, seguido de puntos suspensivos (por ejemplo: \"JAJAJA...\"). NUNCA transcribas textos largos completos.

  4. **Contenido discriminatorio**: Evalúa si la imagen o el texto contenido contiene elementos discriminatorios, como símbolos, insultos, mensajes peyorativos o cualquier otro elemento que fomente desigualdad o estigmatización.
     - Valores: `[TRUE / FALSE]`

  5. **Contenido violento**: Determina si existe contenido visual o textual asociado con violencia explícita o implícita, incluyendo amenazas, representaciones de daño físico o cualquier acto de agresión visual o textual (mensaje violento, la imagen contiene texto que llama a ejercer la violencia, desea la muerte o desaparición de otro individuo, etc).
     - Valores: `[TRUE / FALSE]`

  6. **Contenido pornográfico**: Indica si la imagen contiene contenido sexual explícito o pornográfico, o cualquier elemento que pueda interpretarse como material de connotación sexual.
     - Valores: `[TRUE / FALSE]`

  7. **Contenido inapropiado**: Evalúa si la imagen contiene elementos que puedan considerarse ofensivos o perturbadores en un contexto general, fuera de las categorías explícitas de violencia, discriminación o contenido sexual. Esto incluye:

     - **Humor de mal gusto**: Chistes sobre temas sensibles como enfermedades, accidentes, muertes o tragedias recientes.

     - **Contenido perturbador**: Imágenes o referencias a sustancias ilícitas, parafernalia de drogas, automutilación o temas de salud mental tratados de manera insensible.

     - **Lenguaje vulgar o insultos**: Frases o palabras que, sin ser necesariamente discriminatorias, son groseras, vulgares o despectivas.

     - **Referencias a temas controvertidos**: Elementos que podrían herir sensibilidades, como símbolos religiosos tratados de forma irrespetuosa o el uso irónico de banderas y otros símbolos nacionales o culturales.

     - **Representaciones visuales perturbadoras**: Escenas que, sin ser violentas ni explícitas, pueden incomodar, como personajes en poses inusuales o distorsionadas que sugieren desesperanza, o rostros con expresiones exageradas de miedo o dolor.

     Identifica estos elementos cuando el contenido sea inadecuado para audiencias amplias o pueda resultar ofensivo en contextos culturales y sociales diversos.
     - Valores: `[TRUE / FALSE]`

  8. **Descripción detallada de la imagen**: Redacta una descripción detallada de lo que aparece en la imagen, incluyendo detalles visuales importantes, contexto, colores, personas, objetos, etc., asegurando claridad y exhaustividad.

  9. **Palabras clave descriptoras de la imagen**: Genera una cadena de texto con entre 2 y 4 palabras clave que describan el contenido de la imagen. Las palabras clave deben estar separadas por punto y coma (`;`) y nunca deben presentarse como un vector o lista. El resultado debe ser un único string en el siguiente formato: `\"palabra1; palabra2; palabra3\"`.

  # Formato de Salida

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
    \"descripcion_detallada\": \"[descripción detallada de la imagen]\",
    \"palabras_clave\": [\"palabra1\"; \"palabra2\"; \"palabra3\"]\"
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
                  url = img_source$data
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
                descripcion = list(type = "string"),
                palabras_clave = list(type = "string")
              ),
              required = c("clasificacion", "contiene_texto", "texto_contenido",
                           "contenido_discriminatorio", "contenido_violento", "contenido_pornografico",
                           "contenido_inapropiado", "descripcion", "palabras_clave"),
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
        encode = "json",
        httr::timeout(timeout)
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
        message(paste("Error al analizar JSON para la imagen:", img_source$img, "-", e$message))
        return(list(
          clasificacion = NA_character_,
          contiene_texto = NA,
          texto_contenido = NA_character_,
          contenido_discriminatorio = NA,
          contenido_violento = NA,
          contenido_pornografico = NA,
          contenido_inapropiado = NA,
          descripcion = NA_character_,
          palabras_clave = NA_character_
        ))
      })
      
      result_tibble <- tibble::as_tibble(result_json)
      
      result_tibble |>
        dplyr::mutate(img = img_source$img)
    }, error = function(e) {
      message(paste("Error al analizar la imagen:", img_source$img, "-", e$message))
      tibble::tibble(
        clasificacion = NA_character_,
        contiene_texto = NA,
        texto_contenido = NA_character_,
        contenido_discriminatorio = NA,
        contenido_violento = NA,
        contenido_pornografico = NA,
        contenido_inapropiado = NA,
        descripcion = NA_character_,
        palabras_clave = NA_character_,
        img = img_source$img
      )
    })
  }
  
  message("\nAnalizando las imágenes...")
  
  total_images <- length(img_sources)
  batch_size <- 50
  
  if (total_images > batch_size) {
    results <- list()
    for (i in seq(1, total_images, by = batch_size)) {
      end <- min(i + batch_size - 1, total_images)
      batch_results <- purrr::map_dfr(img_sources[i:end], analyzeImage, .progress = TRUE)
      results[[length(results) + 1]] <- batch_results
      
      # Guardar resultados parciales cada 50 imágenes
      saveRDS(do.call(rbind, results), paste0(dir, "/results_images_analyze_", format(Sys.time(), "%Y_%m_%d_%H_%M_%S"), ".rds"))
      
      message(paste("Procesadas", end, "de", total_images, "imágenes"))
    }
    results <- do.call(rbind, results)
  } else {
    results <- purrr::map_dfr(img_sources, analyzeImage, .progress = TRUE)
    saveRDS(results, paste0(dir, "/results_images_analyze_", format(Sys.time(), "%Y_%m_%d_%H_%M_%S"), ".rds"))
  }
  
  message("\nEl análisis de imágenes ha finalizado.\n")
  
  return(results)
}
