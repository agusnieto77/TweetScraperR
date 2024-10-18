#' Extracts Relevant Information from Locally Stored Tweets
#'
#' @description
#' Esta función procesa un conjunto de tweets almacenados localmente y extrae información relevante de cada uno.
#' Puede manejar tanto un dataframe como una lista que contenga el HTML de los tweets y sus URLs correspondientes.
#'
#' @param data Un dataframe o una lista que contiene dos elementos: 'art_html' (el contenido HTML de los tweets), 'url' (las URLs de los tweets) y 'fecha_captura' (la fecha y hora de captura de cada tweet).
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
#'   \item respuestas: El número de respuestas al tweet.
#'   \item reposteos: El número de reposteos del tweet.
#'   \item megustas: El número de "me gusta" del tweet.
#'   \item metricas: Información adicional sobre las métricas del tweet.
#'   \item urls: Una lista de URLs mencionadas en el tweet.
#'   \item hilo: Indica si el tweet es parte de un hilo.
#'   \item url: La URL original del tweet.
#'   \item fecha_captura: La fecha y hora en que se capturó la información del tweet (heredada de los datos de entrada).
#' }
#'
#' @details
#' La función utiliza expresiones XPath y selectores CSS para extraer información específica de cada tweet.
#' Procesa cada tweet individualmente y maneja posibles errores, permitiendo continuar con el procesamiento
#' incluso si algunos tweets fallan. La fecha de captura se hereda de los datos de entrada.
#'
#' @examples
#' \dontrun{
#' # Asumiendo que tienes un dataframe llamado 'tweets_data' con columnas 'art_html', 'url' y 'fecha_captura'
#' resultados <- extractTweetsData(tweets_data)
#' }
#'
#' @importFrom xml2 read_html
#' @importFrom rvest html_attr html_elements html_text
#' @importFrom lubridate as_datetime
#' @importFrom tibble tibble
#' @importFrom dplyr bind_rows
#' @importFrom purrr map2
#' @importFrom stringr str_extract_all
#'
#' @export
#' 

extractTweetsData <- function(data) {
  
  metrica_meg = '//*[contains(@aria-label, "Me gusta")]'
  metrica_res = '//*[contains(@aria-label, "Respuesta") or contains(@aria-label, "Respuestas")]'
  metrica_rep = '//*[contains(@aria-label, "Repostear")]'
  pattern = "https?://pbs\\.twimg\\.com/media/[^\\s\"']+(?:\\?[^\\s\"']+)?"
  
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
  
  # Función para procesar un solo artículo
  process_single_article <- function(art_html, url, fecha_captura) {
    tryCatch({
      # Comprobar si art_html es una lista y extraer el primer elemento si es así
      if (is.list(art_html)) {
        art_html <- art_html[[1]]
      }
      
      # Asegurarse de que art_html es una cadena de texto
      if (!is.character(art_html)) {
        stop("El contenido HTML debe ser una cadena de texto")
      }
      
      articulo <- xml2::read_html(art_html)
      
      # Extracción de URLs
      urls_tw <- rvest::html_attr(rvest::html_elements(articulo, css = "article a"), "href")
      urls_tw <- urls_tw[grep("/status/", urls_tw)]
      urls_tw <- urls_tw[!grepl("/status/.*/analytics|/status/.*/photo|/status/.*/hidden|/status/.*/quotes", urls_tw)]
      
      # Extracción de fechas
      fechas <- lubridate::as_datetime(rvest::html_attr(rvest::html_elements(articulo, css = "time"), "datetime"))
      max_fecha <- if(length(fechas) > 0) max(fechas) else NA
      
      # Extracción de métricas
      metr <- rvest::html_attr(rvest::html_element(articulo, xpath = metrica_meg), "aria-label")
      resp <- rvest::html_attr(rvest::html_element(articulo, xpath = metrica_res), "aria-label")
      resp_ok <- if(grepl("[0-9]", resp)) as.integer(gsub("^(\\d+).*", "\\1", resp)) else as.integer(gsub("^(\\d+).*", "\\1", metr))
      
      # Creación del tibble con los datos extraídos
      tibble::tibble(
        fecha = lubridate::as_datetime(max_fecha),
        username = sub("^https://x.com/(.*?)/.*$|^https://twitter.com/(.*?)/.*$", "\\1", url),
        texto = rvest::html_text(rvest::html_elements(articulo, css = 'div[data-testid="tweetText"]'))[1],
        tweet_citado = rvest::html_text(rvest::html_elements(articulo, css = 'div[data-testid="tweetText"]'))[2],
        user_citado = rvest::html_text(rvest::html_elements(articulo, css = 'div.css-175oi2r.r-1wbh5a2.r-dnmrzs > div > div > span'))[3],
        emoticones = list(rvest::html_attr(rvest::html_elements(articulo, css = 'div[data-testid="tweetText"] img'), "alt")),
        links_img_user = sub(".*?(https://.*?(?:png|jpg)).*", "\\1", grep("profile_images", gsub('src="([^"]+)"', '\\1', regmatches(as.character(articulo), gregexpr('src="(.*?\\.(?:png|jpg))"', as.character(articulo), perl=TRUE))[[1]]), value = TRUE)[1]),
        links_img_post = list(unique(gsub("&amp;", "&", stringr::str_extract_all(as.character(articulo), pattern)[[1]]))),
        respuestas = resp_ok,
        reposteos = as.integer(gsub("^(\\d+).*", "\\1", rvest::html_attr(rvest::html_element(articulo, xpath = metrica_rep), "aria-label"))),
        megustas = as.integer(gsub(".*?(\\d+) Me gusta.*", "\\1", rvest::html_attr(rvest::html_element(articulo, xpath = metrica_meg), "aria-label"))),
        metricas = metr,
        urls = list(urls_tw),
        hilo = resp_ok,
        url = url,
        fecha_captura = fecha_captura
      )
    }, error = function(e) {
      message("Error al procesar el tweet: ", url, "\n", conditionMessage(e))
      return(NULL)
    })
  }
  
  # Procesar todos los artículos
  results <- purrr::pmap(list(art_html_list, url_list, fecha_captura_list), process_single_article)
  
  # Combinar los resultados en un solo dataframe
  dplyr::bind_rows(results)
}
