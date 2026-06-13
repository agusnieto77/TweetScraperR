#' Get Users Data
#'
#' @description
#'
#' <a href="https://lifecycle.r-lib.org/articles/stages.html#experimental" target="_blank"><img src="https://lifecycle.r-lib.org/articles/figures/lifecycle-experimental.svg" alt="[Experimental]"></a>
#'
#' @description
#' **Obsoleta**: preféri getUsersDataAPI(), basada en la API de X (datos del JSON, mas robusta).
#'
#' Esta función permite recuperar y procesar datos de usuarixs de Twitter a partir de un vector de URLs
#' proporcionadas. Opcionalmente puede realizar la autenticación en Twitter si open=TRUE utilizando las
#' credenciales proporcionadas. La función extrae información detallada de cada perfil de usuarix incluyendo
#' el nombre del usuarix, el username, la fecha de creación del perfil, el número de publicaciones,
#' seguidorxs y seguidxs. La función maneja posibles errores durante el proceso de recolección de datos y
#' realiza reintentos automáticos cuando es necesario. Los datos recopilados se devuelven en forma de un
#' tibble y, si se especifica, se guardan en un archivo RDS para su posterior uso.
#'
#' @param urls_users Vector de URLs de users de los cuales se desea obtener datos.
#' @param open Indica si se debe realizar el proceso de autenticación (por defecto FALSE).
#' @param xuser Nombre de usuarix de Twitter para autenticación. Por defecto es el valor de la variable de entorno TWITTER_USER (o, si no está definida, USER).
#' @param xpass Contraseña de Twitter para autenticación. Por defecto es el valor de la variable de entorno TWITTER_PASS (o, si no está definida, PASS).
#' @param max_retries número máximo de intentos de conexión. Por defecto es 3.
#' @param dir Directorio donde se guardará el archivo RDS con los datos recopilados. Por defecto es el directorio actual.
#' @param save Lógico. Indica si se debe guardar el resultado en un archivo RDS (por defecto TRUE).
#' @return Un tibble que contiene los datos de los users recuperados.
#' @export
#'
#' @examples
#' \dontrun{
#' # Sin autenticación
#' getUsersData(urls_users = "https://x.com/estacion_erre")
#'
#' # Con autenticación
#' getUsersData(urls_users = "https://x.com/estacion_erre", open = TRUE)
#'
#' # Sin guardar los resultados
#' getUsersData(urls_users = "https://x.com/estacion_erre", save = FALSE)
#' }
#'
#' @importFrom rvest html_elements html_text html_text2
#' @importFrom lubridate dmy
#' @importFrom tibble tibble
#' @importFrom utils tail
#'

