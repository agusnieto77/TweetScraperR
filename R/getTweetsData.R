#' Get Tweets Data
#'
#' @description
#'
#' <a href="https://lifecycle.r-lib.org/articles/stages.html#experimental" target="_blank"><img src="https://lifecycle.r-lib.org/articles/figures/lifecycle-experimental.svg" alt="[Experimental]"></a>
#'
#' @description
#' **Obsoleta**: preféri getTweetsDataAPI(), basada en la API de X (datos del JSON, mas robusta).
#'
#' Esta función permite recuperar y procesar datos de tweets a partir de un vector de URLs
#' de tweets proporcionadas. Utilizando las credenciales de unx usuarix de Twitter, la función
#' realiza la autenticación en Twitter y extrae información detallada de cada tweet. Los datos
#' extraídos incluyen la fecha del tweet, el nombre de usuarix que lo publicó, el texto del tweet,
#' las respuestas, reposts, me gusta, URLs asociadas, y otra información relevante.
#' La función también maneja tweets borrados y errores durante el proceso de recolección, y
#' clasifica las URLs de los tweets en tres categorías: tweets recuperados, tweets borrados, y
#' tweets que necesitan ser reprocesados. Si el parámetro 'save' es TRUE, los datos recopilados
#' se guardan en un archivo RDS en el directorio especificado por le usuarix.
#'
#' @param urls_tweets Vector de URLs de tweets de los cuales se desea obtener datos.
#' @param xuser Nombre de usuarix de Twitter para autenticación. Por defecto es el valor de la variable de entorno TWITTER_USER y, si esta no está definida, el de la variable de entorno del sistema USER.
#' @param xpass Contraseña de Twitter para autenticación. Por defecto es el valor de la variable de entorno TWITTER_PASS y, si esta no está definida, el de la variable de entorno del sistema PASS.
#' @param dir directorio para guardar el RDS con las URLs recolectadas
#' @param save Logical. Indica si se debe guardar el resultado en un archivo RDS. Por defecto es TRUE.
#' @return Un tibble que contiene los datos de los tweets recuperados.
#'
#' @details
#' Cuando save = TRUE, se guarda un archivo RDS con una lista que contiene:
#'
#' \itemize{
#'   \item \code{tweets_recuperados}: Un tibble con los datos de los tweets recuperados, incluyendo la fecha, nombre de usuario, texto, respuestas, reposts, me gusta, URLs asociadas y otras informaciones recopiladas.
#'   \item \code{tweets_borrados}: Un vector con las URLs de los tweets que fueron detectados como borrados.
#'   \item \code{tweets_a_reprocesar}: Un vector con las URLs de los tweets que no pudieron ser procesados exitosamente y necesitan ser reprocesados.
#'   \item \code{errores}: Un vector con los mensajes de error recopilados durante el proceso de recolección de datos.
#' }
#'
#' @export
#'
#' @examples
#' \dontrun{
#' getTweetsData(urls_tweets = "https://twitter.com/estacion_erre/status/1788929978811232537")
#' getTweetsData(
#'   urls_tweets = "https://twitter.com/estacion_erre/status/1788929978811232537",
#'   save = FALSE
#' )
#' }
#'
#' @importFrom rvest read_html_live html_elements html_element html_attr html_text
#' @importFrom lubridate as_datetime is.POSIXct
#' @importFrom tibble tibble
#' @importFrom stringr str_extract_all
#'

getTweetsData <- function(
    urls_tweets,
    xuser = Sys.getenv("TWITTER_USER", Sys.getenv("USER")),
    xpass = Sys.getenv("TWITTER_PASS", Sys.getenv("PASS")),
    dir = getwd(),
    save = TRUE
) {
  .Deprecated(msg = "getTweetsData() est\u00e1 obsoleta: us\u00e1 getTweetsDataAPI() (basada en la API de X, datos estructurados del JSON, m\u00e1s robusta). Ver ?getTweetsDataAPI.")
  twitter <- .x_login(xuser, xpass)
  on.exit(.close_sessions(twitter), add = TRUE)
  .collect_tweets_data(urls_tweets, dir = dir, save = save)
}

