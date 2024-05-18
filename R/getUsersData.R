#' Get Users Data
#'
#' Esta función recupera datos de users a partir de URLs de users proporcionadas.
#'
#' @param urls_users Vector de URLs de users de los cuales se desea obtener datos.
#' @param xuser Nombre de usuario de Twitter para autenticación. Por defecto es el valor de la variable de entorno del sistema USER.
#' @param xpass Contraseña de Twitter para autenticación. Por defecto es el valor de la variable de entorno del sistema PASS.
#' @return Un tibble que contiene los datos de los users recuperados.
#' @export
#'
#' @examples
#' \dontrun{
#' getUsersData(urls_users = "https://x.com/estacion_erre")
#' }
#'
#' @import rvest
#' @import lubridate
#' @import tibble

getUsersData <- function(
    urls_users,
    xuser = Sys.getenv("USER"),
    xpass = Sys.getenv("PASS")
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
  
  # Procesa URLs iniciales
  for (i in urls_users) {
    users <- rvest::read_html_live(i)
    Sys.sleep(2)
    nodo <- users$html_elements(css = todo)
    Sys.sleep(2)
    users_db <- rbind(
      users_db,
      tibble::tibble(
        fecha_inicio = lubridate::dmy(paste("01", gsub("^.*unió en |^.*ined ", "", tail(rvest::html_text(rvest::html_elements(nodo, css = fech)), 1)), collapse = " ")),
        nombre = rvest::html_text2(rvest::html_elements(nodo, css = name))[1],
        username = sub("^https://twitter.com/(.*?)|^https://x.com/(.*?)", "\\1", i),
        n_post = gsub(" posts", "", rvest::html_text(rvest::html_elements(nodo, css = met_post))[1]),
        n_siguiendo = gsub(" Siguiendo| Following", "", rvest::html_text(rvest::html_elements(nodo, css = met_siguiendo))[1]),
        n_seguidorxs = gsub(" Seguidores| Followers", "", rvest::html_text(rvest::html_elements(nodo, css = met_seguidores))[1]),
        url = i
      )
    )
    message("Datos recolectados usuarix: ", sub("^https://twitter.com/(.*?)|^https://x.com/(.*?)", "\\1", i))
    users$session$close()
  }
  
  # Reprocesa URLs con fechas NA hasta que no queden más
  while (any(is.na(users_db$fecha_inicio))) {
    urls_con_na <- users_db$url[is.na(users_db$fecha_inicio)]
    
    for (i in urls_con_na) {
      users <- rvest::read_html_live(i)
      Sys.sleep(2)
      nodo <- users$html_elements(css = todo)
      Sys.sleep(2)
      fecha_inicio <- rvest::html_text(rvest::html_elements(nodo, css = fech))
      if (length(fecha_inicio) > 0) {
        fecha_inicio <- lubridate::dmy(paste("01", gsub("^.*unió en |^.*ined ", "", tail(fecha_inicio, 1)), collapse = " "))
      } else {
        fecha_inicio <- NA
      }
      
      idx <- which(users_db$url == i)
      if (is.na(users_db$fecha_inicio[idx])) {
        users_db$fecha_inicio[idx] <- fecha_inicio
        users_db$nombre[idx] <- rvest::html_text2(rvest::html_elements(nodo, css = name))[1]
        users_db$username[idx] <- sub("^https://twitter.com/(.*?)|^https://x.com/(.*?)", "\\1", i)
        users_db$n_post[idx] <- gsub(" posts", "", rvest::html_text(rvest::html_elements(nodo, css = met_post))[1])
        users_db$n_siguiendo[idx] <- gsub(" Siguiendo| Following", "", rvest::html_text(rvest::html_elements(nodo, css = met_siguiendo))[1])
        users_db$n_seguidorxs[idx] <- gsub(" Seguidores| Followers", "", rvest::html_text(rvest::html_elements(nodo, css = met_seguidores))[1])
      }
      
      message("Datos actualizados usuarix: ", sub("^https://twitter.com/(.*?)|^https://x.com/(.*?)", "\\1", i))
      users$session$close()
    }
  }
  
  twitter$session$close()
  
  convertir_mil <- function(x) {
    ifelse(grepl("mil|K", x), as.numeric(gsub("[^0-9.]", "", x)) * 1000, as.numeric(x))
  }
  
  users_db$n_post <- sapply(gsub(",", ".", gsub("\\.", "", users_db$n_post)), convertir_mil)
  users_db$n_siguiendo <- sapply(gsub(",", ".", gsub("\\.", "", users_db$n_siguiendo)), convertir_mil)
  users_db$n_seguidorxs <- sapply(gsub(",", ".", gsub("\\.", "", users_db$n_seguidorxs)), convertir_mil)
  
  saveRDS(users_db, paste0("db_users_", gsub("-|:|\\.", "_", format(Sys.time(), "%Y_%m_%d_%X")), ".rds"))
  
  return(users_db)
}
