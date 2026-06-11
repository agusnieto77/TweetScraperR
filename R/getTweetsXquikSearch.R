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

  target_count <- as.integer(n_tweets)
  request_url <- paste0(sub("/+$", "", base_url), "/api/v1/x/tweets/search")
  tweets <- list()
  captured_at <- Sys.time()
  cursor <- NULL

  while (length(tweets) < target_count) {
    limit <- min(200L, target_count - length(tweets))
    query <- list(q = search, limit = limit, queryType = query_type)
    if (!is.null(cursor) && nzchar(cursor)) {
      query$cursor <- cursor
    }

    response <- httr::GET(
      request_url,
      httr::add_headers("X-API-Key" = api_key, Accept = "application/json"),
      query = query,
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
    page_tweets <- payload$tweets
    if (is.null(page_tweets) || length(page_tweets) == 0) {
      break
    }
    if (!is.list(page_tweets)) {
      stop("Unexpected Xquik response. Tweets must be a list.", call. = FALSE)
    }

    tweets <- c(tweets, page_tweets)
    if (!isTRUE(xquik_field_bool(payload, c("hasNextPage", "has_next_page")))) {
      break
    }

    next_cursor <- xquik_field_chr_any(payload, c("nextCursor", "next_cursor"))
    if (is.na(next_cursor) || !nzchar(next_cursor) || identical(next_cursor, cursor)) {
      break
    }
    cursor <- next_cursor
  }

  if (length(tweets) == 0) {
    return(xquik_empty_tweets())
  }

  rows <- lapply(tweets, xquik_tweet_row, captured_at = captured_at)
  dplyr::bind_rows(rows)
}

xquik_tweet_row <- function(tweet, captured_at) {
  created <- xquik_field_chr_any(tweet, c("createdAt", "created"))
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
    like_count = xquik_field_num_any(tweet, c("likeCount", "like_count")),
    retweet_count = xquik_field_num_any(tweet, c("retweetCount", "retweet_count")),
    reply_count = xquik_field_num_any(tweet, c("replyCount", "reply_count")),
    quote_count = xquik_field_num_any(tweet, c("quoteCount", "quote_count")),
    view_count = xquik_field_num_any(tweet, c("viewCount", "view_count")),
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

xquik_field_chr_any <- function(record, fields) {
  for (field in fields) {
    value <- xquik_field_chr(record, field)
    if (!is.na(value)) {
      return(value)
    }
  }
  NA_character_
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

xquik_field_num_any <- function(record, fields) {
  for (field in fields) {
    value <- xquik_field_num(record, field)
    if (!is.na(value)) {
      return(value)
    }
  }
  NA_real_
}

xquik_field_bool <- function(record, fields) {
  for (field in fields) {
    value <- record[[field]]
    if (is.logical(value) && length(value) == 1 && !is.na(value)) {
      return(value)
    }
  }
  FALSE
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