#' Motor interno compartido de getTweetsData() y getTweetsData2()
#'
#' Itera las URLs de tweets: carga cada una con reintentos acotados
#' (.read_html_live_retry), detecta tweets borrados/inaccesibles, extrae los
#' campos con .extract_data_article_fields() (el esquema legacy de 16
#' columnas, con la columna urls a nivel de página, como el código legacy),
#' acumula los resultados en una lista y guarda/reporta con los mensajes
#' legacy. Cada sesión live por URL se cierra en todos los caminos (finally),
#' y la función termina siempre (sin el while externo legacy que nunca
#' seteaba success).
#'
#' @param urls_tweets Vector de URLs de tweets.
#' @param dir Directorio donde guardar el RDS.
#' @param save Lógico. Si TRUE guarda el resultado en un archivo RDS.
#' @param msg_borrado Prefijo literal del mensaje de tweet borrado
#'   ("El tweet" en getTweetsData, "\\nEl tweet" en getTweetsData2).
#'
#' @return Un tibble con los datos de los tweets recuperados, o NULL de forma
#'   invisible si no se recuperó ninguno.
#' @noRd
.collect_tweets_data <- function(urls_tweets, dir, save, msg_borrado = "El tweet") {
  Sys.sleep(3)
  borrados <- c()
  errores <- c()
  contador <- 0
  resultados <- vector("list", length(urls_tweets))
  cat("Inicio de la recolecci\u00f3n de datos.\n\n")
  for (i in urls_tweets) {
    contador <- contador + 1
    tweets <- NULL
    tryCatch({
      tweets <- .read_html_live_retry(i, wait = 3)
      Sys.sleep(6)
      raiz <- gsub("\\D", "", sub(".*status/", "", i))
      tuit_out <- tweets$html_elements(xpath = paste0('//article[.//a[contains(@href, ', '"', raiz, '"', ')]]'))
      if (grepl("i/communities/", i) || length(tuit_out) == 0) {
        borrados <- append(borrados, i)
        cat(msg_borrado, gsub("https://twitter.com/.*/status/|https://x.com/.*/status/|https://x.com/i/communities/", "", i), "fue BORRADO o se encuentra moment\u00e1neamente INACCESIBLE.\n")
      } else {
        articulo <- tuit_out[1]
        urls_tw <- rvest::html_attr(tweets$html_elements(css = "article a"), "href")
        urls_tw <- urls_tw[grep("/status/", urls_tw)]
        urls_tw <- urls_tw[!grepl("/status/.*/analytics|/status/.*/photo|/status/.*/hidden|/status/.*/quotes", urls_tw)]
        resultados[[contador]] <- .extract_data_article_fields(articulo, i, urls_tw)
        message("Datos recolectados del tweet: ", gsub("https://twitter.com/|https://x.com/", "", i), " ", contador, " de ", length(urls_tweets))
      }
    }, error = function(e) {
      errores <<- append(errores, conditionMessage(e))
      cat("Error al procesar el tweet:", gsub("https://twitter.com/.*/status/|https://x.com/.*/status/", "", i), "\n")
    }, finally = {
      .close_sessions(tweets)
    })
  }
  tweets_db <- dplyr::bind_rows(resultados)
  if (nrow(tweets_db) > 0) {
    tweets_db$fecha <- lubridate::as_datetime(tweets_db$fecha)
    tweets_db_c <- tweets_db[!is.na(tweets_db$fecha), ]
    urls_tweets_r <- setdiff(urls_tweets, borrados)
    urls_tweets_n <- setdiff(urls_tweets_r, tweets_db_c$url)

    if (save) {
      saveRDS(list(tweets_recuperados = tweets_db_c,
                   tweets_borrados_o_inaccesibles = borrados,
                   tweets_a_reprocesar = urls_tweets_n,
                   errores = errores),
              file.path(dir, paste0("tweets_data_", format(Sys.time(), "%Y_%m_%d_%H_%M_%S"), ".rds")))
      cat("\nLos datos de los tweets se han guardado en un archivo RDS.\n")
    } else {
      cat("\nLos datos de los tweets no se han guardado en un archivo RDS.\n")
    }

    cat("\nTerminando el proceso.\n      \nTweets recuperados:",
        length(tweets_db_c$url),
        "\nTweets borrados o inaccesibles:",
        length(borrados),
        "\nTweets con errores:",
        length(errores),
        "\nTweets pendientes:",
        length(urls_tweets_n),
        "\n\n")
    return(tweets_db_c)
  } else {
    urls_tweets_n <- setdiff(urls_tweets, borrados)

    if (save) {
      saveRDS(list(tweets_borrados = borrados,
                   tweets_a_reprocesar = urls_tweets_n,
                   errores = errores),
              file.path(dir, paste0("tweets_data_", format(Sys.time(), "%Y_%m_%d_%H_%M_%S"), ".rds")))
      cat("\nLos datos de los tweets se han guardado en un archivo RDS.\n")
    } else {
      cat("\nLos datos de los tweets no se han guardado en un archivo RDS.\n")
    }

    cat("\nTerminando el proceso.\n      \nTweets recuperados:",
        0,
        "\nTweets borrados o inaccesibles:",
        length(borrados),
        "\nTweets con errores:",
        length(errores),
        "\nTweets pendientes:",
        length(urls_tweets_n),
        "\n\n")
    return(invisible(NULL))
  }
}

