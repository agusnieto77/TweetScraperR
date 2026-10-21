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
#' @param search Consulta de busqueda (soporta operadores de X, p.ej. "lang:es",
#'   "-filter:retweets"). Por defecto "#RStats".
#' @param interval Segundos entre rondas. Minimo 60. Por defecto 300.
#' @param duration Segundos totales de captura. Por defecto 3600 (una hora).
#' @param n_tweets Tope de tweets por ronda. La primera ronda trae hasta
#'   `n_tweets` de los mas recientes como punto de partida. Por defecto 100.
#' @param max_tweets La captura termina al alcanzar este total acumulado. Por
#'   defecto `Inf` (solo limita `duration`).
#' @param dir Directorio de destino del RDS. Por defecto el de trabajo.
#' @param save Logico. Si TRUE guarda lo acumulado en un RDS dentro de `dir`
#'   despues de cada ronda (si la sesion de R se corta, lo recolectado no se
#'   pierde). Por defecto FALSE: no se escribe ningun archivo.
#'
#' @return Un tibble con un tweet por fila, del mas nuevo al mas viejo (mismas
#'   columnas que [getTweetsSearchAPI()]).
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
                             dir = getwd(), save = FALSE) {
  if (!is.numeric(interval) || length(interval) != 1L || is.na(interval) || interval < 60) {
    stop("`interval` debe ser un numero de segundos >= 60.", call. = FALSE)
  }
  if (!is.numeric(duration) || length(duration) != 1L || is.na(duration) || duration <= 0) {
    stop("`duration` debe ser un numero de segundos > 0.", call. = FALSE)
  }
  inicio <- .live_now()
  fin <- inicio + duration
  path <- file.path(dir, paste0("api_live_", gsub("[^A-Za-z0-9]+", "_", search), "_",
                                format(inicio, "%Y_%m_%d_%H_%M_%S"), ".rds"))
  cat("Captura en vivo de: ", search, " (cada ", interval, " s hasta las ",
      format(fin, "%H:%M:%S"), ")\n", sep = "")

  tweets <- tibble::tibble()
  last_id <- NULL
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
        nuevos <- nuevos[!nuevos$tweet_id %in% tweets[["tweet_id"]], ]
        n_nuevos <- nrow(nuevos)
        tweets <- dplyr::bind_rows(nuevos, tweets)
        if (save && n_nuevos) saveRDS(tweets, path)
      }
      cat(format(.live_now(), "%H:%M:%S"), " | ronda ", ronda, ": ", n_nuevos,
          " nuevos | total: ", nrow(tweets), "\n", sep = "")
      if (nrow(tweets) >= max_tweets) break
      espera <- min(interval, as.numeric(difftime(fin, .live_now(), units = "secs")))
      if (espera <= 0) break
      .live_sleep(espera)
    }
  }, interrupt = function(e) cat("Captura interrumpida.\n"))

  cat("Captura terminada:", nrow(tweets), "tweets en", ronda, "rondas.\n")
  if (save) {
    cat(if (file.exists(path)) paste0("Guardado en ", path, "\n") else "No hubo tweets para guardar.\n")
  }
  tweets
}
