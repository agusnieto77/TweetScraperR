#' Get Tweets Images
#'
#' Esta función toma una lista de URLs de imágenes extraídas de tweets, las descarga y
#' las guarda en un directorio específico. Si el directorio no existe, se creará.
#'
#' @param urls Lista o vector de URLs de imágenes que se desea descargar.
#' @param directorio (opcional) Nombre del directorio donde se guardarán las imágenes.
#' El valor predeterminado es "img_x". Si el directorio no existe, la función lo crea.
#'
#' @details La función primero asegura que el directorio donde se guardarán las
#' imágenes exista; si no es así, lo crea. Luego, recorre cada URL proporcionada,
#' extrae un nombre de archivo a partir del URL, y descarga la imagen en formato
#' JPG usando la librería `httr`.
#'
#' El nombre de archivo se genera a partir del segmento de la URL que sigue a "media/"
#' y se le agrega la extensión ".jpg".
#'
#' @export
#'
#' @examples
#' \dontrun{
#' urls <- c("https://x.com/AAS_Sociologia/status/1838907832927768645", "https://x.com/AAS_Sociologia/status/1841819590587822081")
#' getTweetsImages(urls)
#' }
#' 
#' @import httr
#' @import stringr

getTweetsImages <- function(urls, directorio = "img_x") {
  
  # Asegurar que urls sea un vector, si es una lista la desanida
  urls <- unlist(urls)
  
  # Crear el directorio si no existe
  # Esto asegura que tengamos un lugar para guardar las imágenes
  if (!dir.exists(directorio)) {
    dir.create(directorio)
  }
  
  # Iterar a través de cada URL y descargar la imagen correspondiente
  for (i in seq_along(urls)) {
    url <- urls[i]
    
    # Extraer el nombre del archivo de la URL
    # Esta expresión regular busca la parte de la URL entre 'media/' y el siguiente '?' o el final de la cadena
    file_name <- stringr::str_extract(url, "(?<=media/)[^?]+")
    
    # Construir la ruta completa del archivo para guardar la imagen
    # Añadimos '.jpg' para asegurar que el archivo se guarde con la extensión correcta
    nombre_archivo <- file.path(directorio, paste0(file_name, ".jpg"))
    
    # Descargar la imagen usando httr
    # GET recupera los datos de la imagen, write_disk la guarda en el archivo especificado
    # overwrite = TRUE asegura que reemplacemos cualquier archivo existente con el mismo nombre
    httr::GET(url, httr::write_disk(nombre_archivo, overwrite = TRUE))
  }
  
  # Nota: La función no devuelve nada, guarda archivos como efecto secundario
}