getUsersData <- function(
    urls_users,
    open = FALSE,
    xuser = Sys.getenv("TWITTER_USER", Sys.getenv("USER")),
    xpass = Sys.getenv("TWITTER_PASS", Sys.getenv("PASS")),
    max_retries = 3,
    dir = getwd(),
    save = TRUE
) {
  .Deprecated(msg = "getUsersData() est\u00e1 obsoleta: us\u00e1 getUsersDataAPI() (basada en la API de X, datos estructurados del JSON, m\u00e1s robusta). Ver ?getUsersDataAPI.")
  global_retry_count <- 0
  success <- FALSE
  twitter <- NULL
  users_db <- tibble::tibble()
  on.exit(.close_sessions(twitter), add = TRUE)

  while (global_retry_count < max_retries && !success) {
    ok <- tryCatch({
      if (open) {
        .close_sessions(twitter)
        twitter <- .x_login(xuser, xpass)
      }

      todo <- "#react-root > div > div > div.css-175oi2r.r-1f2l425.r-13qz1uu.r-417010.r-18u37iz > main > div > div > div > div > div"
      name <- "h2"
      met_post <- "div.css-175oi2r.r-aqfbo4.r-gtdqiz.r-1gn8etr.r-1g40b8q > div:nth-child(1) > div > div > div > div > div > div.css-175oi2r.r-16y2uox.r-1wbh5a2.r-1pi2tsx.r-1777fci > div > div"
      fech <- "span.css-1jxf684.r-bcqeeo.r-1ttztb7.r-qvutc0.r-poiln3.r-4qtqp9.r-1a11zyx span.css-1jxf684.r-bcqeeo.r-1ttztb7.r-qvutc0.r-poiln3"
      met_siguiendo <- "div:nth-child(3) > div > div > div > div.css-175oi2r.r-3pj75a.r-ttdzmv.r-1ifxtd0 > div.css-175oi2r.r-13awgt0.r-18u37iz.r-1w6e6rj > div:nth-child(1)"
      met_seguidores <- "div:nth-child(3) > div > div > div > div.css-175oi2r.r-3pj75a.r-ttdzmv.r-1ifxtd0 > div.css-175oi2r.r-13awgt0.r-18u37iz.r-1w6e6rj > div:nth-child(2)"
      Sys.sleep(1)

      users_list <- list()

      # Procesa URLs iniciales
      for (i in urls_users) {
        users <- NULL
        tryCatch({
          users <- rvest::read_html_live(i)
          Sys.sleep(2)
          nodo <- users$html_elements(css = todo)
          Sys.sleep(2)
          users_list[[length(users_list) + 1]] <- tibble::tibble(
            fecha_inicio = lubridate::dmy(paste("01", gsub("^.*uni\u00f3 en |^.*ined ", "", tail(rvest::html_text(rvest::html_elements(nodo, css = fech)), 1)), collapse = " ")),
            nombre = rvest::html_text2(rvest::html_elements(nodo, css = name))[1],
            username = sub("^https://twitter.com/(.*?)|^https://x.com/(.*?)", "\\1", i),
            n_post = gsub(" posts", "", rvest::html_text(rvest::html_elements(nodo, css = met_post))[1]),
            n_siguiendo = gsub(" Siguiendo| Following", "", rvest::html_text(rvest::html_elements(nodo, css = met_siguiendo))[1]),
            n_seguidorxs = gsub(" Seguidores| Followers", "", rvest::html_text(rvest::html_elements(nodo, css = met_seguidores))[1]),
            url = i,
            fecha_captura = Sys.time()
          )
          message("Datos recolectados usuarix: ", sub("^https://twitter.com/(.*?)|^https://x.com/(.*?)", "\\1", i))
        }, error = function(e) {
          message("Error al procesar usuarix ", i, ": ", e$message)
        }, finally = {
          if (!is.null(users)) users$session$close()
        })
      }
      users_db <- dplyr::bind_rows(users_list)

      # Reprocesa URLs con fechas NA hasta que no queden más o se alcance el límite de reintentos
      retry_count <- 0
      while (any(is.na(users_db$fecha_inicio)) && retry_count < max_retries) {
        urls_con_na <- users_db$url[is.na(users_db$fecha_inicio)]

        for (i in urls_con_na) {
          users <- NULL
          tryCatch({
            users <- rvest::read_html_live(i)
            Sys.sleep(2)
            nodo <- users$html_elements(css = todo)
            Sys.sleep(2)
            fecha_inicio <- rvest::html_text(rvest::html_elements(nodo, css = fech))
            if (length(fecha_inicio) > 0) {
              fecha_inicio <- lubridate::dmy(paste("01", gsub("^.*uni\u00f3 en |^.*ined ", "", tail(fecha_inicio, 1)), collapse = " "))
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
          }, error = function(e) {
            message("Error al actualizar usuarix ", i, ": ", e$message)
          }, finally = {
            if (!is.null(users)) users$session$close()
          })
        }
        retry_count <- retry_count + 1
      }

      success <- TRUE
      TRUE
    }, error = function(e) {
      message("Error general: ", e$message)
      FALSE
    })
    if (!ok) {
      global_retry_count <- global_retry_count + 1
      message("Reintentando... (Intento ", global_retry_count, " de ", max_retries, ")")
      Sys.sleep(5)
    }
  }

  if (!success) {
    stop("No se pudo completar la operaci\u00f3n despu\u00e9s de ", max_retries, " intentos.")
  }

  # Convertir números con sufijos (K, M) a valores numéricos
  convertir_numero <- function(x) {
    x <- as.character(x)  # Convertir a caracteres por si acaso
    if (grepl("mil|K", x)) {
      return(as.numeric(gsub("[^0-9.]", "", x)) * 1000)
    } else if (grepl("M", x)) {
      return(as.numeric(gsub("[^0-9.]", "", x)) * 1000000)
    } else {
      return(as.numeric(x))
    }
  }

  # Normalizar separadores decidiendo desde el propio string:
  # solo se elimina un separador cuando es inequívocamente de miles
  normalizar_separadores <- function(x) {
    x <- as.character(x)
    if (grepl("^[0-9]{1,3}(,[0-9]{3})+$", x)) {
      # coma como separador de miles (formato inglés): quitarla
      return(gsub(",", "", x))
    }
    if (grepl("^[0-9]{1,3}(\\.[0-9]{3})+$", x)) {
      # punto como separador de miles (formato español): quitarlo
      return(gsub("\\.", "", x))
    }
    # separador único tratado como decimal: normalizar coma a punto
    gsub(",", ".", x)
  }

  # Procesar los números
  users_db$n_post <- sapply(users_db$n_post, function(x) convertir_numero(normalizar_separadores(x)))
  users_db$n_siguiendo <- sapply(users_db$n_siguiendo, function(x) convertir_numero(normalizar_separadores(x)))
  users_db$n_seguidorxs <- sapply(users_db$n_seguidorxs, function(x) convertir_numero(normalizar_separadores(x)))

  .save_rds(users_db, dir, "db_users", save = save)

  return(users_db)
}
