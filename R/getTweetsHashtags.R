#' Get Hashtags from Tweets
#'
#' @description
#' 
#' <a href="https://lifecycle.r-lib.org/articles/stages.html#experimental" target="_blank"><img src="https://lifecycle.r-lib.org/articles/figures/lifecycle-experimental.svg" alt="[Experimental]"></a>
#' 
#' Esta función toma un dataframe de tweets y extrae todos los hashtags
#' del campo 'texto' o 'tweet', añadiéndolos como una nueva columna al dataframe.
#'
#' @param df Un dataframe que contiene una columna 'texto' o 'tweet' con el contenido de los tweets.
#' @return Un dataframe con una nueva columna 'hashtags' que contiene una lista de hashtags para cada tweet.
#' 
#' @export
#'
#' @examples
#' df1 <- data.frame(texto = c("Este es un #tweet con #hashtags", "Este no tiene hashtags", "Otro #ejemplo"))
#' getTweetsHashtags(df1)
#' 
#' df2 <- data.frame(tweet = c("Este es un #tweet con #hashtags", "Este no tiene hashtags", "Otro #ejemplo"))
#' getTweetsHashtags(df2)
#' 
#' @importFrom stringr str_extract_all
#' 

getTweetsHashtags <- function(df) {
  # Verificar que el dataframe tiene una columna 'texto' o 'tweet'
  if (!any(c("texto", "tweet") %in% colnames(df))) {
    stop("El dataframe debe contener una columna llamada 'texto' o 'tweet'")
  }
  
  # Determinar qué columna usar
  text_col <- ifelse("texto" %in% colnames(df), "texto", "tweet")
  
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
  df$hashtags <- lapply(df[[text_col]], extract_single)
  
  return(df)
}
