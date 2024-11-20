#' Get Tweets Images
#'
#' @description
#' 
#' <a href="https://lifecycle.r-lib.org/articles/stages.html#experimental" target="_blank"><img src="https://lifecycle.r-lib.org/articles/figures/lifecycle-experimental.svg" alt="[Experimental]"></a>
#' 
#' Esta función toma una lista de URLs de imágenes extraídas de tweets, las descarga y
#' opcionalmente las guarda en un directorio específico. Si el directorio no existe, se creará.
#'
#' @param urls Lista o vector de URLs de imágenes que se desea descargar.
#' @param directorio (opcional) Nombre del directorio donde se guardarán las imágenes.
#' El valor predeterminado es "img_x". Si el directorio no existe, la función lo crea.
#' @param save Lógico. Indica si se deben guardar las imágenes en el directorio especificado (por defecto TRUE).
#'
#' @details La función primero asegura que el directorio donde se guardarán las
#' imágenes exista; si no es así, lo crea (si save = TRUE). Luego, recorre cada URL proporcionada,
#' extrae un nombre de archivo a partir del URL, y descarga la imagen en formato
#' JPG usando la librería `httr`.
#'
#' El nombre de archivo se genera a partir del segmento de la URL que sigue a "media/"
#' y se le agrega la extensión ".jpg".
#'
#' Si save = FALSE, la función descargará las imágenes pero no las guardará en el disco.
#'
#' @return Una lista invisible de las rutas de archivo donde se guardaron las imágenes,
#' o NULL si save = FALSE.
#'
#' @export
#'
#' @examples
#' \dontrun{
#' urls <- c("https://x.com/AAS_Sociologia/status/1838907832927768645", "https://x.com/AAS_Sociologia/status/1841819590587822081")
#' getTweetsImages(urls)
#' 
#' # Sin guardar las imágenes
#' getTweetsImages(urls, save = FALSE)
#' }
#' 
#' @importFrom httr GET write_disk
#' @importFrom stringr str_extract
#' @importFrom tools file_path_sans_ext
#' 

getTweetsImages <- function(urls, directorio = "img_x", save = TRUE) {
  
  # Asegurar que urls sea un vector, si es una lista la desanida
  urls <- unlist(urls)
  
  # Crear el directorio si no existe y save es TRUE
  if (save && !dir.exists(directorio)) {
    dir.create(directorio)
  }
  
  # Lista para almacenar las rutas de los archivos guardados
  archivos_guardados <- list()
  
  # Iterar a través de cada URL y descargar la imagen correspondiente
  for (i in seq_along(urls)) {
    url <- urls[i]
    
    # Extraer el nombre del archivo de la URL
    file_name <- tools::file_path_sans_ext(stringr::str_extract(url, "(?<=media/)[^?]+|[^/]+(?=\\?|$)"))
    
    # Construir la ruta completa del archivo para guardar la imagen
    nombre_archivo <- file.path(directorio, paste0(file_name, ".jpg"))
    
    if (save) {
      # Descargar y guardar la imagen usando httr
      httr::GET(url, httr::write_disk(nombre_archivo, overwrite = TRUE))
      archivos_guardados[[i]] <- nombre_archivo
    } else {
      # Descargar la imagen pero no guardarla
      httr::GET(url)
    }
  }
  
  if (save) {
    cat("Imágenes procesadas y guardadas.\n")
    invisible(archivos_guardados)
  } else {
    cat("Imágenes procesadas. No se han guardado en el disco.\n")
    invisible(NULL)
  }
}