#' Extracción legacy de campos para getTweetsData() y getTweetsData2()
#'
#' Variante interna exclusiva de la familia de scraping de datos: conserva el
#' contrato legacy de 16 columnas (sin links_externos ni reproducciones), las
#' XPaths de métricas solo en español, la semántica NA de megustas (sin
#' coerción a 0) y la extracción plana de texto con html_text (sin reemplazo
#' del alt de los emojis ni trim). .extract_article_fields() (utils-extract.R)
#' queda solo para extractTweetsData(), que siempre tuvo el esquema rico.
#' El único cambio respecto del código legacy es el username, que usa la
#' extracción corregida .extract_username (bug C03).
#'
#' @param articulo Nodo (xml_nodeset) del article tal como lo devuelve la
#'   sesión live; las XPaths con //* buscan desde la raíz del documento de la
#'   página, como en el código legacy.
#' @param url URL del tweet.
#' @param urls_tw URLs de status a nivel de página, ya filtradas por el caller.
#'
#' @return Tibble de una fila con las 16 columnas legacy (fecha, username,
#'   texto, tweet_citado, user_citado, emoticones, links_img_user,
#'   links_img_post, respuestas, reposteos, megustas, metricas, urls, hilo,
#'   url, fecha_captura). Los errores se propagan al tryCatch del caller,
#'   como en el código legacy.
#' @noRd
.extract_data_article_fields <- function(articulo, url, urls_tw) {
  metrica_res <- '//*[contains(@aria-label, "Respuesta") or contains(@aria-label, "Respuestas")]'
  metrica_rep <- '//*[contains(@aria-label, "Repostear")]'
  metrica_meg <- '//*[contains(@aria-label, "Me gusta")]'
  pattern <- "https?://(pbs|video)\\.twimg\\.com/(media|tweet_video_thumb|tweet_video|amplify_video_thumb)/[^\\s\"']+(?:\\?[^\\s\"']+)?"
  fechas <- lubridate::as_datetime(rvest::html_attr(rvest::html_elements(articulo, css = "time"), "datetime"))
  fechas <- fechas[order(fechas, decreasing = TRUE)][1]
  if (lubridate::is.POSIXct(fechas)) {max_fecha <- fechas} else {max_fecha <- NA}
  metr <- rvest::html_attr(rvest::html_element(articulo, xpath = metrica_meg), "aria-label")
  resp <- rvest::html_attr(rvest::html_element(articulo, xpath = metrica_res), "aria-label")
  if (grepl("[0-9]", resp)) {resp_ok <- as.integer(gsub("^(\\d+).*", "\\1", resp))} else {resp_ok <- as.integer(gsub("^(\\d+).*", "\\1", metr))}
  tibble::tibble(
    fecha = max_fecha,
    username = .extract_username(url),
    texto = rvest::html_text(rvest::html_elements(articulo, css = 'div[data-testid="tweetText"]'))[1],
    tweet_citado = rvest::html_text(rvest::html_elements(articulo, css = 'div[data-testid="tweetText"]'))[2],
    user_citado = rvest::html_text(rvest::html_elements(articulo, css = 'div.css-175oi2r.r-1wbh5a2.r-dnmrzs > div > div > span'))[3],
    emoticones = list(rvest::html_attr(rvest::html_elements(articulo, css = 'div[data-testid="tweetText"] img'), "alt")),
    links_img_user = sub(".*?(https://.*?(?:png|jpg)).*", "\\1", grep("profile_images", gsub('src="([^"]+)"', '\\1', regmatches(as.character(articulo), gregexpr('src="(.*?\\.(?:png|jpg))"', as.character(articulo), perl=TRUE))[[1]]), value = TRUE)[1]),
    links_img_post = list(unique(gsub("&amp;", "&", stringr::str_extract_all(as.character(articulo), pattern)[[1]]))),
    respuestas = resp_ok,
    reposteos = as.integer(gsub("^(\\d+).*", "\\1", rvest::html_attr(rvest::html_element(articulo, xpath = metrica_rep), "aria-label"))),
    megustas = as.integer(gsub(".*?(\\d+) Me gusta.*", "\\1", metr)),
    metricas = metr,
    urls = list(urls_tw),
    hilo = resp_ok,
    url = url,
    fecha_captura = Sys.time()
  )
}
