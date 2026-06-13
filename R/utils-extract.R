# Helpers internos de extraccion de datos de tweets -----------------------

#' XPath bilingue (espanol/ingles) para la metrica de me gusta
#' @noRd
.xp_metrica_meg <- '//*[contains(@aria-label, "Me gusta") or contains(@aria-label, "like") or contains(@aria-label, "likes") or contains(@aria-label, "Like") or contains(@aria-label, "Likes")]'

#' XPath bilingue (espanol/ingles) para la metrica de respuestas
#' @noRd
.xp_metrica_res <- '//*[contains(@aria-label, "Respuesta") or contains(@aria-label, "Respuestas") or contains(@aria-label, "Reply") or contains(@aria-label, "Replies")]'

#' XPath bilingue (espanol/ingles) para la metrica de reposteos
#' @noRd
.xp_metrica_rep <- '//*[contains(@aria-label, "Repostear") or contains(@aria-label, "Repost") or contains(@aria-label, "repost") or contains(@aria-label, "Reposts") or contains(@aria-label, "reposts")]'

#' Regex para URLs de media de twimg.com
#' @noRd
.rx_twimg <- "https?://(pbs|video)\\.twimg\\.com/(media|tweet_video_thumb|tweet_video|amplify_video_thumb)/[^\\s\"']+(?:\\?[^\\s\"']+)?"

#' Regex para links acortados t.co (links externos / YouTube)
#' @noRd
.rx_tco <- "https?://t\\.co/[^\\s\"']+(?:\\?[^\\s\"']+)?"

#' Extrae el username desde la URL de un tweet
#'
#' Version corregida con UN solo grupo de captura: el sub legacy con
#' alternation (^https://x.com/(.*?)/.*$|^https://twitter.com/(.*?)/.*$)
#' devolvia string vacio para URLs twitter.com porque el reemplazo "\\1"
#' referenciaba un grupo no matcheado (bug C03).
#'
#' @param url URL del tweet (x.com o twitter.com).
#'
#' @return El username (character).
#' @noRd
.extract_username <- function(url) {
  sub("^https://(?:x|twitter)\\.com/([^/]+)/.*$", "\\1", url, perl = TRUE)
}

