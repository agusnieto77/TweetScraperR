#' Get Tweets Images
#'
#' @description
#' 
#' <a href="https://lifecycle.r-lib.org/articles/stages.html#experimental" target="_blank"><img src="https://lifecycle.r-lib.org/articles/figures/lifecycle-experimental.svg" alt="[Experimental]"></a>
#' 
#' Esta funci\u00f3n toma una lista de URLs de im\u00e1genes extra\u00eddas de tweets, las descarga y
#' opcionalmente las guarda en un directorio espec\u00edfico. Si el directorio no existe, se crear\u00e1.
#'
#' @param urls Lista o vector de URLs de im\u00e1genes que se desea descargar.
#' @param directorio (opcional) Nombre del directorio donde se guardar\u00e1n las im\u00e1genes.
#' El valor predeterminado es "img_x". Si el directorio no existe, la funci\u00f3n lo crea.
#' @param save L\u00f3gico. Indica si se deben guardar las im\u00e1genes en el directorio especificado (por defecto TRUE).
#'
#' @details La funci\u00f3n primero asegura que el directorio donde se guardar\u00e1n las
#' im\u00e1genes exista; si no es as\u00ed, lo crea (si save = TRUE). Luego, recorre cada URL proporcionada,
#' extrae un nombre de archivo a partir del URL, y descarga la imagen en formato
#' JPG usando la librer\u00eda `httr`.
#'
#' El nombre de archivo se genera a partir del segmento de la URL que sigue a "media/"
#' y se le agrega la extensi\u00f3n ".jpg".
#'
#' Si save = FALSE, la funci\u00f3n descargar\u00e1 las im\u00e1genes pero no las guardar\u00e1 en el disco.
#'
#' @return Una lista invisible de las rutas de archivo donde se guardaron las im\u00e1genes,
#' o NULL si save = FALSE.
#'
#' @export
#'
#' @examples
#' \dontrun{
#' urls <- c("https://x.com/AAS_Sociologia/status/1838907832927768645", "https://x.com/AAS_Sociologia/status/1841819590587822081")
#' getTweetsImages(urls)
#' 
#' # Sin guardar las im\u00e1genes
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
  
  # Iterar a trav\u00e9s de cada URL y descargar la imagen correspondiente
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
    cat("Im\u00e1genes procesadas y guardadas.\n")
    invisible(archivos_guardados)
  } else {
    cat("Im\u00e1genes procesadas. No se han guardado en el disco.\n")
    invisible(NULL)
  }
}
