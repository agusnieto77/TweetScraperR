#' Get Iterative Tweets in Streaming II
#'
#' @description
#' 
#' <a href="https://lifecycle.r-lib.org/articles/stages.html#experimental" target="_blank"><img src="https://lifecycle.r-lib.org/articles/figures/lifecycle-experimental.svg" alt="[Experimental]"></a>
#' 
#' Esta funci\u00f3n recolecta tweets de forma iterativa utilizando la funci\u00f3n optimizada
#' getTweetsSearchStreaming2, con manejo robusto de errores, seguimiento de progreso,
#' unificaci\u00f3n de datos y gesti\u00f3n eficiente de recursos del sistema.
#' Optimizaci\u00f3n realizada con asistencia de Claude Sonnet 4 (Anthropic).
#'
#' @param iterations N\u00famero de iteraciones a realizar
#' @param search T\u00e9rmino de b\u00fasqueda para los tweets
#' @param n_tweets N\u00famero de tweets a recolectar en cada iteraci\u00f3n
#' @param sleep Tiempo de espera para la carga de tweets. Por defecto este valor es de 15 segundos.
#' @param xuser Nombre de usuario de Twitter para autenticaci\u00f3n. Por defecto es el valor de la variable de entorno del sistema USER.
#' @param xpass Contrase\u00f1a de Twitter para autenticaci\u00f3n. Por defecto es el valor de la variable de entorno del sistema PASS.
#' @param dir Directorio donde se guardar\u00e1n los tweets
#' @param system Sistema operativo ('windows', 'unix', 'macOS')
#' @param kill_system Booleano que indica si se debe cerrar el navegador despu\u00e9s de cada iteraci\u00f3n (por defecto: FALSE)
#' @param sleep_time Tiempo de espera entre iteraciones en segundos. Por defecto este valor es de 300 segundos.
#' @param max_retries N\u00famero m\u00e1ximo de reintentos por iteraci\u00f3n (por defecto: 3)
#' @param backoff_factor Factor de backoff exponencial entre reintentos (por defecto: 2)
#' @param consolidate_data Booleano para unificar todos los datos en un \u00fanico archivo al final (por defecto: TRUE)
#' @param cleanup_individual Booleano para eliminar archivos individuales despu\u00e9s de unificar (por defecto: FALSE)
#' @param verbose Booleano para mostrar mensajes detallados (por defecto: TRUE)
#' @param progress_file Archivo para guardar el progreso de la recolecci\u00f3n (por defecto: NULL)
#' @param resume_from Iteraci\u00f3n desde la cual resumir la recolecci\u00f3n (por defecto: 1)
#'
#' @return Lista con estad\u00edsticas de la recolecci\u00f3n y ruta del archivo unificado (si aplica)
#' @export
#'
#' @examples
#' \dontrun{
#' # Uso b\u00e1sico
#' result <- getTweetsSearchStreamingFor2(
#'   iterations = 5,
#'   search = "Milei",
#'   n_tweets = 100,
#'   dir = "./data/tweets"
#' )
#' 
#' # Uso avanzado con opciones de recuperaci\u00f3n
#' result <- getTweetsSearchStreamingFor2(
#'   iterations = 10,
#'   search = "#datascience",
#'   n_tweets = 200,
#'   dir = "./data/tweets",
#'   system = "unix",
#'   kill_system = TRUE,
#'   sleep_time = 600,
#'   max_retries = 5,
#'   consolidate_data = TRUE,
#'   cleanup_individual = TRUE,
#'   progress_file = "./progress.rds",
#'   verbose = TRUE
#' )
#' 
#' # Resumir recolecci\u00f3n desde iteraci\u00f3n espec\u00edfica
#' result <- getTweetsSearchStreamingFor2(
#'   iterations = 10,
#'   search = "#RStats",
#'   n_tweets = 150,
#'   dir = "./data/tweets",
#'   resume_from = 6,
#'   progress_file = "./progress.rds"
#' )
#' }
#'
#' @references
#' Puedes encontrar m\u00e1s informaci\u00f3n sobre el paquete TweetScrapeR en:
#' <https://github.com/agusnieto77/TweetScraperR>
#' 
#' Funci\u00f3n optimizada con asistencia de Claude Sonnet 4 (Anthropic, 2025).
#' Optimizaciones incluyen: manejo robusto de errores, seguimiento de progreso,
#' unificaci\u00f3n de datos, y gesti\u00f3n eficiente de recursos del sistema.
#'
#' @importFrom dplyr bind_rows distinct
#' @importFrom tibble tibble
#' @importFrom lubridate now
#' 

