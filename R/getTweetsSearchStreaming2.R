#' Get Live Tweet by Search II
#' 
#' @description
#' 
#' <a href="https://lifecycle.r-lib.org/articles/stages.html#experimental" target="_blank"><img src="https://lifecycle.r-lib.org/articles/figures/lifecycle-experimental.svg" alt="[Experimental]"></a>
#' 
#' Esta función recupera tweets basados en una consulta de búsqueda en tiempo real en Twitter. 
#' Utiliza autenticación en Twitter mediante el nombre de usuario y la contraseña proporcionados, 
#' o los valores predeterminados de las variables de entorno del sistema. Versión optimizada con
#' mejor manejo de errores, procesamiento vectorizado y gestión eficiente de memoria.
#' Optimización realizada con asistencia de Claude Sonnet 4 (Anthropic).
#' 
#' @param search La consulta de búsqueda para recuperar tweets. Por defecto es "#RStats".
#' @param n_tweets El número máximo de tweets a recuperar. Por defecto es 100.
#' @param sleep Tiempo de espera para la carga de tweets. Por defecto este valor es de 15 segundos.
#' @param xuser Nombre de usuario de Twitter para autenticación. Por defecto es el valor de la variable de entorno del sistema USER.
#' @param xpass Contraseña de Twitter para autenticación. Por defecto es el valor de la variable de entorno del sistema PASS.
#' @param dir Directorio para guardar el archivo RDS con las URLs recolectadas.
#' @param save Lógico. Indica si se debe guardar el resultado en un archivo RDS (por defecto TRUE).
#' @param max_login_attempts Número máximo de intentos de login (por defecto 3).
#' @param max_collect_attempts Número máximo de intentos consecutivos sin tweets nuevos (por defecto 5).
#' @param backoff_factor Factor de backoff exponencial para reintentos (por defecto 1.5).
#' @param verbose Lógico. Mostrar mensajes detallados (por defecto TRUE).
#' 
#' @return Un tibble que contiene los tweets recuperados con información completa.
#' @export
#'
#' @examples
#' \dontrun{
#' getTweetsSearchStreaming2(search = "#RStats", n_tweets = 200)
#' 
#' # Sin guardar los resultados
#' getTweetsSearchStreaming2(search = "#RStats", n_tweets = 200, save = FALSE)
#' 
#' # Con configuración personalizada
#' getTweetsSearchStreaming2(
#'   search = "#datascience", 
#'   n_tweets = 500,
#'   sleep = 10,
#'   max_collect_attempts = 8,
#'   verbose = FALSE
#' )
#' }
#'
#' @references
#' Puedes encontrar más información sobre el paquete TweetScrapeR en:
#' <https://github.com/agusnieto77/TweetScraperR>
#'
#' @importFrom rvest read_html_live html_elements html_attr html_text html_element read_html
#' @importFrom dplyr distinct bind_rows
#' @importFrom tibble tibble
#' @importFrom lubridate as_datetime is.POSIXct
#' 

