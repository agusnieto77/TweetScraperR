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
#' devuelven en forma de un tibble y se guardan en un archivo RDS para su posterior uso.
#'
#' @param urls_users Vector de URLs de users de los cuales se desea obtener datos.
#' @param xuser Nombre de usuarix de Twitter para autenticación. Por defecto es el valor de la variable de entorno del sistema USER.
#' @param xpass Contraseña de Twitter para autenticación. Por defecto es el valor de la variable de entorno del sistema PASS.
#' @param dir Directorio donde se guardará el archivo RDS con los datos recopilados. Por defecto es el directorio actual.
#' @return Un tibble que contiene los datos de los users recuperados.
#' @export
#'
#' @examples
#' \dontrun{
#' getUsersFullData(urls_users = "https://x.com/estacion_erre")
#' }
#'
#' @import rvest
#' @import lubridate
#' @import tibble

getUsersFullData <- function(
    urls_users,
    xuser = Sys.getenv("USER"),
    xpass = Sys.getenv("PASS"),
    dir = getwd()
) {
  twitter <- rvest::read_html_live("https://x.com/i/flow/login")
  Sys.sleep(6)
  userx <- "#layers > div > div > div > div > div > div > div.css-175oi2r > div.css-175oi2r > div > div > div.css-175oi2r > div.css-175oi2r > div > div > div > div.css-175oi2r > label > div > div.css-175oi2r > div > input"
  nextx <- "#layers div > div > div > button:nth-child(6) > div"
  passx <- "#layers > div > div > div > div > div > div > div > div > div > div > div > div > div > div > div > div > div > label > div > div > div > input"
  login <- "#layers > div > div > div > div > div > div > div.css-175oi2r > div.css-175oi2r > div > div > div.css-175oi2r > div.css-175oi2r.r-16y2uox > div.css-175oi2r > div > div.css-175oi2r > div > div > button"
  twitter$type(css = userx, text = xuser)
  twitter$click(css = nextx, n_clicks = 1)
  Sys.sleep(2)
  twitter$type(css = passx, text = xpass)
  twitter$click(css = login, n_clicks = 1)
  Sys.sleep(2)
  todo <- "#react-root > div > div > div.css-175oi2r.r-1f2l425.r-13qz1uu.r-417010.r-18u37iz > main > div > div > div > div > div"
  name <- "h2"
  met_post <- "div.css-175oi2r.r-aqfbo4.r-gtdqiz.r-1gn8etr.r-1g40b8q > div:nth-child(1) > div > div > div > div > div > div.css-175oi2r.r-16y2uox.r-1wbh5a2.r-1pi2tsx.r-1777fci > div > div"
  descrip <- "div > div > div.css-175oi2r.r-1f2l425.r-13qz1uu.r-417010.r-18u37iz > main > div > div > div > div.css-175oi2r.r-14lw9ot.r-jxzhtn.r-13l2t4g.r-1ljd8xs.r-1phboty.r-16y2uox.r-184en5c.r-61z16t.r-11wrixw.r-1jgb5lz.r-13qz1uu.r-1ye8kvj > div > div:nth-child(3) > div > div > div > div.css-175oi2r.r-ymttw5.r-ttdzmv.r-1ifxtd0 > div:nth-child(3) > div > div"
  fech <- "span.css-1jxf684.r-bcqeeo.r-1ttztb7.r-qvutc0.r-poiln3.r-4qtqp9.r-1a11zyx span.css-1jxf684.r-bcqeeo.r-1ttztb7.r-qvutc0.r-poiln3"
  met_siguiendo <- "div:nth-child(3) > div > div > div > div.css-175oi2r.r-3pj75a.r-ttdzmv.r-1ifxtd0 > div.css-175oi2r.r-13awgt0.r-18u37iz.r-1w6e6rj > div:nth-child(1)"
  met_seguidores <- "div:nth-child(3) > div > div > div > div.css-175oi2r.r-3pj75a.r-ttdzmv.r-1ifxtd0 > div.css-175oi2r.r-13awgt0.r-18u37iz.r-1w6e6rj > div:nth-child(2)"
  Sys.sleep(1)
  users_db <- tibble::tibble()
  for (i in urls_users) {
    users <- rvest::read_html_live(i)
    Sys.sleep(2)
    json_list <- jsonlite::fromJSON(rvest::html_text(users$html_elements(xpath = "/html/head/script[3]")))
    author <- json_list$author
    interaction_stats <- author$interactionStatistic
    users_db <- rbind(users_db, tibble::tibble(
      fecha_creacion = lubridate::as_datetime(json_list$dateCreated),
      nombre_adicional = author$additionalName,
      descripcion = author$description,
      nombre = author$givenName,
      ubicacion = author$homeLocation$name,
      identificador = author$identifier,
      url_imagen = author$image$contentUrl,
      url_miniatura = author$image$thumbnailUrl,
      seguidorxs = interaction_stats$userInteractionCount[1],
      amigxs = interaction_stats$userInteractionCount[2],
      tweets = interaction_stats$userInteractionCount[3],
      url = author$url,
      enlaces_relacionados = paste(json_list$relatedLink, collapse = ", ")
    ))
    Sys.sleep(2)
    message("Datos recolectados usuarix: ", sub("^https://twitter.com/(.*?)|^https://x.com/(.*?)", "\\1", i))
    users$session$close()
  }
  twitter$session$close()
  saveRDS(users_db, paste0(dir, "/db_full_users_", gsub("-|:|\\.", "_", format(Sys.time(), "%Y_%m_%d_%X")), ".rds"))
  return(users_db)
}
