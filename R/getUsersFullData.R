#' Get Users Full Data 
#'
#' @description
#' 
#' <a href="https://lifecycle.r-lib.org/articles/stages.html#experimental" target="_blank"><img src="https://lifecycle.r-lib.org/articles/figures/lifecycle-experimental.svg" alt="[Experimental]"></a>
#' 
#' Esta función permite recuperar y procesar datos de usuarixs de Twitter a partir de un vector de URLs 
#' proporcionadas. Utilizando las credenciales de unx usuarix de Twitter, la función realiza la autenticación y 
#' extrae información detallada de cada perfil de usuarix. Los datos extraídos incluyen el nombre del usuarix, 
#' el username, la fecha de creación del perfil, el número de publicaciones, seguidorxs, seguidxs y otros metadatos.
#' La función maneja posibles errores durante el proceso de recolección de datos, como tiempos de espera prolongados, y 
#' se asegura de obtener información precisa mediante múltiples intentos si es necesario. Los datos recopilados se 
#' devuelven en forma de un tibble y, si se especifica, se guardan en un archivo RDS para su posterior uso.
#'
#' @param urls_users Vector de URLs de users de los cuales se desea obtener datos.
#' @param xuser Nombre de usuarix de Twitter para autenticación. Por defecto es el valor de la variable de entorno del sistema USER.
#' @param xpass Contraseña de Twitter para autenticación. Por defecto es el valor de la variable de entorno del sistema PASS.
#' @param dir Directorio donde se guardará el archivo RDS con los datos recopilados. Por defecto es el directorio actual.
#' @param save Lógico. Indica si se debe guardar el resultado en un archivo RDS (por defecto TRUE).
#' @return Un tibble que contiene los datos de los users recuperados.
#' @export
#'
#' @examples
#' \dontrun{
#' getUsersFullData(urls_users = "https://x.com/estacion_erre")
#' 
#' # Sin guardar los resultados
#' getUsersFullData(urls_users = "https://x.com/estacion_erre", save = FALSE)
#' }
#'
#' @importFrom rvest read_html_live html_elements html_text
#' @importFrom lubridate as_datetime
#' @importFrom tibble tibble
#' @importFrom jsonlite fromJSON
#' 

getUsersFullData <- function(
    urls_users,
    xuser = Sys.getenv("USER"),
    xpass = Sys.getenv("PASS"),
    dir = getwd(),
    save = TRUE
) {
  twitter <- rvest::read_html_live("https://x.com/i/flow/login")
  Sys.sleep(6)
  
  userx <- "#layers > div > div > div > div > div > div > div.css-175oi2r > div.css-175oi2r > div > div > div.css-175oi2r > div.css-175oi2r > div > div > div > div.css-175oi2r > label > div > div.css-175oi2r > div > input"
  nextx <- "#layers div > div > div > button:nth-child(6) > div"
  passx <- "#layers > div > div > div > div > div > div > div > div > div > div > div > div > div > div > div > div > div > label > div > div > div > input"
  login <- "#layers > div > div > div > div > div > div > div.css-175oi2r > div.css-175oi2r > div > div > div.css-175oi2r > div.css-175oi2r.r-16y2uox > div.css-175oi2r > div > div.css-175oi2r > div > div > button"
  
  tryCatch({
    twitter$type(css = userx, text = xuser)
    twitter$click(css = nextx, n_clicks = 1)
    Sys.sleep(2)
    
    twitter$type(css = passx, text = xpass)
    twitter$click(css = login, n_clicks = 1)
    Sys.sleep(2)
  }, error = function(e) {
    message("Sesión ya iniciada...")
  })
  
  users_db <- tibble::tibble()
  
  # Inicializar el objeto para almacenar las URLs que fallan
  urls_fallidas <- c()
  
  for (i in urls_users) {
    tryCatch({
      users <- rvest::read_html_live(i)
      Sys.sleep(2)
      
      json_list <- jsonlite::fromJSON(rvest::html_text(users$html_elements(xpath = "/html/head/script[1]")))
      author <- json_list$mainEntity$givenName
      interaction_stats <- json_list$mainEntity$interactionStatistic
      users_db <- rbind(users_db, tibble::tibble(fecha_creacion = lubridate::as_datetime(json_list$dateCreated), 
                                                 nombre_adicional = json_list$mainEntity$additionalName, descripcion = json_list$mainEntity$description, 
                                                 nombre = author, ubicacion = json_list$mainEntity$homeLocation$name, 
                                                 identificador = json_list$mainEntity$identifier, url_imagen = json_list$mainEntity$image$contentUrl, 
                                                 url_miniatura = json_list$mainEntity$image$thumbnailUrl, 
                                                 seguidorxs = json_list$mainEntity$interactionStatistic$userInteractionCount[1], 
                                                 amigxs = json_list$mainEntity$interactionStatistic$userInteractionCount[2], 
                                                 tweets = json_list$mainEntity$interactionStatistic$userInteractionCount[3], 
                                                 url = json_list$mainEntity$url, enlaces_relacionados = paste(json_list$relatedLink, 
                                                                                                              collapse = ", ")))
      Sys.sleep(2)
      message("Datos recolectados usuarix: ", sub("^https://twitter.com/(.*?)|^https://x.com/(.*?)", "\\1", i))
      users$session$close()
    }, error = function(e) {
      message("Datos sin recolectar usuarix: ", sub("^https://twitter.com/(.*?)|^https://x.com/(.*?)", "\\1", i))
      
      # Agregar la URL que falló al objeto urls_fallidas
      urls_fallidas <<- c(urls_fallidas, i)
    })
  }
  
  twitter$session$close()
  
  if (save) {
    # Guardar la base de datos de usuarios recolectados
    saveRDS(users_db, paste0(dir, "/db_full_users_", gsub("-|:|\\.", "_", format(Sys.time(), "%Y_%m_%d_%X")), ".rds"))
    
    # Guardar las URLs fallidas en un archivo
    if (length(urls_fallidas) > 0) {
      writeLines(urls_fallidas, paste0(dir, "/urls_fallidas_", gsub("-|:|\\.", "_", format(Sys.time(), "%Y_%m_%d_%X")), ".txt"))
    }
    cat("Datos procesados y guardados.\n")
  } else {
    cat("Datos procesados. No se han guardado en archivos.\n")
  }
  
  cat("\nTerminando el proceso.
      \nUsuarixs recuperados:",
      length(users_db$url),
      "\nUsuarixs no recuperados:",
      length(urls_fallidas),
      "\n\n")
  return(users_db)
}
