#' Extracts Relevant Information from Locally Stored Tweets
#'
#' @description
#' 
#' <a href="https://lifecycle.r-lib.org/articles/stages.html#experimental" target="_blank"><img src="https://lifecycle.r-lib.org/articles/figures/lifecycle-experimental.svg" alt="[Experimental]"></a>
#' 
#' Esta función procesa un conjunto de tweets almacenados localmente y extrae información relevante de cada uno.
#' Puede manejar tanto un dataframe como una lista que contenga el HTML de los tweets, sus URLs correspondientes y las fechas de captura.
#'
#' @param data Un dataframe o una lista que contiene tres elementos: 'art_html' (el contenido HTML de los tweets), 'url' (las URLs de los tweets) y 'fecha_captura' (la fecha y hora de captura de cada tweet).
#'
#' @return Un tibble con las siguientes columnas:
#' \itemize{
#'   \item fecha: La fecha y hora del tweet.
#'   \item username: El nombre de usuario del autor del tweet.
#'   \item texto: El texto principal del tweet.
#'   \item tweet_citado: El texto del tweet citado, si existe.
#'   \item user_citado: El nombre de usuario del autor del tweet citado, si existe.
#'   \item emoticones: Una lista de emoticones utilizados en el tweet.
#'   \item links_img_user: El enlace a la imagen de perfil del usuario.
#'   \item links_img_post: Una lista de enlaces a las imágenes incluidas en el tweet.
#'   \item links_youtube: Una lista de enlaces a videos de YouTube mencionados en el tweet.
#'   \item respuestas: El número de respuestas al tweet.
#'   \item reposteos: El número de reposteos del tweet.
#'   \item megustas: El número de "me gusta" del tweet.
#'   \item metricas: Información adicional sobre las métricas del tweet.
#'   \item urls: Una lista de URLs mencionadas en el tweet.
#'   \item hilo: Indica si el tweet es parte de un hilo (basado en el número de respuestas).
#'   \item url: La URL original del tweet.
#'   \item fecha_captura: La fecha y hora en que se capturó la información del tweet (heredada de los datos de entrada).
#' }
#'
#' @details
#' La función utiliza expresiones XPath y selectores CSS para extraer información específica de cada tweet.
#' Procesa cada tweet individualmente y maneja posibles errores, permitiendo continuar con el procesamiento
#' incluso si algunos tweets fallan. La función ahora puede manejar tanto URLs de Twitter como de X.com.
#' Se han añadido nuevas extracciones, como enlaces a videos de YouTube y se ha mejorado la extracción de emoticones.
#'
#' @examples
#' \dontrun{
#' # Usando un dataframe
#' tweets_data <- data.frame(
#'   art_html = c("<html>...</html>", "<html>...</html>"),
#'   url = c("https://twitter.com/user1/status/123", "https://x.com/user2/status/456"),
#'   fecha_captura = c("2023-01-01 12:00:00", "2023-01-02 13:00:00")
#' )
#' resultados <- extractTweetsData(tweets_data)
#'
#' # Usando una lista
#' tweets_list <- list(
#'   art_html = c("<html>...</html>", "<html>...</html>"),
#'   url = c("https://twitter.com/user1/status/123", "https://x.com/user2/status/456"),
#'   fecha_captura = c("2023-01-01 12:00:00", "2023-01-02 13:00:00")
#' )
#' resultados <- extractTweetsData(tweets_list)
#' }
#'
#' @importFrom rvest html_attr html_elements html_text
#' @importFrom lubridate as_datetime
#' @importFrom tibble tibble
#' @importFrom dplyr bind_rows
#' @importFrom purrr pmap
#' @importFrom stringr str_extract_all str_replace_all
#'
#' @export
#' 

extractTweetsData <- function(data) {

  # Verificar si la entrada es un dataframe o una lista
  if (is.data.frame(data)) {
    if (!all(c("art_html", "url", "fecha_captura") %in% colnames(data))) {
      stop("El dataframe debe contener las columnas 'art_html', 'url' y 'fecha_captura'")
    }
    art_html_list <- data$art_html
    url_list <- data$url
    fecha_captura_list <- data$fecha_captura
  } else if (is.list(data) && length(data) == 3 && all(c("art_html", "url", "fecha_captura") %in% names(data))) {
    art_html_list <- data$art_html
    url_list <- data$url
    fecha_captura_list <- data$fecha_captura
  } else {
    stop("La entrada debe ser un dataframe o una lista con elementos 'art_html', 'url' y 'fecha_captura'")
  }
  
  # Función para procesar un solo artículo (delegada al helper interno)
  process_single_article <- function(art_html, url, fecha_captura) {
    resultado <- .extract_article_fields(art_html, url)
    if (!is.null(resultado)) {
      resultado$fecha_captura <- fecha_captura
    }
    resultado
  }
  
  # Procesar todos los artículos
  results <- purrr::pmap(list(art_html_list, url_list, fecha_captura_list), process_single_article)
  
  # Combinar los resultados en un solo dataframe
  dplyr::bind_rows(results)
}