#' Extrae fecha/user/tweet/url de un vector de articles HTML
#'
#' Promocion a nivel de paquete del .extract_tweet_data local de
#' getTweetsSearchStreaming2.R: parsea cada article UNA sola vez (el loop
#' legacy re-parseaba 4 veces por campo) y devuelve un tibble equivalente al
#' del loop legacy, con dplyr::distinct por url y filtrado de filas invalidas
#' (sin el sentinel-date hack).
#'
#' @param articles_html Vector character con el HTML de cada article.
#' @param url_selector Selector CSS para el anchor de la URL del tweet.
#'   Por defecto (NULL) usa .sel$tweet_url; getTweetsCites usa otro selector.
#'
#' @return Tibble con columnas art_html, fecha, user, tweet, url, fecha_captura.
#' @noRd
.extract_tweet_data <- function(articles_html, url_selector = NULL) {
  if (is.null(url_selector)) {
    url_selector <- .sel$tweet_url
  }
  articles_html <- as.character(articles_html)
  n_articles <- length(articles_html)
  if (n_articles == 0) return(tibble::tibble())

  fechas <- vector("list", n_articles)
  usuarios <- character(n_articles)
  textos <- character(n_articles)
  urls <- character(n_articles)

  for (i in seq_len(n_articles)) {
    tryCatch({
      post_html <- rvest::read_html(articles_html[i])

      time_elements <- rvest::html_elements(post_html, css = .sel$tweet_time)
      if (length(time_elements) > 0) {
        datetime_attrs <- rvest::html_attr(time_elements, "datetime")
        valid_dates <- lubridate::as_datetime(datetime_attrs[!is.na(datetime_attrs)])
        if (length(valid_dates) > 0) {
          fechas[[i]] <- max(valid_dates)
        }
      }

      user_element <- rvest::html_element(post_html, css = .sel$tweet_user)
      if (!is.na(user_element)) {
        usuarios[i] <- rvest::html_text(user_element)
      }

      text_element <- rvest::html_element(post_html, css = .sel$tweet_text)
      if (!is.na(text_element)) {
        textos[i] <- rvest::html_text(text_element)
      }

      url_element <- rvest::html_element(post_html, css = url_selector)
      if (!is.na(url_element)) {
        href <- rvest::html_attr(url_element, "href")
        if (!is.na(href)) {
          urls[i] <- paste0("https://x.com", href)
        }
      }

    }, error = function(e) {
      message("Error al procesar el art\u00edculo ", i, ": ", conditionMessage(e))
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
  result <- dplyr::distinct(result, url, .keep_all = TRUE)
  result
}

#' Extraccion rica de campos de un article (version bilingue completa)
#'
#' Promocion a nivel de paquete de process_single_article (extractTweetsData.R),
#' la version mas completa de la extraccion rica: 17 columnas con metricas
#' bilingues espanol/ingles. Mejoras respecto del original: as.character(articulo)
#' se serializa UNA sola vez (antes 4 veces por fila) y el username usa la
#' extraccion corregida .extract_username (bug C03). No incluye la columna
#' fecha_captura: el caller la agrega si corresponde.
#'
#' @param articulo HTML del article como string (o lista cuyo primer elemento
#'   lo contiene), o un documento xml ya parseado.
#' @param url URL del tweet.
#'
#' @return Tibble de una fila con 17 columnas (fecha, username, texto,
#'   tweet_citado, user_citado, emoticones, links_img_user, links_img_post,
#'   links_externos, respuestas, reposteos, megustas, reproducciones,
#'   metricas, urls, hilo, url), o NULL si fallo el procesamiento.
#' @noRd
.extract_article_fields <- function(articulo, url) {
  tryCatch({
    # Comprobar si articulo es una lista y extraer el primer elemento si es asi
    # (los objetos xml2 tambien son listas de external pointers: no desenvolver)
    if (is.list(articulo) && !inherits(articulo, c("xml_document", "xml_node"))) {
      articulo <- articulo[[1]]
    }

    if (is.character(articulo)) {
      articulo <- xml2::read_html(articulo)
    } else if (!inherits(articulo, c("xml_document", "xml_node"))) {
      stop("El contenido HTML debe ser una cadena de texto")
    }

    # Serializar el articulo UNA sola vez
    art_str <- as.character(articulo)

    # Extraccion de URLs
    urls_tw <- rvest::html_attr(rvest::html_elements(articulo, css = "article a"), "href")
    urls_tw <- urls_tw[grep("/status/", urls_tw)]
    urls_tw <- urls_tw[!grepl("/status/.*/analytics|/status/.*/photo|/status/.*/hidden|/status/.*/quotes", urls_tw)]

    # Extraccion de fechas
    fechas <- lubridate::as_datetime(rvest::html_attr(rvest::html_elements(articulo, css = .sel$tweet_time), "datetime"))
    max_fecha <- if (length(fechas) > 0) max(fechas) else NA

    # Extraccion de metricas
    metr <- rvest::html_attr(rvest::html_element(articulo, xpath = .xp_metrica_meg), "aria-label")
    resp <- rvest::html_attr(rvest::html_element(articulo, xpath = .xp_metrica_res), "aria-label")
    resp_ok <- if (grepl("[0-9]", resp)) as.integer(gsub("^(\\d+).*", "\\1", resp)) else as.integer(gsub("^(\\d+).*", "\\1", metr))
    megus <- suppressWarnings(as.integer(gsub(".*?(\\d+)\\s*(?:Me gusta|likes|like).*", "\\1", metr)))
    reprodu <- suppressWarnings(as.integer(gsub(".*?(\\d+)\\s*(?:reproducciones|views|reproduccion|view).*", "\\1", metr)))

    # Creacion del tibble con los datos extraidos
    tibble::tibble(
      fecha = lubridate::as_datetime(max_fecha),
      username = .extract_username(url),
      texto = rvest::html_text(rvest::html_element(rvest::read_html(stringr::str_replace_all(art_str, '<img alt="([^"]+)"[^>]*>', '\\1')), "[data-testid='tweetText']"), trim = TRUE)[1],
      tweet_citado = rvest::html_text(rvest::html_elements(articulo, css = .sel$tweet_text))[2],
      user_citado = rvest::html_text(rvest::html_elements(articulo, css = .sel$quoted_user))[3],
      emoticones = list(rvest::html_attr(rvest::html_elements(articulo, css = .sel$tweet_emoji), "alt")),
      links_img_user = sub(".*?(https://.*?(?:png|jpg)).*", "\\1", grep("profile_images", gsub('src="([^"]+)"', '\\1', regmatches(art_str, gregexpr('src="(.*?\\.(?:png|jpg))"', art_str, perl = TRUE))[[1]]), value = TRUE)[1]),
      links_img_post = list(unique(gsub("&amp;", "&", stringr::str_extract_all(art_str, .rx_twimg)[[1]]))),
      links_externos = list(unique(stringr::str_extract_all(art_str, .rx_tco)[[1]])),
      respuestas = resp_ok,
      reposteos = as.integer(gsub(".*?(\\d+)\\s*(?:Repostear|repost|reposts).*", "\\1", rvest::html_attr(rvest::html_element(articulo, xpath = .xp_metrica_rep), "aria-label"))),
      megustas = if (!is.na(megus)) megus else 0,
      reproducciones = if (!is.na(reprodu)) reprodu else 0,
      metricas = metr,
      urls = list(urls_tw),
      hilo = resp_ok,
      url = url
    )
  }, error = function(e) {
    message("Error al procesar el tweet: ", url, "\n", conditionMessage(e))
    return(NULL)
  })
}
