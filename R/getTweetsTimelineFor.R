#' Get Tweets from Multiple Users Iteratively
#' 
#' @description
#' 
#' <a href="https://lifecycle.r-lib.org/articles/stages.html#experimental" target="_blank"><img src="https://lifecycle.r-lib.org/articles/figures/lifecycle-experimental.svg" alt="[Experimental]"></a>
#'
#' Esta función recolecta tweets de múltiples usuarios de X (Twitter) de forma iterativa,
#' permitiendo obtener un conjunto de datos combinado con tweets de todos los usuarios especificados.
#'
#' @param usernames Vector de caracteres con los nombres de usuario de X (Twitter) para recolectar tweets.
#' @param n_tweets Número de tweets a recolectar por usuario (por defecto: 10).
#' @param save Booleano que indica si se deben guardar los resultados en un archivo (por defecto: FALSE).
#' @param save_path Ruta del archivo donde guardar los resultados (por defecto: NULL).
#' @param file_format Formato del archivo para guardar los resultados ("rds" o "csv", por defecto: "rds").
#' @param include_user_column Booleano que indica si se debe añadir una columna con el nombre de usuario (por defecto: TRUE).
#' @param dir Directorio para guardar los tweets recolectados (por defecto: directorio de trabajo actual).
#' @param system Sistema operativo ("windows", "unix", o "mac").
#' @param kill_system Booleano que indica si se debe cerrar el navegador después de la recolección (por defecto: FALSE).
#'
#' @details
#' La función realiza las siguientes operaciones:
#' 1. Valida los parámetros de entrada.
#' 2. Crea el directorio de destino si no existe y es necesario.
#' 3. Abre la línea de tiempo de X (Twitter).
#' 4. Itera a través de cada nombre de usuario especificado.
#' 5. Recolecta los tweets de cada usuario utilizando getTweetsTimeline().
#' 6. Añade una columna "cuenta" con el nombre de usuario a cada conjunto de datos.
#' 7. Combina todos los resultados en un único dataframe.
#' 8. Guarda los resultados combinados si se especifica, en formato .rds (por defecto) o .csv.
#'
#' @return
#' Un dataframe que contiene los tweets de todos los usuarios especificados.
#'
#' @examples
#' \dontrun{
#' 
#' # Iniciar sesión
#' openTimeline()
#' 
#' # Recolectar 5 tweets de cada usuario
#' usuarios <- c("S1RSTAT1C", "gregoriosz", "ori_oberman")
#' tweets_df <- getTweetsTimelineFor(
#'   usernames = usuarios, 
#'   n_tweets = 5
#' )
#'
#' # Guardar resultados en formato RDS (por defecto)
#' tweets_df <- getTweetsTimelineFor(
#'   usernames = usuarios,
#'   n_tweets = 10,
#'   save = TRUE,
#'   save_path = "tweets_data.rds"
#' )
#'
#' # Guardar resultados en formato CSV
#' tweets_df <- getTweetsTimelineFor(
#'   usernames = usuarios,
#'   n_tweets = 10,
#'   save = TRUE,
#'   save_path = "tweets_data.csv",
#'   file_format = "csv"
#' )
#' }
#' 
#' @importFrom dplyr mutate
#' @importFrom utils write.csv
#' 
#' @export
#' 

getTweetsTimelineFor <- function(
    usernames, 
    n_tweets = 10, 
    save = FALSE, 
    save_path = NULL,
    file_format = "rds",
    include_user_column = TRUE,
    dir = getwd(), 
    system = "windows", 
    kill_system = FALSE
) {
  
  # Validación de parámetros
  if (!is.character(usernames)) {
    stop("usernames debe ser un vector de caracteres")
  }
  
  if (!is.numeric(n_tweets) || n_tweets < 1) {
    stop("n_tweets debe ser un número entero positivo")
  }
  
  if (!is.logical(save)) {
    stop("save debe ser TRUE o FALSE")
  }
  
  if (!file_format %in% c("rds", "csv")) {
    stop("file_format debe ser 'rds' o 'csv'")
  }
  
  # Determinar la extensión del archivo según el formato
  file_ext <- ifelse(file_format == "rds", ".rds", ".csv")
  
  if (save && is.null(save_path)) {
    default_filename <- paste0("tweets_data", file_ext)
    warning(paste0("save es TRUE pero no se proporcionó save_path. Usando '", default_filename, "' por defecto"))
    save_path <- file.path(dir, default_filename)
  } else if (save) {
    # Asegurarse de que el archivo tenga la extensión correcta
    if (!grepl(paste0(file_ext, "$"), save_path)) {
      save_path <- paste0(save_path, file_ext)
      warning(paste0("Se ha añadido la extensión '", file_ext, "' al nombre del archivo"))
    }
    save_path <- file.path(dir, save_path)
  }
  
  # Crear el directorio si no existe y es necesario
  if (save && !dir.exists(dirname(save_path))) {
    dir.create(dirname(save_path), recursive = TRUE)
  }
  
  # Función para cerrar el navegador según el sistema operativo
  close_browser <- function(system) {
    if (system == "windows") {
      system("taskkill /F /IM chrome.exe", intern = TRUE, ignore.stderr = TRUE)
    } else if (system == "unix") {
      system("pkill chrome")
    } else if (system == "mac") {
      system("pkill -x 'Google Chrome'")
    } else {
      warning("Sistema operativo no reconocido. No se cerrará el navegador.")
    }
  }
  
  # Inicializar dataframe vacío para almacenar resultados
  result_df <- data.frame()
  
  # Iterar a través de cada nombre de usuario
  cat("Iniciando recolección de tweets para", length(usernames), "usuarios\n")
  
  for (i in seq_along(usernames)) {
    username <- usernames[i]
    cat("Procesando usuario", i, "de", length(usernames), ":", username, "\n")
    
    tryCatch({
      # Obtener tweets para el usuario actual
      user_tweets <- TweetScraperR::getTweetsTimeline(
        username = username, 
        n_tweets = n_tweets, 
        save = FALSE  # Manejaremos el guardado de los datos combinados
      )
      
      # Añadir columna de nombre de usuario si se solicita
      if (include_user_column) {
        user_tweets <- user_tweets |> dplyr::mutate(cuenta = username)
      }
      
      # Combinar con el dataframe principal de resultados
      result_df <- rbind(result_df, user_tweets)
      
      cat("  Recolectados", nrow(user_tweets), "tweets\n")
      
    }, error = function(e) {
      warning("Error al procesar el usuario ", username, ": ", conditionMessage(e))
    })
  }
  
  # Guardar resultados combinados si se solicita
  if (save && !is.null(save_path)) {
    if (file_format == "rds") {
      saveRDS(result_df, file = save_path)
      cat("Tweets combinados guardados en formato RDS:", save_path, "\n")
    } else {
      utils::write.csv(result_df, file = save_path, row.names = FALSE)
      cat("Tweets combinados guardados en formato CSV:", save_path, "\n")
    }
  }
  
  # Cerrar el navegador si kill_system es TRUE
  if (kill_system) {
    cat("Cerrando el navegador...\n")
    close_browser(system)
  }
  
  cat("Recolección de tweets completada. Total de tweets:", nrow(result_df), "\n")
  
  return(result_df)
}
