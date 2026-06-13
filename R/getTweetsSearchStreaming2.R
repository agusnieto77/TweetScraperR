#' Get Live Tweet by Search II
#'
#' @description
#'
#' <a href="https://lifecycle.r-lib.org/articles/stages.html#experimental" target="_blank"><img src="https://lifecycle.r-lib.org/articles/figures/lifecycle-experimental.svg" alt="[Experimental]"></a>
#'
#' @description
#' **Obsoleta**: preférí getTweetsSearchAPI(), basada en la API de X (datos del JSON, mas robusta).
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
#' @param xuser Nombre de usuario de Twitter para autenticación. Por defecto es el valor de la variable de entorno TWITTER_USER (o USER si no está definida).
#' @param xpass Contraseña de Twitter para autenticación. Por defecto es el valor de la variable de entorno TWITTER_PASS (o PASS si no está definida).
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
#' @importFrom rvest read_html_live html_elements html_attr html_text html_element
#' @importFrom dplyr distinct bind_rows
#' @importFrom tibble tibble
#' @importFrom lubridate as_datetime is.POSIXct
#'

getTweetsSearchStreaming2 <- function(
    search = "#RStats",
    n_tweets = 100,
    sleep = 15,
    xuser = Sys.getenv("TWITTER_USER", Sys.getenv("USER")),
    xpass = Sys.getenv("TWITTER_PASS", Sys.getenv("PASS")),
    dir = getwd(),
    save = TRUE,
    max_login_attempts = 3,
    max_collect_attempts = 5,
    backoff_factor = 1.5,
    verbose = TRUE
) {
  .Deprecated(msg = "getTweetsSearchStreaming2() est\u00e1 obsoleta: us\u00e1 getTweetsSearchAPI() (basada en la API de X, datos estructurados del JSON, m\u00e1s robusta). Ver ?getTweetsSearchAPI.")

  .validate_params <- function(search, n_tweets, sleep, max_login_attempts, max_collect_attempts, backoff_factor) {
    if (!is.character(search) || length(search) != 1 || nchar(search) == 0) {
      stop("'search' debe ser una cadena de caracteres no vac\u00eda")
    }
    if (!is.numeric(n_tweets) || n_tweets <= 0) {
      stop("'n_tweets' debe ser un n\u00famero positivo")
    }
    if (!is.numeric(sleep) || sleep < 0) {
      stop("'sleep' debe ser un n\u00famero no negativo")
    }
    if (!is.numeric(max_login_attempts) || max_login_attempts <= 0) {
      stop("'max_login_attempts' debe ser un n\u00famero positivo")
    }
    if (!is.numeric(max_collect_attempts) || max_collect_attempts <= 0) {
      stop("'max_collect_attempts' debe ser un n\u00famero positivo")
    }
    if (!is.numeric(backoff_factor) || backoff_factor <= 1) {
      stop("'backoff_factor' debe ser un n\u00famero mayor a 1")
    }
  }

  .log_message <- function(message, verbose = TRUE) {
    if (verbose) {
      cat(paste0("[", format(Sys.time(), "%Y-%m-%d %H:%M:%S"), "] ", message, "\n"))
    }
  }

  .validate_params(search, n_tweets, sleep, max_login_attempts, max_collect_attempts, backoff_factor)

  .log_message("=== Iniciando getTweetsSearchStreaming2 ===", verbose)
  .log_message(paste("B\u00fasqueda:", search), verbose)
  .log_message(paste("Tweets objetivo:", n_tweets), verbose)

  url_x <- paste0("https://x.com/search?q=", gsub("#", "%23", search), "&src=typed_query&f=live")
  .log_message(paste("URL de b\u00fasqueda:", url_x), verbose)

  twitter <- NULL
  historicalok <- NULL
  on.exit(.close_sessions(historicalok, twitter), add = TRUE)

  .log_message("Iniciando proceso de autenticaci\u00f3n...", verbose)
  twitter <- tryCatch({
    .x_login(xuser, xpass, max_attempts = max_login_attempts)
  }, error = function(e) {
    .log_message(paste("Error en intento de autenticaci\u00f3n:", conditionMessage(e)), verbose)
    .log_message("Asumiendo que la cuenta ya est\u00e1 autenticada", verbose)
    NULL
  })

  .log_message("Conectando a la p\u00e1gina de b\u00fasqueda...", verbose)
  historicalok <- .read_html_live_retry(url_x, max_tries = 3)
  Sys.sleep(sleep)

  .log_message("Iniciando recolecci\u00f3n de tweets...", verbose)

  all_tweets <- tibble::tibble()
  consecutive_failures <- 0
  total_iterations <- 0

  while (nrow(all_tweets) < n_tweets && consecutive_failures < max_collect_attempts) {
    total_iterations <- total_iterations + 1
    .log_message(paste("Iteraci\u00f3n", total_iterations, "- Tweets actuales:", nrow(all_tweets)), verbose)

    ok <- tryCatch({

      html <- historicalok$session$DOM$getDocument()
      html_content <- historicalok$session$DOM$getOuterHTML(nodeId = html$root$nodeId)$outerHTML

      articles_html <- as.character(rvest::html_elements(rvest::read_html(html_content), css = .sel$article))

      if (length(articles_html) == 0) {
        .log_message("No se encontraron art\u00edculos en esta iteraci\u00f3n", verbose)
        consecutive_failures <- consecutive_failures + 1
      } else {

        .log_message("Extrayendo datos de tweets...", verbose)
        new_tweets <- .extract_tweet_data(articles_html)
        .log_message(paste("Procesados", nrow(new_tweets), "tweets v\u00e1lidos de", length(articles_html), "art\u00edculos"), verbose)

        if (nrow(new_tweets) > 0) {

          count_before <- nrow(all_tweets)
          all_tweets <- dplyr::bind_rows(all_tweets, new_tweets)
          all_tweets <- dplyr::distinct(all_tweets, url, .keep_all = TRUE)

          new_count <- nrow(all_tweets)
          .log_message(paste("Tweets \u00fanicos recolectados:", new_count), verbose)

          if (new_count > count_before) {
            consecutive_failures <- 0
          } else {
            consecutive_failures <- consecutive_failures + 1
          }
        } else {
          consecutive_failures <- consecutive_failures + 1
        }
      }

      if (nrow(all_tweets) < n_tweets && consecutive_failures < max_collect_attempts) {
        .log_message("Recargando p\u00e1gina...", verbose)
        historicalok$session$Page$reload()
        Sys.sleep(sleep)
      }
      TRUE

    }, error = function(e) {
      .log_message(paste("Error en iteraci\u00f3n", total_iterations, ":", e$message), verbose)
      FALSE
    })
    if (!ok) {
      consecutive_failures <- consecutive_failures + 1
      Sys.sleep(backoff_factor^consecutive_failures)
    }
  }

  .log_message("Finalizando recolecci\u00f3n de tweets...", verbose)

  .close_sessions(historicalok, twitter)

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
    .log_message(paste("Tweets \u00fanicos recolectados:", nrow(all_tweets)), verbose)
    .log_message(paste("Iteraciones totales:", total_iterations), verbose)

    return(all_tweets)
  } else {
    .log_message("No se recolectaron tweets v\u00e1lidos", verbose)
    return(NULL)
  }
}