getTweetsSearchStreamingFor2 <- function(
    iterations,
    search,
    n_tweets,
    sleep = 15,
    xuser = Sys.getenv("USER"),
    xpass = Sys.getenv("PASS"),
    dir = getwd(),
    system = "unix",
    kill_system = FALSE,
    sleep_time = 300,
    max_retries = 3,
    backoff_factor = 2,
    consolidate_data = TRUE,
    cleanup_individual = FALSE,
    verbose = TRUE,
    progress_file = NULL,
    resume_from = 1
) {
  
  .create_safe_directory_name <- function(search, timestamp = NULL) {

    clean_search <- gsub("[^[:alnum:]_]", "_", search)
    clean_search <- gsub("_+", "_", clean_search) 
    clean_search <- gsub("^_|_$", "", clean_search) 
    
    if (is.null(timestamp)) {
      timestamp <- format(Sys.time(), "%Y_%m_%d_%H_%M_%S")
    }
    
    dir_name <- paste0(clean_search, "_", timestamp)
    
    return(dir_name)
  }
  
  .log_iterative <- function(message, verbose = TRUE, level = "INFO") {
    if (verbose) {
      timestamp <- format(Sys.time(), "%Y-%m-%d %H:%M:%S")
      cat(paste0("[", timestamp, "] [", level, "] ", message, "\n"))
    }
  }
  
  .validate_iterative_params <- function(iterations, search, n_tweets, sleep, sleep_time, max_retries, backoff_factor, resume_from) {
    if (!is.numeric(iterations) || iterations <= 0) {
      stop("'iterations' debe ser un n\u00famero positivo")
    }
    if (!is.character(search) || length(search) != 1 || nchar(search) == 0) {
      stop("'search' debe ser una cadena de caracteres no vac\u00eda")
    }
    if (!is.numeric(n_tweets) || n_tweets <= 0) {
      stop("'n_tweets' debe ser un n\u00famero positivo")
    }
    if (!is.numeric(sleep) || sleep < 0) {
      stop("'sleep' debe ser un n\u00famero no negativo")
    }
    if (!is.numeric(sleep_time) || sleep_time < 0) {
      stop("'sleep_time' debe ser un n\u00famero no negativo")
    }
    if (!is.numeric(max_retries) || max_retries <= 0) {
      stop("'max_retries' debe ser un n\u00famero positivo")
    }
    if (!is.numeric(backoff_factor) || backoff_factor <= 1) {
      stop("'backoff_factor' debe ser un n\u00famero mayor a 1")
    }
    if (!is.numeric(resume_from) || resume_from < 1 || resume_from > iterations) {
      stop("'resume_from' debe ser un n\u00famero entre 1 y iterations")
    }
  }
  
  .close_browser_system <- function(system, verbose = TRUE) {
    .log_iterative("Cerrando navegador...", verbose)
    
    tryCatch({
      if (system == "windows") {

        system("taskkill /F /IM chrome.exe 2>NUL", intern = FALSE, ignore.stderr = TRUE)
        system("taskkill /F /IM msedge.exe 2>NUL", intern = FALSE, ignore.stderr = TRUE)
        system("taskkill /F /IM chromedriver.exe 2>NUL", intern = FALSE, ignore.stderr = TRUE)
      } else if (system == "unix") {

        system("pkill -f chrome 2>/dev/null || true")
        system("pkill -f chromium 2>/dev/null || true")
        system("pkill -f chromedriver 2>/dev/null || true")
      } else if (system == "macOS" || system == "mac") {

        system("pkill -x 'Google Chrome' 2>/dev/null || true")
        system("pkill -x 'Chromium' 2>/dev/null || true")
        system("pkill -f chromedriver 2>/dev/null || true")
      } else {
        .log_iterative("Sistema operativo no reconocido. No se cerrar\u00e1 el navegador.", verbose, "WARN")
        return(FALSE)
      }
      
      Sys.sleep(2)  
      .log_iterative("Navegador cerrado exitosamente", verbose)
      return(TRUE)
      
    }, error = function(e) {
      .log_iterative(paste("Error cerrando navegador:", e$message), verbose, "ERROR")
      return(FALSE)
    })
  }
  
  .save_progress <- function(progress_file, iteration, total_iterations, collected_tweets, failed_iterations, verbose = TRUE) {
    if (!is.null(progress_file)) {
      tryCatch({
        progress_data <- list(
          timestamp = Sys.time(),
          current_iteration = iteration,
          total_iterations = total_iterations,
          collected_tweets = collected_tweets,
          failed_iterations = failed_iterations,
          completion_percentage = round((iteration / total_iterations) * 100, 2)
        )
        saveRDS(progress_data, progress_file)
        .log_iterative(paste("Progreso guardado en:", progress_file), verbose)
      }, error = function(e) {
        .log_iterative(paste("Error guardando progreso:", e$message), verbose, "ERROR")
      })
    }
  }
  
  .load_progress <- function(progress_file, verbose = TRUE) {
    if (!is.null(progress_file) && file.exists(progress_file)) {
      tryCatch({
        progress_data <- readRDS(progress_file)
        .log_iterative(paste("Progreso cargado desde:", progress_file), verbose)
        .log_iterative(paste("\u00daltima iteraci\u00f3n completada:", progress_data$current_iteration), verbose)
        return(progress_data)
      }, error = function(e) {
        .log_iterative(paste("Error cargando progreso:", e$message), verbose, "ERROR")
        return(NULL)
      })
    }
    return(NULL)
  }
  
  .consolidate_tweet_data <- function(dir, search, cleanup_individual = FALSE, verbose = TRUE) {
    .log_iterative("Iniciando unificaci\u00f3n de datos...", verbose)
    
    search_pattern <- paste0("tweets_search_", substr(gsub("\\s|#|[^[:alnum:]]", "", search), 1, 12))
    tweet_files <- list.files(dir, pattern = paste0(search_pattern, "_.*\\.rds$"), full.names = TRUE)
    
    if (length(tweet_files) == 0) {
      .log_iterative("No se encontraron archivos de tweets para unificar", verbose, "WARN")
      return(NULL)
    }
    
    .log_iterative(paste("Encontrados", length(tweet_files), "archivos para unificar"), verbose)
    
    all_data <- list()
    successful_files <- character()
    
    for (i in seq_along(tweet_files)) {
      tryCatch({
        data <- readRDS(tweet_files[i])
        if (!is.null(data) && nrow(data) > 0) {
          all_data[[i]] <- data
          successful_files <- c(successful_files, tweet_files[i])
          .log_iterative(paste("Cargado archivo", basename(tweet_files[i]), "con", nrow(data), "tweets"), verbose)
        }
      }, error = function(e) {
        .log_iterative(paste("Error cargando archivo", basename(tweet_files[i]), ":", e$message), verbose, "ERROR")
      })
    }
    
    if (length(all_data) == 0) {
      .log_iterative("No se pudieron cargar datos v\u00e1lidos para unificar", verbose, "ERROR")
      return(NULL)
    }
    
    consolidated_data <- dplyr::bind_rows(all_data)
    
    original_count <- nrow(consolidated_data)
    consolidated_data <- dplyr::distinct(consolidated_data, url, .keep_all = TRUE)
    final_count <- nrow(consolidated_data)
    
    .log_iterative(paste("Datos unificados:", original_count, "tweets \u2192", final_count, "tweets \u00fanicos"), verbose)
    
    timestamp <- format(Sys.time(), "%Y_%m_%d_%H_%M_%S")
    consolidated_filename <- paste0(dir, "/tweets_unificados_", search_pattern, "_", timestamp, ".rds")
    
    tryCatch({
      saveRDS(consolidated_data, consolidated_filename)
      .log_iterative(paste("Archivo unificado guardado:", basename(consolidated_filename)), verbose)
      
      if (cleanup_individual && length(successful_files) > 0) {
        .log_iterative("Eliminando archivos individuales...", verbose)
        for (file in successful_files) {
          tryCatch({
            file.remove(file)
            .log_iterative(paste("Eliminado:", basename(file)), verbose)
          }, error = function(e) {
            .log_iterative(paste("Error eliminando", basename(file), ":", e$message), verbose, "ERROR")
          })
        }
      }
      
      return(list(
        file_path = consolidated_filename,
        total_tweets = final_count,
        files_processed = length(successful_files)
      ))
      
    }, error = function(e) {
      .log_iterative(paste("Error guardando archivo unificado:", e$message), verbose, "ERROR")
      return(NULL)
    })
  }
  
  
  .validate_iterative_params(iterations, search, n_tweets, sleep, sleep_time, max_retries, backoff_factor, resume_from)
  
  .log_iterative("=== Iniciando getTweetsSearchStreamingFor2 ===", verbose)
  .log_iterative(paste("Configuraci\u00f3n: Iteraciones:", iterations, "| B\u00fasqueda:", search, "| Tweets por iteraci\u00f3n:", n_tweets), verbose)
  
  session_timestamp <- format(Sys.time(), "%Y_%m_%d_%H_%M_%S")
  
  safe_dir_name <- .create_safe_directory_name(search, session_timestamp)
  full_dir_path <- file.path(dir, safe_dir_name)
  
  if (!dir.exists(full_dir_path)) {
    dir.create(full_dir_path, recursive = TRUE)
    .log_iterative(paste("Directorio creado:", full_dir_path), verbose)
  }
  
  if (!is.null(progress_file)) {
    progress_file <- file.path(full_dir_path, basename(progress_file))
  }
  
  previous_progress <- .load_progress(progress_file, verbose)
  
  start_time <- Sys.time()
  successful_iterations <- 0
  failed_iterations <- character()
  total_tweets_collected <- 0
  iteration_stats <- tibble::tibble(
    iteration = integer(),
    tweets_collected = integer(),
    success = logical(),
    duration_seconds = numeric(),
    error_message = character()
  )
  
  for (i in resume_from:iterations) {
    iteration_start <- Sys.time()
    .log_iterative(paste("=== ITERACI\u00d3N", i, "de", iterations, "==="), verbose)
    
    iteration_success <- FALSE
    tweets_this_iteration <- 0
    error_message <- ""
    
    for (attempt in 1:max_retries) {
      if (attempt > 1) {
        wait_time <- ceiling(backoff_factor^(attempt-1))
        .log_iterative(paste("Intento", attempt, "de", max_retries, "- Esperando", wait_time, "segundos..."), verbose)
        Sys.sleep(wait_time)
      }
      
      tryCatch({
        .log_iterative(paste("Ejecutando getTweetsSearchStreaming2 (intento", attempt, ")"), verbose)
        
        result <- getTweetsSearchStreaming2(
          search = search,
          n_tweets = n_tweets,
          sleep = sleep,
          xuser = xuser,
          xpass = xpass,
          dir = full_dir_path,
          save = TRUE,
          verbose = verbose
        )
        
        if (!is.null(result) && nrow(result) > 0) {
          tweets_this_iteration <- nrow(result)
          total_tweets_collected <- total_tweets_collected + tweets_this_iteration
          successful_iterations <- successful_iterations + 1
          iteration_success <- TRUE
          
          .log_iterative(paste("Iteraci\u00f3n", i, "exitosa:", tweets_this_iteration, "tweets recolectados"), verbose)
          break  
        } else {
          error_message <- "No se recolectaron tweets v\u00e1lidos"
          .log_iterative(paste("Intento", attempt, "fall\u00f3: No se recolectaron tweets"), verbose, "WARN")
        }
        
      }, error = function(e) {
        error_message <<- e$message
        .log_iterative(paste("Error en intento", attempt, ":", e$message), verbose, "ERROR")
      })
    }
    
    iteration_duration <- as.numeric(difftime(Sys.time(), iteration_start, units = "secs"))
    iteration_stats <- dplyr::bind_rows(iteration_stats, tibble::tibble(
      iteration = i,
      tweets_collected = tweets_this_iteration,
      success = iteration_success,
      duration_seconds = iteration_duration,
      error_message = error_message
    ))
    
    if (!iteration_success) {
      failed_iterations <- c(failed_iterations, i)
      .log_iterative(paste("Iteraci\u00f3n", i, "fall\u00f3 despu\u00e9s de", max_retries, "intentos"), verbose, "ERROR")
    }
    
    if (kill_system) {
      .close_browser_system(system, verbose)
    }
    
    .save_progress(progress_file, i, iterations, total_tweets_collected, failed_iterations, verbose)
    
    if (i < iterations) {
      .log_iterative(paste("Esperando", sleep_time, "segundos antes de la pr\u00f3xima iteraci\u00f3n..."), verbose)
      Sys.sleep(sleep_time)
    }
  }
  
  total_duration <- as.numeric(difftime(Sys.time(), start_time, units = "mins"))
  success_rate <- round((successful_iterations / iterations) * 100, 2)
  
  .log_iterative("=== RECOLECCI\u00d3N COMPLETADA ===", verbose)
  .log_iterative(paste("Iteraciones exitosas:", successful_iterations, "de", iterations, paste0("(", success_rate, "%)")), verbose)
  .log_iterative(paste("Total de tweets recolectados:", total_tweets_collected), verbose)
  .log_iterative(paste("Duraci\u00f3n total:", round(total_duration, 2), "minutos"), verbose)
  .log_iterative(paste("Datos guardados en:", full_dir_path), verbose)
  
  if (length(failed_iterations) > 0) {
    .log_iterative(paste("Iteraciones fallidas:", paste(failed_iterations, collapse = ", ")), verbose, "WARN")
  }
  
  consolidated_result <- NULL
  if (consolidate_data && successful_iterations > 0) {
    .log_iterative("Iniciando unificaci\u00f3n de datos...", verbose)
    consolidated_result <- .consolidate_tweet_data(full_dir_path, search, cleanup_individual, verbose)
  }
  
  if (!is.null(progress_file) && file.exists(progress_file) && resume_from == 1) {
    tryCatch({
      file.remove(progress_file)
      .log_iterative("Archivo de progreso eliminado tras completar recolecci\u00f3n", verbose)
    }, error = function(e) {
      .log_iterative(paste("Error eliminando archivo de progreso:", e$message), verbose, "ERROR")
    })
  }
  
  return(list(
    summary = list(
      total_iterations = iterations,
      successful_iterations = successful_iterations,
      failed_iterations = failed_iterations,
      success_rate_percent = success_rate,
      total_tweets_collected = total_tweets_collected,
      total_duration_minutes = round(total_duration, 2),
      start_time = start_time,
      end_time = Sys.time(),
      output_directory = full_dir_path,
      directory_name = safe_dir_name
    ),
    iteration_details = iteration_stats,
    consolidated_file = if (!is.null(consolidated_result)) consolidated_result$file_path else NULL,
    consolidated_stats = consolidated_result
  ))
}
