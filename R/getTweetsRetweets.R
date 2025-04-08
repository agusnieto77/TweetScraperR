#' Get Users Retweets with Data
#'
#' @description
#' 
#' <a href="https://lifecycle.r-lib.org/articles/stages.html#experimental" target="_blank"><img src="https://lifecycle.r-lib.org/articles/figures/lifecycle-experimental.svg" alt="[Experimental]"></a>
#' 
#' Esta función recupera los retweets a un tweet específico en Twitter (ahora X),
#' incluyendo datos como el texto del tweet, usuario, fecha, y URL.
#' Utiliza web scraping para acceder a la página del tweet, iniciar sesión con las credenciales proporcionadas,
#' y recolectar la información de los retweets al tweet.
#' 
#' El proceso incluye:
#' 1. Iniciar sesión en Twitter usando las credenciales proporcionadas (si open=TRUE).
#' 2. Navegar a la URL del tweet especificado con "/retweets" para ver los retweets.
#' 3. Extraer la información de los retweets mediante scraping.
#' 4. Continuar scrolling y recolectando datos hasta alcanzar el número deseado o no encontrar nuevas citas.
#' 
#' La función guarda los datos recolectados en un archivo RDS en el directorio especificado si el parámetro 'save' es TRUE,
#' y los devuelve como un data frame.
#'
#' @param url URL del tweet del cual se quieren obtener los retweets. Por defecto es "https://x.com/tipsder/status/1672311054922293254".
#' @param n_users El número máximo de users a recuperar. Por defecto es 100.
#' @param timeout Tiempo de espera entre scrolls en segundos. Por defecto es 2.5.
#' @param xuser Nombre de usuario de Twitter para autenticación. Por defecto es el valor de la variable de entorno del sistema USER.
#' @param xpass Contraseña de Twitter para autenticación. Por defecto es el valor de la variable de entorno del sistema PASS.
#' @param view Ver el navegador. Por defecto es FALSE.
#' @param dir Directorio donde se guardará el archivo RDS con los datos recolectados. Por defecto es el directorio de trabajo actual.
#' @param save Lógico. Indica si se debe guardar el resultado en un archivo RDS (por defecto TRUE).
#' @param open Lógico. Indica si se debe abrir una nueva sesión de login en Twitter (por defecto FALSE).
#'
#' @return Un data frame que contiene información sobre los retweets al tweet especificado, incluyendo usuario, texto, fecha, URL y fecha de captura.
#' @export
#'
#' @examples
#' \dontrun{
#' getTweetsRetweets(url = "https://x.com/tipsder/status/1672311054922293254", n_users = 20)
#' 
#' # Sin guardar los resultados
#' getTweetsRetweets(url = "https://x.com/tipsder/status/1672311054922293254", n_users = 20, save = FALSE)
#' 
#' # Sin abrir una nueva sesión de login
#' getTweetsRetweets(url = "https://x.com/tipsder/status/1672311054922293254", n_users = 20, open = TRUE)
#' }
#'
#' @references
#' Puedes encontrar más información sobre el paquete TweetScraperR en:
#' <https://github.com/agusnieto77/TweetScraperR>
#'
#' @importFrom rvest read_html_live html_elements html_element html_attr html_text read_html
#' @importFrom tibble tibble
#' @importFrom dplyr distinct
#' @importFrom lubridate as_datetime is.POSIXct
#'
#' @note
#' Esta función utiliza web scraping y puede ser sensible a cambios en la estructura de la página de Twitter.