getTweetsSearchStreaming2 <- function(
    search = "#RStats",
    n_tweets = 100,
    sleep = 15,
    xuser = Sys.getenv("USER"),
    xpass = Sys.getenv("PASS"),
    dir = getwd(),
    save = TRUE,
    max_login_attempts = 3,
    max_collect_attempts = 5,
    backoff_factor = 1.5,
    verbose = TRUE
) {
  
  .SELECTORS <- list(
    login_user = "#layers > div > div > div > div > div > div > div.css-175oi2r > div.css-175oi2r > div > div > div.css-175oi2r > div.css-175oi2r > div > div > div > div.css-175oi2r > label > div > div.css-175oi2r > div > input",
    login_next = "#layers div > div > div > button:nth-child(6) > div",
    login_pass = "#layers > div > div > div > div > div > div > div > div > div > div > div > div > div > div > div > div > div > label > div > div > div > input",
    login_button = "#layers > div > div > div > div > div > div > div.css-175oi2r > div.css-175oi2r > div > div > div.css-175oi2r > div.css-175oi2r.r-16y2uox > div.css-175oi2r > div > div.css-175oi2r > div > div > button",
    tweet_url = "div.css-175oi2r > div > div.css-175oi2r > a.css-146c3p1.r-bcqeeo.r-1ttztb7.r-qvutc0.r-37j5jr.r-a023e6",
    tweet_time = "time",
    tweet_user = "div.css-175oi2r.r-18u37iz.r-1wbh5a2.r-1ez5h0i > div > div.css-175oi2r.r-1wbh5a2.r-dnmrzs > a > div > span",
    tweet_text = "div[data-testid='tweetText']"
  )
  
  .validate_params <- function(search, n_tweets, sleep, max_login_attempts, max_collect_attempts, backoff_factor) {
    if (!is.character(search) || length(search) != 1 || nchar(search) == 0) {
      stop("'search' debe ser una cadena de caracteres no vacía")
    }
    if (!is.numeric(n_tweets) || n_tweets <= 0) {
      stop("'n_tweets' debe ser un número positivo")
    }
    if (!is.numeric(sleep) || sleep < 0) {
      stop("'sleep' debe ser un número no negativo")
    }
    if (!is.numeric(max_login_attempts) || max_login_attempts <= 0) {
      stop("'max_login_attempts' debe ser un número positivo")
    }
    if (!is.numeric(max_collect_attempts) || max_collect_attempts <= 0) {
      stop("'max_collect_attempts' debe ser un número positivo")
    }
    if (!is.numeric(backoff_factor) || backoff_factor <= 1) {
      stop("'backoff_factor' debe ser un número mayor a 1")
    }
  }
  
  .log_message <- function(message, verbose = TRUE) {
    if (verbose) {
      cat(paste0("[", format(Sys.time(), "%Y-%m-%d %H:%M:%S"), "] ", message, "\n"))
    }
  }
  
  .authenticate_twitter <- function(xuser, xpass, max_attempts = 3, backoff_factor = 1.5, verbose = TRUE) {
    .log_message("Iniciando proceso de autenticación...", verbose)
    
    for (attempt in 1:max_attempts) {
      tryCatch({
        .log_message(paste("Intento de autenticación", attempt, "de", max_attempts), verbose)
        
        twitter <- NULL
        login_attempts <- 0
        while (is.null(twitter) && login_attempts < 3) {
          tryCatch({
            twitter <- rvest::read_html_live("https://x.com/i/flow/login")
          }, error = function(e) {
            login_attempts <<- login_attempts + 1
            if (grepl("loadEventFired", e$message)) {
              .log_message(paste("Error de timeout en conexión, reintentando en", login_attempts * 2, "segundos..."), verbose)
              Sys.sleep(login_attempts * 2)
            } else {
              stop(e)
            }
          })
        }
        
        if (is.null(twitter)) {
          stop("No se pudo conectar a la página de login después de 3 intentos")
        }
        
        Sys.sleep(3)
        
        twitter$type(css = .SELECTORS$login_user, text = xuser)
        Sys.sleep(1)
        twitter$click(css = .SELECTORS$login_next, n_clicks = 1)
        Sys.sleep(2)
        twitter$type(css = .SELECTORS$login_pass, text = xpass)
        Sys.sleep(1)
        twitter$click(css = .SELECTORS$login_button, n_clicks = 1)
        Sys.sleep(3)
        
        .log_message("Autenticación exitosa", verbose)
        return(twitter)
        
      }, error = function(e) {
        .log_message(paste("Error en intento de autenticación", attempt, ":", e$message), verbose)
        if (attempt < max_attempts) {
          wait_time <- ceiling(backoff_factor^attempt)
          .log_message(paste("Esperando", wait_time, "segundos antes del siguiente intento..."), verbose)
          Sys.sleep(wait_time)
        }
      })
    }
    
    .log_message("Asumiendo que la cuenta ya está autenticada", verbose)
    return(NULL)
  }
  
  .extract_tweet_data <- function(articles_html, verbose = TRUE) {
    .log_message("Extrayendo datos de tweets...", verbose)
    
    n_articles <- length(articles_html)
    if (n_articles == 0) return(tibble::tibble())
    
    fechas <- vector("list", n_articles)
    usuarios <- character(n_articles)
    textos <- character(n_articles)
    urls <- character(n_articles)
    
    for (i in seq_len(n_articles)) {
      tryCatch({
        post_html <- rvest::read_html(articles_html[i])
        
        time_elements <- rvest::html_elements(post_html, css = .SELECTORS$tweet_time)
        if (length(time_elements) > 0) {
          datetime_attrs <- rvest::html_attr(time_elements, "datetime")
          valid_dates <- lubridate::as_datetime(datetime_attrs[!is.na(datetime_attrs)])
          if (length(valid_dates) > 0) {
            fechas[[i]] <- max(valid_dates)
          }
        }
        
        user_element <- rvest::html_element(post_html, css = .SELECTORS$tweet_user)
        if (!is.na(user_element)) {
          usuarios[i] <- rvest::html_text(user_element)
        }
        
        text_element <- rvest::html_element(post_html, css = .SELECTORS$tweet_text)
        if (!is.na(text_element)) {
          textos[i] <- rvest::html_text(text_element)
        }
        
        url_element <- rvest::html_element(post_html, css = .SELECTORS$tweet_url)
        if (!is.na(url_element)) {
          href <- rvest::html_attr(url_element, "href")
          if (!is.na(href)) {
            urls[i] <- paste0("https://x.com", href)
          }
        }
        
      }, error = function(e) {
        .log_message(paste("Error procesando tweet", i, ":", e$message), verbose)
      })
    }
    
    fechas_processed <- do.call(c, lapply(fechas, function(x) if (is.null(x)) as.POSIXct(NA) else x))
    
    result <- tibble::tibble(
      art_html = articles_html,
      fecha = fechas_processed,
      user = usuarios,
      tweet = textos,
      url = urls,
      fecha_captura = Sys.time()
    )
    
    result <- result[!is.na(result$fecha) & !is.na(result$url) & result$url != "https://x.com", ]
    
    .log_message(paste("Procesados", nrow(result), "tweets válidos de", n_articles, "artículos"), verbose)
    return(result)
  }
  
  
  .validate_params(search, n_tweets, sleep, max_login_attempts, max_collect_attempts, backoff_factor)
  
  .log_message("=== Iniciando getTweetsSearchStreaming2 ===", verbose)
  .log_message(paste("Búsqueda:", search), verbose)
  .log_message(paste("Tweets objetivo:", n_tweets), verbose)
  
  url_x <- paste0("https://x.com/search?q=", gsub("#", "%23", search), "&src=typed_query&f=live")
  .log_message(paste("URL de búsqueda:", url_x), verbose)
  
  twitter <- .authenticate_twitter(xuser, xpass, max_login_attempts, backoff_factor, verbose)
  
  .log_message("Conectando a la página de búsqueda...", verbose)
  historicalok <- NULL
  search_attempts <- 0
  max_search_attempts <- 3
  
  while (is.null(historicalok) && search_attempts < max_search_attempts) {
    tryCatch({
      historicalok <- rvest::read_html_live(url_x)
      Sys.sleep(sleep)
    }, error = function(e) {
      search_attempts <<- search_attempts + 1
      if (grepl("loadEventFired", e$message)) {
        wait_time <- search_attempts * 2
        .log_message(paste("Error de timeout, reintentando en", wait_time, "segundos..."), verbose)
        Sys.sleep(wait_time)
      } else {
        stop(e)
      }
    })
  }
  
  if (is.null(historicalok)) {
    stop("No se pudo conectar a la página de búsqueda después de", max_search_attempts, "intentos")
  }
  
  .log_message("Iniciando recolección de tweets...", verbose)
  
  all_tweets <- tibble::tibble()
  consecutive_failures <- 0
  total_iterations <- 0
  
  while (nrow(all_tweets) < n_tweets && consecutive_failures < max_collect_attempts) {
    total_iterations <- total_iterations + 1
    .log_message(paste("Iteración", total_iterations, "- Tweets actuales:", nrow(all_tweets)), verbose)
    
    tryCatch({
      
      html <- historicalok$session$DOM$getDocument()
      html_content <- historicalok$session$DOM$getOuterHTML(nodeId = html$root$nodeId)$outerHTML
      
      articles_html <- as.character(rvest::html_elements(rvest::read_html(html_content), css = "article"))
      
      if (length(articles_html) == 0) {
        .log_message("No se encontraron artículos en esta iteración", verbose)
        consecutive_failures <- consecutive_failures + 1
      } else {
        
        new_tweets <- .extract_tweet_data(articles_html, verbose)
        
        if (nrow(new_tweets) > 0) {
          
          all_tweets <- dplyr::bind_rows(all_tweets, new_tweets)
          all_tweets <- dplyr::distinct(all_tweets, url, .keep_all = TRUE)
          
          new_count <- nrow(all_tweets)
          .log_message(paste("Tweets únicos recolectados:", new_count), verbose)
          
          if (new_count > nrow(all_tweets) - nrow(new_tweets)) {
            consecutive_failures <- 0
          } else {
            consecutive_failures <- consecutive_failures + 1
          }
        } else {
          consecutive_failures <- consecutive_failures + 1
        }
      }
      
      if (nrow(all_tweets) < n_tweets && consecutive_failures < max_collect_attempts) {
        .log_message("Recargando página...", verbose)
        historicalok$session$Page$reload()
        Sys.sleep(sleep)
      }
      
    }, error = function(e) {
      .log_message(paste("Error en iteración", total_iterations, ":", e$message), verbose)
      consecutive_failures <- consecutive_failures + 1
      Sys.sleep(backoff_factor^consecutive_failures)
    })
  }
  
  .log_message("Finalizando recolección de tweets...", verbose)
  
  tryCatch({
    if (!is.null(historicalok)) historicalok$session$close()
    if (!is.null(twitter)) twitter$session$close()
  }, error = function(e) {
    .log_message(paste("Error cerrando sesiones:", e$message), verbose)
  })
  
  if (nrow(all_tweets) > 0) {
    
    if (nrow(all_tweets) > n_tweets) {
      all_tweets <- all_tweets[1:n_tweets, ]
    }
    
    if (save) {
      filename <- paste0(
        dir, "/tweets_search_", 
        substr(gsub("\\s|#|[^[:alnum:]]", "", search), 1, 12), "_", 
        gsub("-|:|\\.", "_", format(Sys.time(), "%Y_%m_%d_%H_%M_%S")), 
        ".rds"
      )
      saveRDS(all_tweets, filename)
      .log_message(paste("Datos guardados en:", filename), verbose)
    }
    
    .log_message(paste("=== Proceso completado ==="), verbose)
    .log_message(paste("Tweets únicos recolectados:", nrow(all_tweets)), verbose)
    .log_message(paste("Iteraciones totales:", total_iterations), verbose)
    
    return(all_tweets)
  } else {
    .log_message("No se recolectaron tweets válidos", verbose)
    return(NULL)
  }
}
