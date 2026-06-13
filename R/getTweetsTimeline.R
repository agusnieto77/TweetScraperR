#' Get Tweets from User Timeline
#'
#' @description
#'
#' <a href="https://lifecycle.r-lib.org/articles/stages.html#experimental" target="_blank"><img src="https://lifecycle.r-lib.org/articles/figures/lifecycle-experimental.svg" alt="[Experimental]"></a>
#'
#' Esta función recupera tweets del timeline de unx usuarix especificadx en Twitter.
#' La función inicia sesión en Twitter utilizando las credenciales proporcionadas,
#' navega al perfil de le usuarix especificadx, y recopila hasta `n_tweets` tweets.
#' El proceso de recolección se detiene si se alcanza el número máximo de tweets
#' especificado o después de alcanzar los 600 tweets con el desplazamiento (scroll).
#'
#' @param username El nombre de usuarix de Twitter del cual quieres obtener el timeline.
#' @param n_tweets El número máximo de tweets a obtener. Por defecto es 100.
#' @param view Mostrar una vista en vivo de Twitter/X TRUE o FALSE
#' @param open Indica si se debe realizar el proceso de autenticación (por defecto FALSE)
#' @param xuser Nombre de usuarix de Twitter para autenticación. Por defecto es el valor de la variable de entorno TWITTER_USER y, si no está definida, el de la variable de entorno del sistema USER.
#' @param xpass Contraseña de Twitter para autenticación. Por defecto es el valor de la variable de entorno TWITTER_PASS y, si no está definida, el de la variable de entorno del sistema PASS.
#' @param mailx Dirección de e-mail para la autenticación. Tiene que ser la misma que la usada en Twitter/X.
#' @param dir El directorio donde se guardará el archivo de salida. Por defecto es el directorio de trabajo actual.
#' @param save Lógico. Indica si se debe guardar el resultado en un archivo RDS (por defecto TRUE).
#' @return Un tibble que contiene los tweets obtenidos.
#' @export
#'
#' @examples
#' \dontrun{
#' getTweetsTimeline(username = "rstatstweet", n_tweets = 200)
#'
#' # Con autenticación
#' getTweetsTimeline(username = "rstatstweet", n_tweets = 200, open = TRUE)
#'
#' # Sin guardar los resultados
#' getTweetsTimeline(username = "rstatstweet", n_tweets = 200, save = FALSE)
#' }
#'
#' @references
#' Puedes encontrar más información sobre el paquete TweetScrapeR en:
#' <https://github.com/agusnieto77/TweetScraperR>
#'
#' @importFrom rvest read_html_live html_elements html_attr html_text
#' @importFrom tibble tibble
#' @importFrom lubridate as_datetime
#' @importFrom dplyr distinct
#'

getTweetsTimeline <- function(
    username = "rstatstweet",
    n_tweets = 100,
    view = FALSE,
    open = FALSE,
    xuser = Sys.getenv("TWITTER_USER", Sys.getenv("USER")),
    xpass = Sys.getenv("TWITTER_PASS", Sys.getenv("PASS")),
    mailx = NULL,
    dir = getwd(),
    save = TRUE
) {
  url <- paste0("https://x.com/", username)
  cat("Inici\u00f3 la recolecci\u00f3n de tweets.\n")

  res <- .pw_collect(url, mode = "articles", n_max = n_tweets, max_attempts = 3)
  if (isTRUE(res$reason == "not_logged_in")) {
    stop("No hay una sesi\u00f3n activa de X. Import\u00e1 tu sesi\u00f3n con importSessionX(auth_token, ct0) antes de scrapear.")
  }
  if (!isTRUE(res$ok)) {
    stop("No se pudo completar la operaci\u00f3n: ", .pw_or(res$error, .pw_or(res$reason, "error desconocido")))
  }
  cat("Finaliz\u00f3 la recolecci\u00f3n de tweets.\n")

  tweets_udb <- .extract_tweet_data(res$items)
  tweets_udb$is_original <- !is.na(tweets_udb$user) & tweets_udb$user == paste0("@", username)
  tweets_udb$is_retweet <- !is.na(tweets_udb$user) & tweets_udb$user != paste0("@", username)
  tweets_udb$is_cita <- is.na(tweets_udb$user)
  .save_rds(tweets_udb, dir, paste0("timeline_", username), save = save)
  return(tweets_udb)
}
