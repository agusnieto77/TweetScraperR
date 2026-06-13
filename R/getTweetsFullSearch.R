#' Get Tweets from a Full Search
#'
#' @description
#'
#' <a href="https://lifecycle.r-lib.org/articles/stages.html#experimental" target="_blank"><img src="https://lifecycle.r-lib.org/articles/figures/lifecycle-experimental.svg" alt="[Experimental]"></a>
#'
#' Esta función realiza una búsqueda avanzada de tweets en Twitter (X) utilizando
#' varios criterios de búsqueda y recolecta los tweets que coinciden con estos criterios.
#'
#' @param search_all Cadena de texto. Busca tweets que contengan todas estas palabras (por defecto "R Project").
#' @param search_exact Cadena de texto. Busca tweets que contengan esta frase exacta (por defecto NULL).
#' @param search_any Cadena de texto. Busca tweets que contengan cualquiera de estas palabras (por defecto NULL).
#' @param no_search Cadena de texto. Excluye tweets que contengan estas palabras (por defecto NULL).
#' @param hashtag Cadena de texto. Busca tweets con estos hashtags (por defecto NULL).
#' @param lan Cadena de texto. Filtra tweets por idioma (por defecto NULL).
#' @param from Cadena de texto. Busca tweets de estos usuarios (por defecto NULL).
#' @param to Cadena de texto. Busca tweets dirigidos a estos usuarios (por defecto NULL).
#' @param men Cadena de texto. Busca tweets que mencionan a estos usuarios (por defecto NULL).
#' @param rep Número entero. Número mínimo de respuestas que debe tener un tweet (por defecto 0).
#' @param fav Número entero. Número mínimo de favoritos que debe tener un tweet (por defecto 0).
#' @param rt Número entero. Número mínimo de retweets que debe tener un tweet (por defecto 0).
#' @param timeout Número entero. Tiempo de espera en segundos entre solicitudes (por defecto 10).
#' @param n_tweets Número entero. Número máximo de tweets a recolectar (por defecto 100).
#' @param since Fecha. Fecha de inicio para la búsqueda (por defecto 7 días antes de la fecha actual).
#' @param until Fecha. Fecha de fin para la búsqueda (por defecto la fecha actual).
#' @param xuser Cadena de texto. Nombre de usuario para la autenticación en Twitter (por defecto se toma de la variable de entorno TWITTER_USER o, en su defecto, USER).
#' @param xpass Cadena de texto. Contraseña para la autenticación en Twitter (por defecto se toma de la variable de entorno TWITTER_PASS o, en su defecto, PASS).
#' @param dir Cadena de texto. Directorio donde se guardarán los resultados (por defecto el directorio de trabajo actual).
#' @param save Lógico. Indica si se debe guardar el resultado en un archivo RDS (por defecto TRUE).
#'
#' @return Un tibble con los tweets recolectados, incluyendo las columnas:
#'   \item{art_html}{HTML del artículo del tweet}
#'   \item{fecha}{Fecha y hora del tweet}
#'   \item{user}{Nombre de usuario del autor del tweet}
#'   \item{tweet}{Texto del tweet}
#'   \item{url}{URL del tweet}
#'   \item{fecha_captura}{Fecha y hora de la captura del tweet}
#'
#' @details
#' La función primero intenta autenticarse en Twitter utilizando las credenciales proporcionadas.
#' Luego, construye una URL de búsqueda basada en los parámetros proporcionados y realiza la búsqueda.
#' Los tweets se recolectan iterativamente, scrolleando la página hasta que se alcance el número
#' deseado de tweets o se agoten los intentos.
#' Los tweets recolectados se procesan para extraer la información relevante y, si save es TRUE,
#' se guardan en un archivo RDS.
#'
#' @note
#' Esta función requiere una conexión a Internet y credenciales válidas de Twitter.
#'
#' @export
#'
#' @examples
#' \dontrun{
#' tweets <- getTweetsFullSearch(
#'   search_all = "clima cambio",
#'   hashtag = "#medioambiente",
#'   lan = "es",
#'   n_tweets = 100,
#'   since = Sys.Date() - 30,
#'   save = TRUE
#' )
#'
#' # Sin guardar los resultados
#' tweets <- getTweetsFullSearch(
#'   search_all = "clima cambio",
#'   hashtag = "#medioambiente",
#'   lan = "es",
#'   n_tweets = 100,
#'   since = Sys.Date() - 30,
#'   save = FALSE
#' )
#' }
#'
#' @importFrom rvest read_html_live html_elements html_attr html_text html_element
#' @importFrom lubridate as_datetime is.POSIXct
#' @importFrom tibble tibble
#' @importFrom dplyr distinct
#'

getTweetsFullSearch <- function(
    search_all = "R Project",
    search_exact = NULL,
    search_any = NULL,
    no_search = NULL,
    hashtag = NULL,
    lan = NULL,
    from = NULL,
    to = NULL,
    men = NULL,
    rep = 0,
    fav = 0,
    rt = 0,
    timeout = 10,
    n_tweets = 100,
    since = Sys.Date()-7,
    until = Sys.Date(),
    xuser = Sys.getenv("TWITTER_USER", Sys.getenv("USER")),
    xpass = Sys.getenv("TWITTER_PASS", Sys.getenv("PASS")),
    dir = getwd(),
    save = TRUE
) {
  search_all <- ifelse(nchar(search_all)<1, "", paste0(gsub(" ", "%20", search_all), "%20"))
  search_exact <- ifelse(is.null(search_exact), "", paste0("%22", gsub(" ", "%20", search_exact), "%22", "%20"))
  search_any <- ifelse(is.null(search_any), "", paste0("(", gsub(" ", "%20OR%20", search_any), ")", "%20"))
  no_search <- ifelse(is.null(no_search), "", paste0(gsub(" ", "%20", gsub("(\\w+)", "-\\1", no_search)), "%20"))
  hashtag <- ifelse(is.null(hashtag), "", paste0("(", gsub(" ", "%20OR%20", gsub("(\\w+)", "%23\\1", gsub("#", "", hashtag))), ")", "%20"))
  lan <- ifelse(is.null(lan), "", paste0("%20lang%3A", lan))
  from <- ifelse(is.null(from), "", paste0("(", gsub(" ", "%20OR%20", gsub("(\\w+)", "from%3A\\1", gsub("@", "", from))), ")", "%20"))
  to <- ifelse(is.null(to), "", paste0("(", gsub(" ", "%20OR%20", gsub("(\\w+)", "to%3A\\1", gsub("@", "", to))), ")", "%20"))
  men <- ifelse(is.null(men), "", paste0("(", gsub(" ", "%20OR%20", gsub("@", "%40", gsub("@@", "@", paste0("@", men)))), ")", "%20"))
  term_search <- paste0("https://x.com/search?f=live&q=", search_all, search_exact, search_any, no_search, hashtag, from, to, men, "min_replies%3A", rep, "%20min_faves%3A", fav, "%20min_retweets%3A", rt, lan, "%20since%3A", since, "%20until%3A", until, "&src=typed_query")
  .get_historical(
    query_url = term_search,
    prefix = "full_search",
    n_tweets = n_tweets,
    dir = dir,
    save = save
  )
}
