#' Get Tweets by Search with Xquik
#'
#' @description
#'
#' Consulta el endpoint de busqueda de tweets de Xquik y devuelve una tabla
#' compatible con los flujos del paquete. Requiere una clave de API en
#' `XQUIK_API_KEY` o en el argumento `api_key`.
#'
#' @param search La consulta de busqueda para recuperar tweets. Por defecto es "#RStats".
#' @param n_tweets El numero maximo de tweets a recuperar. Por defecto es 100.
#' @param query_type Orden de busqueda. Puede ser "Latest" o "Top".
#' @param api_key Clave de API de Xquik. Por defecto usa la variable de entorno `XQUIK_API_KEY`.
#' @param base_url URL base de Xquik. Por defecto es "https://xquik.com".
#' @param timeout Tiempo de espera de la peticion en segundos.
#'
#' @return Un tibble con tweets recuperados desde Xquik.
#' @export
#'
#' @examples
#' \dontrun{
#' getTweetsXquikSearch(search = "#RStats", n_tweets = 50)
#'
#' getTweetsXquikSearch(
#'   search = "from:rstats",
#'   query_type = "Top",
#'   api_key = Sys.getenv("XQUIK_API_KEY")
#' )
#' }
#'
#' @references
#' Puedes encontrar mas informacion sobre Xquik en:
#' <https://docs.xquik.com>
#'
#' @importFrom dplyr bind_rows
#' @importFrom httr GET add_headers content timeout
#' @importFrom jsonlite fromJSON
#' @importFrom lubridate as_datetime
#' @importFrom tibble tibble
#'
getTweetsXquikSearch <- function(
    search = "#RStats",
    n_tweets = 100,
    query_type = c("Latest", "Top"),
    api_key = Sys.getenv("XQUIK_API_KEY"),
    base_url = "https://xquik.com",
    timeout = 30
) {
  query_type <- match.arg(query_type)
  xquik_check_string(search, "search")
  xquik_check_string(api_key, "api_key")
  xquik_check_string(base_url, "base_url")
  xquik_check_positive_number(n_tweets, "n_tweets")
  xquik_check_positive_number(timeout, "timeout")

  limit <- min(200L, as.integer(n_tweets))
  request_url <- paste0(sub("/+$", "", base_url), "/api/v1/x/tweets/search")
  response <- httr::GET(
    request_url,
    httr::add_headers("X-API-Key" = api_key, Accept = "application/json"),
    query = list(q = search, limit = limit, queryType = query_type),
    httr::timeout(timeout)
  )
  response_text <- httr::content(response, as = "text", encoding = "UTF-8")

  if (response$status_code >= 400) {
    stop(
      paste0(
        "Xquik request failed with HTTP ",
        response$status_code,
        ". ",
        xquik_error_message(response_text)
      ),
      call. = FALSE
    )
  }

  payload <- jsonlite::fromJSON(response_text, simplifyVector = FALSE)
  tweets <- payload$tweets
  captured_at <- Sys.time()
  if (is.null(tweets) || length(tweets) == 0) {
    return(xquik_empty_tweets())
  }
  if (!is.list(tweets)) {
    stop("Unexpected Xquik response. Tweets must be a list.", call. = FALSE)
  }

  rows <- lapply(tweets, xquik_tweet_row, captured_at = captured_at)
  dplyr::bind_rows(rows)
}

xquik_tweet_row <- function(tweet, captured_at) {
  created <- xquik_field_chr(tweet, "created")
  fecha <- if (is.na(created)) {
    lubridate::as_datetime(NA_character_)
  } else {
    lubridate::as_datetime(created)
  }

  tibble::tibble(
    id = xquik_field_chr(tweet, "id"),
    fecha = fecha,
    user = xquik_author_chr(tweet, "username"),
    name = xquik_author_chr(tweet, "name"),
    tweet = xquik_field_chr(tweet, "text"),
    url = xquik_field_chr(tweet, "url"),
    lang = xquik_field_chr(tweet, "lang"),
    like_count = xquik_field_num(tweet, "like_count"),
    retweet_count = xquik_field_num(tweet, "retweet_count"),
    reply_count = xquik_field_num(tweet, "reply_count"),
    quote_count = xquik_field_num(tweet, "quote_count"),
    view_count = xquik_field_num(tweet, "view_count"),
    fecha_captura = captured_at
  )
}

xquik_empty_tweets <- function() {
  tibble::tibble(
    id = character(),
    fecha = as.POSIXct(character(), tz = "UTC"),
    user = character(),
    name = character(),
    tweet = character(),
    url = character(),
    lang = character(),
    like_count = numeric(),
    retweet_count = numeric(),
    reply_count = numeric(),
    quote_count = numeric(),
    view_count = numeric(),
    fecha_captura = as.POSIXct(character(), tz = "UTC")
  )
}

xquik_author_chr <- function(record, field) {
  author <- record[["author"]]
  if (!is.list(author)) {
    return(NA_character_)
  }
  xquik_field_chr(author, field)
}

xquik_field_chr <- function(record, field) {
  value <- record[[field]]
  if (is.null(value) || is.list(value) || length(value) == 0) {
    return(NA_character_)
  }
  scalar <- value[[1]]
  if (length(scalar) != 1 || is.na(scalar)) {
    return(NA_character_)
  }
  as.character(scalar)
}

xquik_field_num <- function(record, field) {
  value <- record[[field]]
  if (is.null(value) || is.list(value) || length(value) == 0) {
    return(NA_real_)
  }
  scalar <- value[[1]]
  if (length(scalar) != 1 || is.na(scalar)) {
    return(NA_real_)
  }
  if (is.numeric(scalar)) {
    return(scalar)
  }
  if (is.character(scalar) && grepl("^[0-9]+(\\.[0-9]+)?$", scalar)) {
    return(as.numeric(scalar))
  }
  NA_real_
}

xquik_check_string <- function(value, name) {
  if (!is.character(value) || length(value) != 1 || is.na(value) || !nzchar(value)) {
    stop(paste0(name, " must be a non-empty string."), call. = FALSE)
  }
}

xquik_check_positive_number <- function(value, name) {
  if (!is.numeric(value) || length(value) != 1 || is.na(value) || !is.finite(value) || value < 1) {
    stop(paste0(name, " must be a positive number."), call. = FALSE)
  }
}

xquik_error_message <- function(response_text) {
  payload <- tryCatch(
    jsonlite::fromJSON(response_text, simplifyVector = FALSE),
    error = function(error) NULL
  )
  if (is.list(payload)) {
    for (field in c("error", "message", "detail")) {
      value <- payload[[field]]
      if (!is.null(value) && !is.list(value) && length(value) > 0) {
        scalar <- value[[1]]
        if (length(scalar) == 1 && !is.na(scalar)) {
          return(as.character(scalar))
        }
      }
    }
  }
  "Check request parameters and API key."
}
