# Incremental SQLite store for long downloads --------------------------------
#
# Long downloads (historical search, live capture, reply crawler) write every
# batch to a SQLite database as soon as it arrives, inside a transaction, so
# an unexpected stop never corrupts or loses what was already confirmed. The
# `plan` table fixes the work units when the database is created; resuming
# runs only the pending ones. Each tweet is stored as the serialize() of its
# one-row tibble, which keeps list columns and types exactly.

#' Esquema actual de las bases de descarga
#' @noRd
.STORE_VERSION <- 1L

#' Abre (o crea) una base de descarga
#' @noRd
.store_open <- function(path) {
  con <- DBI::dbConnect(RSQLite::SQLite(), path)
  # busy_timeout antes de pasar a WAL: el cambio de modo toma un lock.
  DBI::dbExecute(con, "PRAGMA busy_timeout = 10000")
  DBI::dbExecute(con, "PRAGMA journal_mode = WAL")
  DBI::dbExecute(con, "PRAGMA synchronous = NORMAL")
  uv <- DBI::dbGetQuery(con, "PRAGMA user_version")[[1]]
  if (uv > .STORE_VERSION) {
    DBI::dbDisconnect(con)
    stop("La base ", path, " es de una version mas nueva de TweetScraperR: actualiza el paquete.",
         call. = FALSE)
  }
  if (uv < 1L) {
    DBI::dbWithTransaction(con, {
      DBI::dbExecute(con, "
        CREATE TABLE IF NOT EXISTS tweets (
          tweet_id        TEXT PRIMARY KEY NOT NULL,
          conversation_id TEXT,
          fecha           REAL,
          row             BLOB NOT NULL
        )")
      DBI::dbExecute(con, "CREATE INDEX IF NOT EXISTS tweets_conv ON tweets(conversation_id)")
      DBI::dbExecute(con, "CREATE INDEX IF NOT EXISTS tweets_fecha ON tweets(fecha)")
      DBI::dbExecute(con, "CREATE TABLE IF NOT EXISTS meta (key TEXT PRIMARY KEY NOT NULL, value TEXT)")
      DBI::dbExecute(con, "
        CREATE TABLE IF NOT EXISTS plan (
          task_key TEXT PRIMARY KEY NOT NULL,
          a        REAL NOT NULL,
          b        REAL NOT NULL,
          product  TEXT,
          level    INTEGER,
          done_at  INTEGER
        )")
      DBI::dbExecute(con, paste0("PRAGMA user_version = ", .STORE_VERSION))
    })
  }
  con
}

#' Cierra la base volcando el WAL al archivo principal
#' @noRd
.store_close <- function(con) {
  try(DBI::dbExecute(con, "PRAGMA wal_checkpoint(TRUNCATE)"), silent = TRUE)
  DBI::dbDisconnect(con)
}

#' Borra una base temporal y sus archivos -wal/-shm
#' @noRd
.store_unlink <- function(path) unlink(paste0(path, c("", "-wal", "-shm")))

#' Lee la meta como lista con nombres (vacia si la base es nueva)
#' @noRd
.store_meta <- function(con) {
  m <- DBI::dbGetQuery(con, "SELECT key, value FROM meta")
  stats::setNames(as.list(m$value), m$key)
}

#' Guarda la meta de una base nueva
#' @noRd
.store_set_meta <- function(con, meta) {
  DBI::dbExecute(con, "INSERT OR REPLACE INTO meta (key, value) VALUES (?, ?)",
                 params = list(names(meta), vapply(meta, as.character, "")))
  invisible()
}

#' Epoch en segundos enteros, como texto sin notacion cientifica
#'
#' Se usa floor() sobre numeric y no as.integer(): los enteros de R son de 32
#' bits y desbordan en 2038.
#' @noRd
.epoch_chr <- function(t) sprintf("%.0f", floor(as.numeric(t)))

#' POSIXct UTC a partir de segundos epoch
#' @noRd
.epoch_time <- function(x) as.POSIXct(as.numeric(x), origin = "1970-01-01", tz = "UTC")

#' Agrega tweets a la base en una sola transaccion
#'
#' Las filas sin `tweet_id` se descartan (no se podrian deduplicar).
#' @return Cantidad de tweets nuevos (los ya guardados se ignoran).
#' @noRd
.store_add <- function(con, tweets) {
  if (!NROW(tweets)) return(0L)
  tweets <- tweets[!is.na(tweets$tweet_id) & nzchar(tweets$tweet_id), ]
  if (!nrow(tweets)) return(0L)
  rows <- lapply(seq_len(nrow(tweets)), function(i) serialize(tweets[i, ], NULL))
  conv <- if ("conversation_id" %in% names(tweets)) tweets$conversation_id else NA_character_
  fecha <- if ("fecha" %in% names(tweets)) as.numeric(tweets$fecha) else NA_real_
  DBI::dbWithTransaction(con, {
    DBI::dbExecute(con, "INSERT OR IGNORE INTO tweets (tweet_id, conversation_id, fecha, row) VALUES (?, ?, ?, ?)",
                   params = list(tweets$tweet_id, rep_len(conv, nrow(tweets)),
                                 rep_len(fecha, nrow(tweets)), rows))
  })
}

#' Cantidad de tweets guardados (opcionalmente de una conversacion)
#' @noRd
.store_count <- function(con, conversation_id = NULL) {
  if (is.null(conversation_id)) return(DBI::dbGetQuery(con, "SELECT COUNT(*) FROM tweets")[[1]])
  DBI::dbGetQuery(con, "SELECT COUNT(*) FROM tweets WHERE conversation_id = ?",
                  params = list(conversation_id))[[1]]
}

#' ID de tweet mas reciente (los IDs crecen con el tiempo: longitud y luego texto)
#' @noRd
.store_max_id <- function(con) {
  r <- DBI::dbGetQuery(con, "SELECT tweet_id FROM tweets ORDER BY LENGTH(tweet_id) DESC, tweet_id DESC LIMIT 1")
  if (nrow(r)) r$tweet_id[[1]] else NULL
}

#' Agrega unidades de trabajo al plan
#' @noRd
.store_plan_add <- function(con, plan) {
  DBI::dbWithTransaction(con, {
    DBI::dbExecute(con, "INSERT OR IGNORE INTO plan (task_key, a, b, product, level) VALUES (?, ?, ?, ?, ?)",
                   params = list(plan$task_key, as.numeric(plan$a), as.numeric(plan$b),
                                 plan$product, as.integer(plan$level)))
  })
  invisible()
}

#' Unidades de trabajo pendientes cuyo `task_key` empieza con `prefix`
#'
#' Orden: Latest antes que Top y, dentro de cada uno, de la mas reciente a la
#' mas vieja (como entrega X).
#' @noRd
.store_plan_pending <- function(con, prefix) {
  p <- DBI::dbGetQuery(con, "
    SELECT task_key, a, b, product, level FROM plan
    WHERE done_at IS NULL AND task_key LIKE ?
    ORDER BY CASE product WHEN 'Top' THEN 1 ELSE 0 END, a DESC",
    params = list(paste0(prefix, "%")))
  p$a <- .epoch_time(p$a)
  p$b <- .epoch_time(p$b)
  p
}

#' Marca una unidad de trabajo como terminada
#' @noRd
.store_done <- function(con, task_key) {
  DBI::dbExecute(con, "UPDATE plan SET done_at = ? WHERE task_key = ?",
                 params = list(as.numeric(Sys.time()), task_key))
  invisible()
}

#' Guarda el avance de una ventana: lo que va de `b` al fin original ya esta
#' completo, asi que al reanudar la ventana pendiente es [a, b)
#' @noRd
.store_plan_progress <- function(con, task_key, b) {
  DBI::dbExecute(con, "UPDATE plan SET b = ? WHERE task_key = ? AND b > ?",
                 params = list(as.numeric(b), task_key, as.numeric(b)))
  invisible()
}

#' Lee los tweets guardados, del mas nuevo al mas viejo
#'
#' Con `a`/`b` (POSIXct) devuelve solo los de [a, b).
#' @noRd
.store_read <- function(con, a = NULL, b = NULL) {
  sql <- "SELECT row FROM tweets"
  params <- list()
  if (!is.null(a)) {
    sql <- paste(sql, "WHERE fecha >= ? AND fecha < ?")
    params <- list(as.numeric(a), as.numeric(b))
  }
  sql <- paste(sql, "ORDER BY LENGTH(tweet_id) DESC, tweet_id DESC")
  res <- DBI::dbSendQuery(con, sql, params = if (length(params)) params)
  on.exit(DBI::dbClearResult(res), add = TRUE)
  out <- list()
  while (!DBI::dbHasCompleted(res)) {
    chunk <- DBI::dbFetch(res, n = 5000)
    if (!nrow(chunk)) break
    out[[length(out) + 1L]] <- dplyr::bind_rows(lapply(chunk$row, unserialize))
  }
  if (length(out)) dplyr::bind_rows(out) else tibble::tibble()
}

#' Ruta de la base de una descarga
#'
#' `db` explicito, o uno nuevo con timestamp en `dir` si `save = TRUE`, o uno
#' temporal (que se borra al terminar) si no se guarda.
#' @return `list(path, temp)`.
#' @noRd
.store_path <- function(db, save, dir, prefix) {
  if (!is.null(db)) return(list(path = db, temp = FALSE))
  if (isTRUE(save)) {
    return(list(path = file.path(dir, paste0(prefix, "_", format(Sys.time(), "%Y_%m_%d_%H_%M_%S"), ".sqlite")),
                temp = FALSE))
  }
  list(path = tempfile("tsr_", fileext = ".sqlite"), temp = TRUE)
}

#' Read Tweets Saved by a Long Download
#'
#' @description
#'
#' Lee los tweets guardados en la base SQLite de [getTweetsHistoricalAPI()],
#' [getTweetsLiveAPI()] o [getTweetsThreadsAPI()] (con `save = TRUE` o `db`),
#' sin volver a descargar nada. Sirve tambien para revisar lo recolectado por
#' una descarga cortada antes de reanudarla.
#'
#' @param db Ruta al archivo `.sqlite`.
#'
#' @return Un tibble con un tweet por fila, del mas nuevo al mas viejo (mismas
#'   columnas que [getTweetsSearchAPI()]).
#' @export
#'
#' @examples
#' \dontrun{
#' tw <- readTweetsDB("api_historical_milei_2026_10_21_22_43_04.sqlite")
#' }
readTweetsDB <- function(db) {
  if (!is.character(db) || length(db) != 1L || !file.exists(db)) {
    stop("No existe la base ", db, ".", call. = FALSE)
  }
  con <- .store_open(db)
  on.exit(.store_close(con), add = TRUE)
  .store_read(con)
}
