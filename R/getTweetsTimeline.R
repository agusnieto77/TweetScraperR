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
#' @param xuser Nombre de usuarix de Twitter para autenticación. Por defecto es el valor de la variable de entorno del sistema USER.
#' @param xpass Contraseña de Twitter para autenticación. Por defecto es el valor de la variable de entorno del sistema PASS.
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
    xuser = Sys.getenv("USER"),
    xpass = Sys.getenv("PASS"),
    mailx = NULL,
    dir = getwd(),
    save = TRUE
) {
  if (open) {
    TweetScraperR::openTwitter(view = view)
    Sys.sleep(3)
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
    mailtext <- "#layers > div> div > div > div > div > div > div > div > div > div > div > div > div > div > div > label > div > div > div > span"
    email_address <- tryCatch({rvest::html_text(twitter$html_elements(css = mailtext))}, error = function(e) {e$message
      return(NULL)
    })
    mailbox <- "#layers > div > div > div > div > div > div > div > div > div > div > div > div > div > div > div > label > div > div > div > input"
    nextx2 <- "#layers > div > div > div > div > div > div > div > div > div > div > div > div > div > div > div > div > button > div"
    if (!is.null(email_address)) {
      twitter$type(css = mailbox, text = mailx)
      twitter$click(css = nextx2, n_clicks = 1)
    }
    Sys.sleep(2)
  }
  
  fech <- "div > div > div > a > time"
  user1 <- "div.css-175oi2r.r-18u37iz.r-1wbh5a2.r-1ez5h0i > div > div.css-175oi2r.r-1wbh5a2.r-dnmrzs > a > div > span"
  tweet <- "#react-root > div > div > div.css-175oi2r.r-1f2l425.r-13qz1uu.r-417010.r-18u37iz > main > div > div > div > div > div > div:nth-child(3) > div > div > section > div > div > div > div > div > article > div > div > div.css-175oi2r.r-18u37iz > div.css-175oi2r.r-1iusvr4.r-16y2uox.r-1777fci.r-kzbkwu > div:nth-child(2)"
  url_tweet <- "div.css-175oi2r.r-18u37iz.r-1wbh5a2.r-1ez5h0i > div > div.css-175oi2r.r-18u37iz.r-1q142lx > a"
  user2 <- "div.css-175oi2r.r-18u37iz.r-1wbh5a2.r-1ez5h0i > div > div.css-175oi2r.r-18u37iz.r-1q142lx > div > a"
  
  timeline <- rvest::read_html_live(paste0("https://x.com/", username))
  
  assign("timeline", timeline, envir = .GlobalEnv)
  
  if (view) {
    timeline$view()
  } else {
    timeline
  }
  
  Sys.sleep(3)
  tweets_udb <- tibble::tibble()
  i <- 1
  repetitions <- 0
  max_repetitions <- 3
  prev_count <- -1
  cat("Inició la recolección de tweets.\n")
  while (TRUE) {
    if (nrow(tweets_udb) > n_tweets || repetitions >= max_repetitions) {
      cat("Finalizó la recolección de tweets.\n")
      break
    }
    i_tweets <- tibble::tibble(
      fecha = lubridate::as_datetime(rvest::html_attr(timeline$html_elements(css = fech), "datetime")),
      usern = rvest::html_text(timeline$html_elements(css = user1)),
      tweet = rvest::html_text(timeline$html_elements(css = tweet)),
      url = rvest::html_attr(timeline$html_elements(css = paste(url_tweet, user2, sep = ", ")), "href"),
      fecha_captura = Sys.time()
    )
    new_count <- nrow(i_tweets)
    if (new_count == prev_count) {
      repetitions <- repetitions + 1
    } else {
      repetitions <- 0
    }
    if (repetitions >= max_repetitions) {
      cat("Finalizó la recolección de tweets.")
      break
    }
    tweets_udb <- dplyr::distinct(rbind(tweets_udb, i_tweets), url, .keep_all = TRUE)
    prev_count <- new_count
    timeline$scroll_by(top = 4000, left = 0)
    message("Tweets recolectados: ", nrow(tweets_udb))
    Sys.sleep(2.5)
  }
  if (open) { timeline$session$close() }
  if (open) { rm(timeline, envir = .GlobalEnv) }
  tweets_udb$url <- paste0("https://x.com", tweets_udb$url)
  tweets_udb$is_original <- tweets_udb$usern == paste0("@", username)
  tweets_udb$is_retweet <- !is.na(tweets_udb$usern) & tweets_udb$usern != paste0("@", username)
  tweets_udb$is_cita <- is.na(tweets_udb$usern)
  if (save) {
    saveRDS(tweets_udb, paste0(dir, "/timeline_", username, "_", gsub("-|:|\\.", "_", format(Sys.time(), "%Y_%m_%d_%X")), ".rds"))
    cat("Datos procesados y guardados.\n")
  } else {
    cat("Datos procesados. No se han guardado en un archivo RDS.\n")
  }
  return(tweets_udb)
}
