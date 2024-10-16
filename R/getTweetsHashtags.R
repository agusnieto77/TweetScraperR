#' Get Hashtags from Tweets
#'
#' Esta función toma un dataframe de tweets y extrae todos los hashtags
#' del campo 'texto', añadiéndolos como una nueva columna al dataframe.
#'
#' @param df Un dataframe que contiene una columna 'texto' con el contenido de los tweets.
#' @return Un dataframe con una nueva columna 'hashtags' que contiene una lista de hashtags para cada tweet.
#' 
#' @export
#'
#' @examples
#' df <- data.frame(texto = c("Este es un #tweet con #hashtags", "Este no tiene hashtags", "Otro #ejemplo"))
#' getTweetsHashtags(df)
#' 
#' @import stringr


getTweetsHashtags <- function(df) {
  # Verificar que el dataframe tiene una columna 'texto'
  if (!"texto" %in% colnames(df)) {
    stop("El dataframe debe contener una columna llamada 'texto'")
  }
  
  # Función para extraer hashtags de un solo texto
  extract_single <- function(text) {
    # Usar expresión regular para encontrar hashtags
    hashtags <- stringr::str_extract_all(text, "#\\w+")
    # Si no hay hashtags, devolver NA
    if (length(hashtags[[1]]) == 0) {
      return(NA)
    } else {
      return(hashtags)
    }
  }
  
  # Aplicar la función a cada fila del dataframe
  df$hashtags <- lapply(df$texto, extract_single)
  
  return(df)
}
