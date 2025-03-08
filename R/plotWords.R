#' Create Word Cloud from Tweets
#'
#' @description
#' 
#' <a href="https://lifecycle.r-lib.org/articles/stages.html#experimental" target="_blank"><img src="https://lifecycle.r-lib.org/articles/figures/lifecycle-experimental.svg" alt="[Experimental]"></a>
#' 
#' Esta función toma un dataframe de tweets y crea una nube de palabras
#' basada en el contenido de la columna 'texto' o 'tweet'.
#'
#' @param df Un dataframe que contiene una columna 'texto' o 'tweet' con el contenido de los tweets.
#' @param min_freq Frecuencia mínima de palabras para incluir en la nube (por defecto 3).
#' @param max_words Número máximo de palabras a incluir en la nube (por defecto 100).
#' @param random_order Booleano, si las palabras deben ordenarse aleatoriamente (por defecto FALSE).
#' @param colors Vector de colores para las palabras (por defecto 'random-dark').
#' @param size Tamaño de la fuente (por defecto 0.3).
#' @param lang idioma para las stopwords 'es', 'en', 'de', 'pt', etc. (por defecto 'es').
#' @param sw vector de palabras extras para sumar a la lista de stopwords (por defecto NULL).
#' 
#' @return Un objeto de tipo wordcloud2.
#' 
#' @importFrom wordcloud2 wordcloud2
#' @importFrom quanteda corpus tokens tokens_remove tokens_tolower dfm topfeatures stopwords
#' @importFrom dplyr filter slice_head
#' @importFrom utils install.packages
#' 
#' @export
#'
#' @examples
#' 
#' df <- data.frame(texto = c("Este es un tweet de ejemplo", "Otro tweet para la nube de palabras"))
#' plotWords(df, min_freq = 1)

plotWords <- function(
    df, 
    min_freq = 3, 
    max_words = 100, 
    random_order = FALSE, 
    colors = 'random-dark',
    size = 0.3,
    lang = "es",
    sw = NULL
    ) {
  
  # Lista de paquetes necesarios
  required_packages <- c("quanteda", "dplyr", "wordcloud2")
  
  # Función para instalar paquetes si no están instalados
  install_if_missing <- function(package) {
    if (!requireNamespace(package, quietly = TRUE)) {
      utils::install.packages(package, dependencies = TRUE)
    }
  }
  
  # Instalar paquetes necesarios
  sapply(required_packages, install_if_missing)
  
  # Verificar que el dataframe tiene una columna 'texto' o 'tweet'
  if ("texto" %in% colnames(df)) {
    text_column <- "texto"
  } else if ("tweet" %in% colnames(df)) {
    text_column <- "tweet"
  } else {
    stop("El dataframe debe contener una columna llamada 'texto' o 'tweet'")
  }
  
  # Comprobación para sw
  if (!is.null(sw)) {
    if (!is.character(sw)) {
      stop("'sw' debe ser una cadena de texto o un vector de cadenas de texto")
    }
    if (length(sw) == 1) {
      sw <- c(sw)  # Convertir una sola palabra en un vector
    }
  }
  
  # Crear un corpus con los tweets
  corpus <- quanteda::corpus(df[[text_column]])
  
  # Preprocesamiento del texto
  stop_words <- c(quanteda::stopwords(lang), sw)
  tokens <- quanteda::tokens(corpus, 
                             remove_punct = TRUE, 
                             remove_numbers = TRUE, 
                             remove_symbols = TRUE) |>
    quanteda::tokens_remove(pattern = stop_words) |>
    quanteda::tokens_tolower()
  
  # Crear una matriz de frecuencia de términos
  dfm <- quanteda::dfm(tokens)
  
  # Convertir la matriz a un dataframe
  word_freq <- quanteda::topfeatures(dfm, n = Inf)
  df_word_freq <- data.frame(word = names(word_freq), freq = unname(word_freq))
  
  # Filtrar palabras por frecuencia mínima y número máximo de palabras
  df_word_freq <- df_word_freq |>
    dplyr::filter(freq >= min_freq) |>
    dplyr::slice_head(n = max_words)
  
  # Crear la nube de palabras
  wc <- wordcloud2::wordcloud2(data = df_word_freq, 
                               size = size, 
                               minSize = 0, 
                               gridSize = 0,
                               fontFamily = 'Montserrat',
                               fontWeight = 'bold',
                               color = colors,
                               backgroundColor = "white",
                               minRotation = -pi/4,
                               maxRotation = pi/4,
                               shuffle = random_order,
                               rotateRatio = 0.4,
                               shape = 'circle',
                               ellipticity = 0.65,
                               widgetsize = c(750, 750))
  
  return(wc)
}