getTweetsRetweets <- function(
    url = "https://x.com/tipsder/status/1672311054922293254",
    n_users = 100,
    timeout = 2.5,
    xuser = Sys.getenv("USER"),
    xpass = Sys.getenv("PASS"),
    view = FALSE,
    dir = getwd(),
    save = TRUE,
    open = FALSE
) {
  # Iniciar sesión en Twitter
  success <- FALSE
  retry_count <- 0
  max_retries <- 3
  
  while (retry_count < max_retries && !success) {
    tryCatch({
      # Intentar iniciar sesión solo si open es TRUE
      if (open) {
        success2 <- FALSE
        while (!success2) {
          tryCatch({
            twitter <- rvest::read_html_live("https://x.com/i/flow/login")
            success2 <- TRUE
          }, error = function(e) {
            if (grepl("loadEventFired", e$message)) {
              message("Error de tiempo de espera, reintentando...")
              Sys.sleep(5)
            } else {
              stop(e)
            }
          })
        }
        
        Sys.sleep(5)
        userx <- "#layers > div > div > div > div > div > div > div.css-175oi2r > div.css-175oi2r > div > div > div.css-175oi2r > div.css-175oi2r > div > div > div > div.css-175oi2r > label > div > div.css-175oi2r > div > input"
        nextx <- "#layers div > div > div > button:nth-child(6) > div"
        passx <- "#layers > div > div > div > div > div > div > div > div > div > div > div > div > div > div > div > div > div > label > div > div > div > input"
        login <- "#layers > div > div > div > div > div > div > div.css-175oi2r > div.css-175oi2r > div > div > div.css-175oi2r > div.css-175oi2r.r-16y2uox > div.css-175oi2r > div > div.css-175oi2r > div > div > button"
        
        twitter$type(css = userx, text = xuser)
        twitter$click(css = nextx, n_clicks = 1)
        Sys.sleep(1)
        twitter$type(css = passx, text = xpass)
        twitter$click(css = login, n_clicks = 1)
        Sys.sleep(1)
      }
      
      # Navegar a la URL del tweet con "/retweets" para ver los retweets
      urlrt <- paste0(url, "/retweets")
      success3 <- FALSE
      while (!success3) {
        tryCatch({
          urlok <- rvest::read_html_live(urlrt)
          if (view) {
            urlok$view()
          }
          success3 <- TRUE
        }, error = function(e) {
          if (grepl("loadEventFired", e$message)) {
            message("Error de tiempo de espera, reintentando...")
            Sys.sleep(5)
          } else {
            stop(e)
          }
        })
      }
      
      Sys.sleep(3)
      
      # XPath para los artículos de citas
      users <- list()
      attempts <- 0
      max_attempts <- 3
      
      html_rt <- '//*[@id="react-root"]/div/div/div[2]/main/div/div/div/div[1]/div/section/div/div/div'
      
      cat("Inició la recolección de users.\n")
      
      while (TRUE) {
        if (length(users) >= n_users || attempts >= max_attempts) {
          cat("Finalizó la recolección de users.\n")
          cat("Procesando datos...\n")
          break
        }
        
        tryCatch({
          Sys.sleep(timeout)
          
          # Recolectar artículos de citas
          tryCatch({
            nuevos_users <- as.character(urlok$html_elements(xpath = html_rt))
          }, error = function(e) {
            message("Error al procesar artículos: ", e$message)
            nuevos_users <- character(0)
          })
          
          # Añadir nuevos artículos a la lista
          new_users <- length(unique(nuevos_users[!nuevos_users %in% users]))
          users <- unique(append(users, nuevos_users))
          users <- users[!is.na(users)]
          
          # Scroll para cargar más citas
          urlok$scroll_by(top = 4000, left = 0)
          message("Users recolectados: ", length(users))
          
          # Verificar si se encontraron nuevos users
          if (new_users <= 1) {
            attempts <- attempts + 1
          } else {
            attempts <- 0
          }
        }, error = function(e) {
          message("Error al recolectar tweet: ", e$message)
          attempts <- attempts + 1
        })
      }
      
      success <- TRUE
      
    }, error = function(e) {
      message("Error: ", e$message)
      retry_count <- retry_count + 1
      message("Reintentando... (Intento ", retry_count, " de ", max_retries, ")")
      Sys.sleep(5)
    })
  }
  
  if (!success) {
    stop("No se pudo completar la operación después de ", max_retries, " intentos.")
  }
  
  # Procesar los artículos recolectados
  if (length(users) > 0) {
    # Crear un data frame para almacenar los datos
    users_recolectados <- tibble::tibble(
      art_html = users,
      user_name = "",
      user = "",
      url_user = "",
      url_rt = url,
      fecha_captura = Sys.time()
    )
    
    user_name <- "span.css-1jxf684.r-bcqeeo.r-1ttztb7.r-qvutc0.r-poiln3"
    user      <- "div.css-146c3p1.r-dnmrzs.r-1udh08x.r-1udbk01.r-3s2u2q.r-bcqeeo.r-1ttztb7.r-qvutc0.r-37j5jr.r-a023e6.r-rjixqe.r-16dba41.r-18u37iz.r-1wvb978 span.css-1jxf684.r-bcqeeo.r-1ttztb7.r-qvutc0.r-poiln3"
    url_user  <- "div.css-175oi2r.r-1wbh5a2.r-dnmrzs a"
    
    # Extraer información de cada artículo
    for (i in 1:length(users_recolectados$art_html)) {
      tryCatch({

        # Extraer usuario
        users_recolectados$user_name[i] <- rvest::html_text(rvest::html_element(rvest::read_html(users[[i]]), css = user_name))
        
        # Extraer texto del tweet
        users_recolectados$user[i] <- rvest::html_text(rvest::html_element(rvest::read_html(users[[i]]), css = user))
        
        # Extraer URL
        users_recolectados$url_user[i] <- paste0("https://x.com", rvest::html_attr(rvest::html_element(rvest::read_html(users[[i]]), css = url_user), "href"))
      }, error = function(e) {
        message("Error al procesar el artículo ", i, ": ", e$message)
      })
    }
    
    # Eliminar duplicados y filas con fechas NA
    users_recolectados <- dplyr::distinct(users_recolectados, url, .keep_all = TRUE)
    users_recolectados <- users_recolectados[!is.na(users_recolectados$fecha), ]
    
    # Guardar resultados si save es TRUE
    if (save) {
      saveRDS(users_recolectados, paste0(dir, "/rt_", sub("https://x.com/(.*)/status/(.*)", "\\1_\\2", url), "_", 
                                          gsub("-|:|\\.", "_", format(Sys.time(), "%Y_%m_%d_%X")), ".rds"))
      cat("Datos procesados y guardados.\n")
    } else {
      cat("Datos procesados. No se han guardado en un archivo RDS.\n")
    }
    
    cat("Users únicos recolectados:", length(users_recolectados$url), "\n")
    
    # Cerrar sesiones
    if (exists("urlok") && !is.null(urlok)) urlok$session$close()
    if (open && exists("twitter") && !is.null(twitter)) twitter$session$close()
    
    # Devolver el data frame
    return(users_recolectados)
  } else {
    cat("No hay artículos para procesar.\n")
    
    # Cerrar sesiones
    if (exists("urlok") && !is.null(urlok)) urlok$session$close()
    if (open && exists("twitter") && !is.null(twitter)) twitter$session$close()
    
    return(NULL)
  }
}
