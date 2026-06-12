#' Analyze images of tweets
#'
#' @description
#'
#' <a href="https://lifecycle.r-lib.org/articles/stages.html#experimental" target="_blank"><img src="https://lifecycle.r-lib.org/articles/figures/lifecycle-experimental.svg" alt="[Experimental]"></a>
#'
#' Esta funci\u00f3n analiza im\u00e1genes asociadas con tweets. Procesa un vector de URLs de im\u00e1genes o rutas de archivos locales,
#' env\u00eda estas im\u00e1genes a la API de OpenAI para su an\u00e1lisis y devuelve un informe detallado sobre
#' el contenido de cada imagen.
#'
#' @param img_sources Un vector de caracteres que contiene las URLs de las im\u00e1genes o rutas de archivos locales a analizar.
#' @param modelo Una cadena de caracteres que contiene el modelo de OpenAI. Por defecto es "gpt-4o-mini".
#' @param api_key Una cadena de caracteres que contiene la clave de API de OpenAI.
#'   Por defecto es `Sys.getenv("OPENAI_API_KEY")`.
#' @param dir Una cadena de caracteres que especifica el directorio donde se
#'   guardar\u00e1n los resultados. Por defecto es `getwd()`.
#'
#' @return Un tibble con las siguientes columnas:
#'   \item{clasificacion}{La clasificaci\u00f3n de la imagen}
#'   \item{contiene_texto}{Un booleano que indica si la imagen contiene texto}
#'   \item{texto_contenido}{El contenido de texto de la imagen (si lo hay, limitado a 10 palabras)}
#'   \item{contenido_discriminatorio}{Un booleano que indica la presencia de contenido discriminatorio}
#'   \item{contenido_violento}{Un booleano que indica la presencia de contenido violento}
#'   \item{contenido_pornografico}{Un booleano que indica la presencia de contenido pornogr\u00e1fico}
#'   \item{contenido_inapropiado}{Un booleano que indica la presencia de contenido inapropiado}
#'   \item{descripcion}{Una descripci\u00f3n detallada de la imagen}
#'   \item{palabras_clave}{Una cadena de texto con 2 a 4 palabras clave separadas por punto y coma}
#'   \item{img}{La URL o nombre del archivo de la imagen analizada}
#'
#' @details
#' La funci\u00f3n realiza los siguientes pasos:
#' \enumerate{
#'   \item Verifica la presencia de una clave de API v\u00e1lida.
#'   \item Procesa el vector de URLs de im\u00e1genes o rutas de archivos locales, eliminando valores NA.
#'   \item Convierte los archivos locales a formato base64 si es necesario.
#'   \item Define un prompt de sistema detallado para la API de OpenAI, instruy\u00e9ndola sobre c\u00f3mo analizar las im\u00e1genes.
#'   \item Para cada imagen:
#'     \itemize{
#'       \item Env\u00eda una solicitud a la API de OpenAI con la URL de la imagen o los datos base64.
#'       \item Procesa la respuesta de la API para extraer los resultados del an\u00e1lisis.
#'     }
#'   \item Combina todos los resultados en un solo tibble.
#'   \item Guarda los resultados como archivos RDS en el directorio especificado, con resultados parciales cada 7 im\u00e1genes si el total es mayor a 7.
#' }
#'
#' El an\u00e1lisis de la imagen incluye:
#' \itemize{
#'   \item Clasificaci\u00f3n del tipo de imagen (por ejemplo, foto, meme, captura de pantalla)
#'   \item Detecci\u00f3n de texto en la imagen (limitado a 10 palabras si es extenso)
#'   \item Identificaci\u00f3n de contenido discriminatorio, violento, pornogr\u00e1fico o inapropiado
#'   \item Una descripci\u00f3n detallada del contenido de la imagen
#'   \item Generaci\u00f3n de palabras clave descriptivas
#' }
#'
#' @note
#' Esta funci\u00f3n requiere una conexi\u00f3n a internet activa y una clave de API de OpenAI v\u00e1lida para funcionar correctamente.
#' La funci\u00f3n est\u00e1 dise\u00f1ada para manejar errores y continuar procesando otras im\u00e1genes si una falla.
#' El tiempo de espera para las solicitudes HTTP est\u00e1 configurado en 300 segundos (5 minutos).
#'
#' @examples
#' \dontrun{
#' # Ejemplo de uso con un vector de URLs de im\u00e1genes
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
    stop("Se requiere una clave de API de OpenAI. Por favor, proporci\u00f3nela como argumento o configure la variable de entorno OPENAI_API_KEY.")
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
        message(paste("URL no v\u00e1lida o archivo no encontrado:", file_path))
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
  Eres un sistema que genera descripciones detalladas de im\u00e1genes y su contenido, considerando varios aspectos relevantes.

  Recibir\u00e1s una imagen junto con el tuit en el que fue compartida. Debes analizar y proporcionar una clasificaci\u00f3n exhaustiva de la imagen, evaluando su contexto y contenido seg\u00fan los siguientes criterios.

  # Detalles a Evaluar

  1. **Clasificaci\u00f3n de la imagen**: Selecciona una categor\u00eda adecuada para la imagen. Las posibles clasificaciones incluyen una de las siguientes:
      - **Foto**: Im\u00e1genes realistas capturadas con una c\u00e1mara o dispositivo como un smartphone, que representan escenas del mundo real, tales como paisajes, retratos, escenas urbanas, veh\u00edculos, objetos diversos, entre otros.
      - **Meme**: Imagen con un mensaje humor\u00edstico o ir\u00f3nico, generalmente con texto superpuesto.
      - **Captura de pantalla**: Representaci\u00f3n directa de la pantalla de un dispositivo, normalmente incluye una interfaz de usuario visible.
      - **Dibujo**: Ilustraciones hechas a mano, ya sean digitales o tradicionales, sin necesariamente tener un prop\u00f3sito informativo.
      - **Pintura**: Imagen art\u00edstica de t\u00e9cnica pict\u00f3rica tradicional o digital, que representa escenas, personas, naturaleza muerta, abstracciones, etc.
      - **Vi\u00f1eta**: Ilustraci\u00f3n humor\u00edstica o cr\u00edtica que normalmente incluye un personaje o situaci\u00f3n breve y puede tener texto.
      - **Caricatura**: Dibujo estilizado o exagerado de personas o personajes, generalmente con un fin humor\u00edstico o sat\u00edrico.
      - **Comic o historieta**: Secuencia de vi\u00f1etas o ilustraciones que narran una historia breve, con texto en globos de di\u00e1logo o cuadros de narraci\u00f3n.
      - **Gr\u00e1fico**: Representaci\u00f3n visual de datos, como diagramas, gr\u00e1ficos circulares, de barras, etc.
      - **Infograf\u00eda**: Imagen que combina gr\u00e1ficos, ilustraciones y texto para presentar informaci\u00f3n de manera visual y simplificada.
      - **Flyer**: Imagen de dise\u00f1o publicitario, promocional o informativo, semejante a un volante.
      - **Poster o cartel**: Imagen dise\u00f1ada para exhibirse en espacios p\u00fablicos, usada para anuncios, promociones o campa\u00f1as culturales.
      - **Placa de texto**: Imagen que consiste principalmente de texto, frecuentemente usada para citas, advertencias o declaraciones.
      - **Arte digital**: Creaciones visuales generadas digitalmente, con un estilo \u00fanico o experimental, que no encajan en \"Dibujo\" o \"Pintura\".
      - **Mapa**: Representaci\u00f3n visual de una zona geogr\u00e1fica, que puede incluir datos geogr\u00e1ficos, pol\u00edticos o culturales.
      - **Collage**: Composici\u00f3n de varias im\u00e1genes o elementos visuales combinados en una sola imagen.
      - **Fotomontaje**: Imagen creada combinando varias fotograf\u00edas, a menudo con fines art\u00edsticos o surrealistas.
      - **Otro**: Categor\u00eda reservada para im\u00e1genes que no encajan en ninguna de las definiciones anteriores.

  2. **Indicador de si contiene texto**: Determina si la imagen contiene texto.
     - Valores: `[TRUE / FALSE]`

  3. **Texto contenido**: Si la imagen incluye texto breve (pocas oraciones o frases), transcribe el texto que aparece. Si el texto es extenso o se repite (como en una onomatopeya), transcribe solo un fragmento de hasta 50 (cincuenta) palabras, seguido de puntos suspensivos (por ejemplo: \"JAJAJA...\"). NUNCA transcribas textos largos completos.

  4. **Contenido discriminatorio**: Eval\u00faa si la imagen o el texto contenido contiene elementos discriminatorios, como s\u00edmbolos, insultos, mensajes peyorativos o cualquier otro elemento que fomente desigualdad o estigmatizaci\u00f3n.
     - Valores: `[TRUE / FALSE]`

  5. **Contenido violento**: Determina si existe contenido visual o textual asociado con violencia expl\u00edcita o impl\u00edcita, incluyendo amenazas, representaciones de da\u00f1o f\u00edsico o cualquier acto de agresi\u00f3n visual o textual (mensaje violento, la imagen contiene texto que llama a ejercer la violencia, desea la muerte o desaparici\u00f3n de otro individuo, etc).
     - Valores: `[TRUE / FALSE]`

  6. **Contenido pornogr\u00e1fico**: Indica si la imagen contiene contenido sexual expl\u00edcito o pornogr\u00e1fico, o cualquier elemento que pueda interpretarse como material de connotaci\u00f3n sexual.
     - Valores: `[TRUE / FALSE]`

  7. **Contenido inapropiado**: Eval\u00faa si la imagen contiene elementos que puedan considerarse ofensivos o perturbadores en un contexto general, fuera de las categor\u00edas expl\u00edcitas de violencia, discriminaci\u00f3n o contenido sexual. Esto incluye:

     - **Humor de mal gusto**: Chistes sobre temas sensibles como enfermedades, accidentes, muertes o tragedias recientes.

     - **Contenido perturbador**: Im\u00e1genes o referencias a sustancias il\u00edcitas, parafernalia de drogas, automutilaci\u00f3n o temas de salud mental tratados de manera insensible.

     - **Lenguaje vulgar o insultos**: Frases o palabras que, sin ser necesariamente discriminatorias, son groseras, vulgares o despectivas.

     - **Referencias a temas controvertidos**: Elementos que podr\u00edan herir sensibilidades, como s\u00edmbolos religiosos tratados de forma irrespetuosa o el uso ir\u00f3nico de banderas y otros s\u00edmbolos nacionales o culturales.

     - **Representaciones visuales perturbadoras**: Escenas que, sin ser violentas ni expl\u00edcitas, pueden incomodar, como personajes en poses inusuales o distorsionadas que sugieren desesperanza, o rostros con expresiones exageradas de miedo o dolor.

     Identifica estos elementos cuando el contenido sea inadecuado para audiencias amplias o pueda resultar ofensivo en contextos culturales y sociales diversos.
     - Valores: `[TRUE / FALSE]`

  8. **Descripci\u00f3n detallada de la imagen**: Redacta una descripci\u00f3n detallada de lo que aparece en la imagen, incluyendo detalles visuales importantes, contexto, colores, personas, objetos, etc., asegurando claridad y exhaustividad.

  9. **Palabras clave descriptoras de la imagen**: Genera una cadena de texto con entre 2 y 4 palabras clave que describan el contenido de la imagen. Las palabras clave deben estar separadas por punto y coma (`;`) y nunca deben presentarse como un vector o lista. El resultado debe ser un \u00fanico string en el siguiente formato: `\"palabra1; palabra2; palabra3\"`.

  # Formato de Salida

  El resultado debe ser un JSON con los siguientes campos:

  ```json
  {
    \"clasificacion\": \"[clasificaci\u00f3n de imagen]\",
    \"contiene_texto\": [true/false],
    \"texto_contenido\": \"[contenido del texto si aplica]\",
    \"contenido_discriminatorio\": [true/false],
    \"contenido_violento\": [true/false],
    \"contenido_pornografico\": [true/false],
    \"contenido_inapropiado\": [true/false],
    \"descripcion_detallada\": \"[descripci\u00f3n detallada de la imagen]\",
    \"palabras_clave\": [\"palabra1\"; \"palabra2\"; \"palabra3\"]\"
  }
  ```
  # Notas
  - Analiza la imagen con atenci\u00f3n para evaluar cada criterio de manera correcta.
  - S\u00e9 lo m\u00e1s expl\u00edcito posible en la descripci\u00f3n.
  - Si la imagen contiene texto extenso, solo transcribir hasta diez palabras, nunca m\u00e1s de 10 palabras.
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

  message("\nAnalizando las im\u00e1genes...")

  total_images <- length(img_sources)
  batch_size <- 50

  if (total_images > batch_size) {
    results <- list()
    for (i in seq(1, total_images, by = batch_size)) {
      end <- min(i + batch_size - 1, total_images)
      batch_results <- purrr::map_dfr(img_sources[i:end], analyzeImage, .progress = TRUE)
      results[[length(results) + 1]] <- batch_results

      # Guardar resultados parciales cada 50 im\u00e1genes
      partial <- batch_results
      saveRDS(partial, paste0(dir, "/partial_results_images_analyze_", format(Sys.time(), "%Y_%m_%d_%H_%M_%S"), ".rds"))

      message(paste("Procesadas", end, "de", total_images, "im\u00e1genes"))
    }
    results <- do.call(rbind, results)
  } else {
    results <- purrr::map_dfr(img_sources, analyzeImage, .progress = TRUE)
    saveRDS(results, paste0(dir, "/results_images_analyze_", format(Sys.time(), "%Y_%m_%d_%H_%M_%S"), ".rds"))
  }

  message("\nEl an\u00e1lisis de im\u00e1genes ha finalizado.\n")

  return(results)
}
