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
#' @param xuser Nombre de usuarix de Twitter para autenticación. Por defecto es el valor de la variable de entorno TWITTER_USER (o, si no está definida, USER).
#' @param xpass Contraseña de Twitter para autenticación. Por defecto es el valor de la variable de entorno TWITTER_PASS (o, si no está definida, PASS).
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
#' @importFrom lubridate as_datetime
#' @importFrom tibble tibble
#' @importFrom jsonlite fromJSON
#'

getUsersFullData <- function(
    urls_users,
    xuser = Sys.getenv("TWITTER_USER", Sys.getenv("USER")),
    xpass = Sys.getenv("TWITTER_PASS", Sys.getenv("PASS")),
    dir = getwd(),
    save = TRUE
) {
  twitter <- NULL
  on.exit(.close_sessions(twitter), add = TRUE)
  twitter <- .x_login(xuser, xpass)

  users_list <- list()

  # Inicializar el objeto para almacenar las URLs que fallan
  urls_fallidas <- c()

  for (i in urls_users) {
    users <- NULL
    tryCatch({
      users <- rvest::read_html_live(i)
      Sys.sleep(2)

      json_list <- jsonlite::fromJSON(rvest::html_text(users$html_elements(xpath = "/html/head/script[1]")))
      author <- json_list$mainEntity$givenName
      interaction_stats <- json_list$mainEntity$interactionStatistic
      users_list[[length(users_list) + 1]] <- tibble::tibble(fecha_creacion = lubridate::as_datetime(.field_or_na(json_list$dateCreated)),
                                                 nombre_adicional = .field_or_na(json_list$mainEntity$additionalName), descripcion = .field_or_na(json_list$mainEntity$description),
                                                 nombre = .field_or_na(author), ubicacion = .field_or_na(json_list$mainEntity$homeLocation$name),
                                                 identificador = .field_or_na(json_list$mainEntity$identifier), url_imagen = .field_or_na(json_list$mainEntity$image$contentUrl),
                                                 url_miniatura = .field_or_na(json_list$mainEntity$image$thumbnailUrl),
                                                 seguidorxs = .field_or_na(interaction_stats$userInteractionCount[1]),
                                                 amigxs = .field_or_na(interaction_stats$userInteractionCount[2]),
                                                 tweets = .field_or_na(interaction_stats$userInteractionCount[3]),
                                                 url = .field_or_na(json_list$mainEntity$url), enlaces_relacionados = paste(json_list$relatedLink,
                                                                                                              collapse = ", "))
      Sys.sleep(2)
      message("Datos recolectados usuarix: ", sub("^https://twitter.com/(.*?)|^https://x.com/(.*?)", "\\1", i))
    }, error = function(e) {
      message("Datos sin recolectar usuarix: ", sub("^https://twitter.com/(.*?)|^https://x.com/(.*?)", "\\1", i))

      # Agregar la URL que falló al objeto urls_fallidas
      urls_fallidas <<- c(urls_fallidas, i)
    }, finally = {
      .close_sessions(users)
    })
  }

  users_db <- dplyr::bind_rows(users_list)

  if (save) {
    # Guardar la base de datos de usuarios recolectados
    saveRDS(users_db, paste0(dir, "/db_full_users_", format(Sys.time(), "%Y_%m_%d_%H_%M_%S"), ".rds"))

    # Guardar las URLs fallidas en un archivo
    if (length(urls_fallidas) > 0) {
      writeLines(urls_fallidas, paste0(dir, "/urls_fallidas_", format(Sys.time(), "%Y_%m_%d_%H_%M_%S"), ".txt"))
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

#' Devuelve NA si un campo extraido del JSON-LD es NULL o de largo cero
#'
#' tibble() descarta silenciosamente las columnas NULL, por lo que un perfil
#' con campos faltantes en su JSON-LD produciria un tibble con menos columnas
#' y dplyr::bind_rows() alteraria la membresia y el orden de columnas del
#' tibble final. Este helper garantiza que cada campo aporte siempre un valor
#' de largo uno (NA si falta), preservando las 13 columnas canonicas y su
#' orden en cada perfil recolectado.
#'
#' @param x Valor extraido del JSON-LD (posiblemente NULL o vacio).
#'
#' @return x si tiene largo mayor a cero; NA en caso contrario.
#' @noRd
.field_or_na <- function(x) {
  if (is.null(x) || length(x) == 0) NA else x
}
