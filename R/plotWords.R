#' Create Word Cloud from Tweets
#'
#' Esta función toma un dataframe de tweets y crea una nube de palabras
#' basada en el contenido de la columna 'texto' o 'tweet'.
#'
#' @param df Un dataframe que contiene una columna 'texto' o 'tweet' con el contenido de los tweets.
#' @param min_freq Frecuencia mínima de palabras para incluir en la nube (por defecto 3).
#' @param max_words Número máximo de palabras a incluir en la nube (por defecto 100).
#' @param random_order Booleano, si las palabras deben ordenarse aleatoriamente (por defecto FALSE).
#' @param colors Vector de colores para las palabras (por defecto 'random-dark').
#' 
#' @return Un objeto de tipo wordcloud2.
#' 
#' @import wordcloud2
#' @import quanteda
#' @import dplyr
#' 
#' @export
#'
#' @examples
#' df <- data.frame(texto = c("Este es un tweet de ejemplo", "Otro tweet para la nube de palabras"))
#' plotWords(df)

plotWords <- function(
    df, 
    min_freq = 3, 
    max_words = 100, 
    random_order = FALSE, 
    colors = 'random-dark') {
  
  # Lista de paquetes necesarios
  required_packages <- c("quanteda", "dplyr", "wordcloud2")
  
  # Función para instalar paquetes si no están instalados
  install_if_missing <- function(package) {
    if (!requireNamespace(package, quietly = TRUE)) {
      install.packages(package, dependencies = TRUE)
    }
    library(package, character.only = TRUE)
  }
  
  # Instalar y cargar paquetes necesarios
  sapply(required_packages, install_if_missing)
  
  # Verificar que el dataframe tiene una columna 'texto' o 'tweet'
  if ("texto" %in% colnames(df)) {
    text_column <- "texto"
  } else if ("tweet" %in% colnames(df)) {
    text_column <- "tweet"
  } else {
    stop("El dataframe debe contener una columna llamada 'texto' o 'tweet'")
  }
  
  # Crear un corpus con los tweets
  corpus <- quanteda::corpus(df[[text_column]])
  
  # Preprocesamiento del texto
  tokens <- quanteda::tokens(corpus, 
                             remove_punct = TRUE, 
                             remove_numbers = TRUE, 
                             remove_symbols = TRUE) %>%
    quanteda::tokens_remove(pattern = quanteda::stopwords("es")) %>%
    quanteda::tokens_tolower()
  
  # Crear una matriz de frecuencia de términos
  dfm <- quanteda::dfm(tokens)
  
  # Convertir la matriz a un dataframe
  word_freq <- quanteda::topfeatures(dfm, n = Inf)
  df_word_freq <- data.frame(word = names(word_freq), freq = unname(word_freq))
  
  # Filtrar palabras por frecuencia mínima y número máximo de palabras
  df_word_freq <- df_word_freq %>%
    dplyr::filter(freq >= min_freq) %>%
    dplyr::slice_head(n = max_words)
  
  # Crear la nube de palabras
  wc <- wordcloud2::wordcloud2(data = df_word_freq, 
                               size = 1, 
                               minSize = 0, 
                               gridSize = 0,
                               fontFamily = 'Segoe UI',
                               fontWeight = 'bold',
                               color = colors,
                               backgroundColor = "white",
                               minRotation = -pi/4,
                               maxRotation = pi/4,
                               shuffle = random_order,
                               rotateRatio = 0.4,
                               shape = 'circle',
                               ellipticity = 0.65,
                               widgetsize = c(800, 500))
  
  return(wc)
}
