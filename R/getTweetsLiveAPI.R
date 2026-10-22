# Captura "en vivo" de una busqueda via API GraphQL/JSON de X ----------------
#
# X no ofrece streaming para sesiones de usuario, asi que la captura es un
# polling sobre getTweetsSearchAPI(): cada ronda agrega el operador
# `since_id:<ultimo id visto>` a la consulta, de modo que X devuelve solo los
# tweets posteriores (since_id es exclusivo) y no se gasta cupo en lo ya traido.

#' Reloj y espera de la captura en vivo (indirecciones para poder testear)
#' @noRd
.live_now <- function() Sys.time()

#' @noRd
.live_sleep <- function(seconds) Sys.sleep(seconds)

#' Mayor ID de tweet de un vector de IDs en texto
#'
#' Los IDs de X superan la precision de un double: se comparan como texto,
#' primero por longitud y despues lexicograficamente.
#' @noRd
.max_status_id <- function(ids) {
  ids <- ids[!is.na(ids) & nzchar(ids)]
  if (!length(ids)) return(NULL)
  ids[order(nchar(ids), ids, decreasing = TRUE, method = "radix")][[1]]
}

#' Capture Tweets from a Search as They Are Published (experimental)
#'
#' @description
#'
#' <a href="https://lifecycle.r-lib.org/articles/stages.html#experimental" target="_blank"><img src="https://lifecycle.r-lib.org/articles/figures/lifecycle-experimental.svg" alt="[Experimental]"></a>
#'
#' Sigue una busqueda "hacia adelante": repite [getTweetsSearchAPI()] (pestania
#' "Latest") cada `interval` segundos durante `duration` segundos y acumula
#' solo los tweets nuevos. Desde la segunda ronda la consulta lleva el operador
#' `since_id:` con el ID mas reciente ya recolectado, asi que X devuelve solo lo
#' publicado despues y no se vuelve a gastar cupo en lo ya traido.
#'
#' No es un streaming real: la granularidad es `interval`. Si en una ronda
#' aparecen `n_tweets` o mas tweets nuevos, los que exceden el tope quedan sin
#' recolectar (se avisa con un mensaje); en ese caso conviene bajar `interval`
#' o subir `n_tweets`. Un error en una ronda se informa y la captura sigue con
#' la proxima. Interrumpir con Esc / Ctrl+C termina la captura y devuelve lo
#' acumulado hasta ese momento.
#'
#' **Guardado y reanudacion:** con `save = TRUE` o `db`, cada ronda se guarda
#' en una base SQLite apenas llega. Para continuar una captura cortada, llama
#' de nuevo con el mismo `search` y `db = "<ruta>.sqlite"`: la primera ronda
#' pide lo posterior al tweet mas reciente guardado y `duration` cuenta desde
#' la nueva llamada.
#'
#' @param search Consulta de busqueda (soporta operadores de X, p.ej. "lang:es",
#'   "-filter:retweets"). Por defecto "#RStats".
#' @param interval Segundos entre rondas. Minimo 60. Por defecto 300.
#' @param duration Segundos totales de captura. Por defecto 3600 (una hora).
#' @param n_tweets Tope de tweets por ronda. La primera ronda trae hasta
#'   `n_tweets` de los mas recientes como punto de partida. Por defecto 100.
#' @param max_tweets La captura termina cuando la base llega a este total de
#'   tweets. Por defecto `Inf` (solo limita `duration`).
#' @param db Ruta a una base `.sqlite`. Si no existe se crea; si existe, se
#'   continua la captura guardada en ella. Por defecto NULL.
#' @param dir Directorio donde se crea la base cuando `save = TRUE` y no se
#'   pasa `db`. Por defecto el de trabajo.
#' @param save Logico. Si TRUE y no se pasa `db`, crea una base nueva
#'   `api_live_<consulta>_<fecha>.sqlite` en `dir`. Por defecto FALSE: se usa
#'   una base temporal que se borra al terminar.
#'
#' @return Un tibble con un tweet por fila, del mas nuevo al mas viejo (mismas
#'   columnas que [getTweetsSearchAPI()]). Al continuar una captura incluye lo
#'   guardado antes.
#' @export
#'
#' @examples
#' \dontrun{
#' importSessionX(auth_token = "...", ct0 = "...")
#' # Una hora de captura, una ronda cada 5 minutos, guardando en cada ronda
#' vivo <- getTweetsLiveAPI("#RStats", interval = 300, duration = 3600, save = TRUE)
#' }
getTweetsLiveAPI <- function(search = "#RStats", interval = 300, duration = 3600,
                             n_tweets = 100, max_tweets = Inf,
                             db = NULL, dir = getwd(), save = FALSE) {
  if (!is.numeric(interval) || length(interval) != 1L || is.na(interval) || interval < 60) {
    stop("`interval` debe ser un numero de segundos >= 60.", call. = FALSE)
  }
  if (!is.numeric(duration) || length(duration) != 1L || is.na(duration) || duration <= 0) {
    stop("`duration` debe ser un numero de segundos > 0.", call. = FALSE)
  }
  where <- .store_path(db, save, dir, paste0("api_live_", gsub("[^A-Za-z0-9]+", "_", search)))
  if (where$temp) on.exit(.store_unlink(where$path), add = TRUE)
  con <- .store_open(where$path)
  on.exit(.store_close(con), add = TRUE, after = FALSE)
  meta <- .store_meta(con)
  if (length(meta)) {
    if (!identical(meta$`function`, "live") || !identical(meta$search, search)) {
      stop("La base ", where$path, " es de otra descarga (", meta$`function`, ": \"",
           meta$search, "\").", call. = FALSE)
    }
    cat("Continuando captura guardada en ", where$path, "\n", sep = "")
  } else {
    .store_set_meta(con, list(`function` = "live", search = search,
                              version = as.character(utils::packageVersion("TweetScraperR"))))
  }

  inicio <- .live_now()
  fin <- inicio + duration
  cat("Captura en vivo de: ", search, " (cada ", interval, " s hasta las ",
      format(fin, "%H:%M:%S"), ")\n", sep = "")

  last_id <- .store_max_id(con)
  ronda <- 0L
  tryCatch({
    repeat {
      ronda <- ronda + 1L
      q <- if (is.null(last_id)) search else paste0(search, " since_id:", last_id)
      # El cat() de cada busqueda se descarta: el progreso es la linea por ronda.
      nuevos <- tryCatch(
        {
          utils::capture.output(
            r <- getTweetsSearchAPI(q, n_tweets = n_tweets, product = "Latest", save = FALSE)
          )
          r
        },
        error = function(e) {
          message("Ronda ", ronda, " fallida (se reintenta en la proxima): ", conditionMessage(e))
          NULL
        }
      )
      n_nuevos <- 0L
      if (NROW(nuevos)) {
        if (!is.null(last_id) && nrow(nuevos) >= n_tweets) {
          message("Ronda ", ronda, ": se alcanzo el tope de ", n_tweets, " tweets; puede haber ",
                  "tweets sin recolectar. Conviene bajar `interval` o subir `n_tweets`.")
        }
        last_id <- .max_status_id(c(last_id, nuevos$tweet_id))
        n_nuevos <- .store_add(con, nuevos)
      }
      total <- .store_count(con)
      cat(format(.live_now(), "%H:%M:%S"), " | ronda ", ronda, ": ", n_nuevos,
          " nuevos | total: ", total, "\n", sep = "")
      if (total >= max_tweets) break
      espera <- min(interval, as.numeric(difftime(fin, .live_now(), units = "secs")))
      if (espera <= 0) break
      .live_sleep(espera)
    }
  }, interrupt = function(e) cat("Captura interrumpida.\n"))

  tweets <- .store_read(con)
  cat("Captura terminada:", nrow(tweets), "tweets en", ronda, "rondas.\n")
  if (!where$temp) cat("Guardado en ", where$path, "\n", sep = "")
  tweets
}
