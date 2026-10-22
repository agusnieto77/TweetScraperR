# Arbol completo de respuestas de tweets ya descargados ----------------------
#
# Todos los tweets de una conversacion (respuestas, respuestas a respuestas,
# a cualquier profundidad) comparten el conversation_id del tweet que la
# inicio, asi que una busqueda `conversation_id:<id>` trae el arbol entero sin
# recorrerlo nivel por nivel. Cada conversacion se baja con
# getTweetsHistoricalAPI(), que trocea por ventanas los hilos enormes.

#' Instante de publicacion codificado en un ID de X (snowflake)
#' @noRd
.snowflake_time <- function(id) {
  ms <- as.numeric(id) / 2^22 + 1288834974657
  as.POSIXct(ms / 1000, origin = "1970-01-01", tz = "UTC")
}

#' Conversaciones a recorrer a partir de un tibble de tweets o de IDs
#'
#' Se omiten las conversaciones sin respuestas (una raiz con `respuestas == 0`).
#' Un retweet se reemplaza por el tweet original (`retweet_id`): su propia
#' conversacion no tiene respuestas.
#' @noRd
.thread_conversations <- function(tweets) {
  if (is.character(tweets)) {
    ids <- unique(tweets[!is.na(tweets)])
  } else if (is.data.frame(tweets)) {
    if (!"conversation_id" %in% names(tweets)) {
      stop("`tweets` debe tener la columna `conversation_id` (salida de las funciones *API).",
           call. = FALSE)
    }
    es_rt <- if ("es_retweet" %in% names(tweets)) tweets$es_retweet %in% TRUE else rep(FALSE, nrow(tweets))
    orig <- tweets[!es_rt, ]
    con_respuestas <- if (all(c("respuestas", "respuesta_a_id") %in% names(orig))) {
      orig$respuestas %in% NA | orig$respuestas > 0 | !is.na(orig$respuesta_a_id)
    } else {
      rep(TRUE, nrow(orig))
    }
    rt_orig <- if ("retweet_id" %in% names(tweets)) tweets$retweet_id[es_rt] else character(0)
    ids <- unique(c(orig$conversation_id[con_respuestas], rt_orig))
    ids <- ids[!is.na(ids)]
  } else {
    stop("`tweets` debe ser un tibble de tweets o un vector de conversation_id.", call. = FALSE)
  }
  bad <- !grepl("^\\d+$", ids)
  if (any(bad)) stop("IDs de conversacion invalidos: ", paste(utils::head(ids[bad], 3), collapse = ", "),
                     call. = FALSE)
  ids
}

#' Crawl Full Reply Trees of Tweets (experimental)
#'
#' @description
#'
#' <a href="https://lifecycle.r-lib.org/articles/stages.html#experimental" target="_blank"><img src="https://lifecycle.r-lib.org/articles/figures/lifecycle-experimental.svg" alt="[Experimental]"></a>
#'
#' A partir de tweets ya descargados (por ejemplo con [getTweetsSearchAPI()]
#' o [getTweetsHistoricalAPI()]), recupera la **conversacion completa** de
#' cada uno: respuestas, respuestas a las respuestas y asi a cualquier
#' profundidad. Todos los tweets de una conversacion comparten el
#' `conversation_id` del tweet que la inicio, asi que alcanza una busqueda
#' `conversation_id:<id>` por conversacion (troceada por ventanas como en
#' [getTweetsHistoricalAPI()], para los hilos enormes).
#'
#' Se omiten las conversaciones sin respuestas y cada conversacion se pide una
#' sola vez aunque varios tweets de entrada pertenezcan a ella. Un retweet se
#' sigue en el tweet original. Las conversaciones que empezaron hace mas de 7
#' dias quedan fuera del indice completo de X: sus respuestas son una muestra
#' (ver [getTweetsHistoricalAPI()]).
#'
#' Con `respuesta_a_id` (el padre de cada respuesta) y `conversation_id` se
#' reconstruye el arbol.
#'
#' **Guardado y reanudacion:** con `save = TRUE` o `db`, cada consulta se
#' guarda en una base SQLite apenas llega. Una conversacion se da por
#' terminada solo si todas sus consultas respondieron; las cortadas (Ctrl+C),
#' fallidas o incompletas quedan pendientes. Para reanudar, llama de nuevo con
#' `db = "<ruta>.sqlite"` (sin `tweets`, o con los mismos).
#'
#' @param tweets Un tibble de tweets (salida de las funciones `*API()`, con la
#'   columna `conversation_id`) o un vector de IDs de conversacion.
#'   Obligatorio al empezar; al reanudar se puede omitir.
#' @param n_per_window Tope de tweets por consulta, ver
#'   [getTweetsHistoricalAPI()]. Por defecto 900.
#' @param db Ruta a una base `.sqlite`. Si no existe se crea; si existe, se
#'   reanuda el recorrido guardado en ella. Por defecto NULL.
#' @param dir Directorio donde se crea la base cuando `save = TRUE` y no se
#'   pasa `db`. Por defecto el de trabajo.
#' @param save Logico. Si TRUE y no se pasa `db`, crea una base nueva
#'   `api_threads_<fecha>.sqlite` en `dir`. Por defecto FALSE: se usa una base
#'   temporal que se borra al terminar.
#'
#' @return Un tibble con un tweet por fila (mismas columnas que
#'   [getTweetsSearchAPI()]), ordenado por conversacion y fecha. Incluye el
#'   tweet raiz de cada conversacion.
#' @export
#'
#' @examples
#' \dontrun{
#' importSessionX(auth_token = "...", ct0 = "...")
#' tw <- getTweetsSearchAPI("#RStats", n_tweets = 100)
#' hilos <- getTweetsThreadsAPI(tw, save = TRUE)
#' }
getTweetsThreadsAPI <- function(tweets = NULL, n_per_window = 900, db = NULL,
                                dir = getwd(), save = FALSE) {
  if (!is.numeric(n_per_window) || length(n_per_window) != 1L || is.na(n_per_window) ||
      n_per_window < 100) {
    stop("`n_per_window` debe ser un numero >= 100.", call. = FALSE)
  }
  ids <- if (!is.null(tweets)) .thread_conversations(tweets)
  if (!is.null(tweets) && !length(ids) && is.null(db)) {
    cat("No hay conversaciones con respuestas para recorrer.\n")
    return(tibble::tibble())
  }
  where <- .store_path(db, save, dir, "api_threads")
  if (where$temp) on.exit(.store_unlink(where$path), add = TRUE)
  con <- .store_open(where$path)
  on.exit(.store_close(con), add = TRUE, after = FALSE)

  meta <- .store_meta(con)
  if (length(meta)) {
    guardadas <- strsplit(.or_null(meta$conversations, ""), ",", fixed = TRUE)[[1]]
    if (!identical(meta$`function`, "threads") ||
        !identical(meta$n_per_window, .epoch_chr(n_per_window))) {
      stop("La base ", where$path, " es de otra descarga (", meta$`function`,
           ", n_per_window = ", meta$n_per_window, ").", call. = FALSE)
    }
    if (!is.null(ids) && !setequal(ids, guardadas)) {
      stop("Las conversaciones de `tweets` no coinciden con las del recorrido guardado (",
           length(guardadas), " conversaciones). Para reanudar, omiti `tweets`.", call. = FALSE)
    }
    b0 <- .epoch_time(meta$b0)
    cutoff <- .epoch_time(meta$cutoff)
    cat("Reanudando recorrido guardado en ", where$path, "\n", sep = "")
  } else {
    if (is.null(ids)) stop("Hace falta `tweets` para empezar un recorrido.", call. = FALSE)
    # El fin del periodo se fija al crear la base: al reanudar no cambia.
    b0 <- .epoch_time(floor(as.numeric(.hist_now())))
    cutoff <- .hist_dense_cutoff()
    .store_set_meta(con, list(`function` = "threads", b0 = .epoch_chr(b0), cutoff = .epoch_chr(cutoff),
                              n_per_window = .epoch_chr(n_per_window),
                              conversations = paste(sort(ids), collapse = ","),
                              version = as.character(utils::packageVersion("TweetScraperR"))))
    # `fecha` viene al segundo y el snowflake con milisegundos: sin margen, la
    # raiz quedaria afuera del periodo de su propia conversacion.
    inicios <- .epoch_time(floor(as.numeric(.snowflake_time(ids) - 60)))
    .store_plan_add(con, data.frame(task_key = paste0("conv|", ids), a = inicios, b = b0,
                                    product = NA_character_, level = NA_integer_))
  }

  pendientes <- .store_plan_pending(con, "conv|")
  viejas <- sum(pendientes$a < cutoff)
  if (viejas) {
    message("Aviso: ", viejas, " de ", nrow(pendientes), " conversaciones empezaron hace mas de ",
            .HIST_DENSE_DAYS, " dias: sus respuestas vienen de Destacados y son una muestra, no el total.")
  }
  cat("Recorriendo ", nrow(pendientes), " conversaciones pendientes\n", sep = "")

  incompletas <- character(0)
  tryCatch({
    for (k in seq_len(nrow(pendientes))) {
      id <- sub("^conv\\|", "", pendientes$task_key[[k]])
      # Ventanas volatiles (no se guardan en `plan`): la unidad que se marca es
      # la conversacion entera.
      ventanas <- .hist_plan(pendientes$a[[k]], b0, cutoff, prefix = paste0("conv", id))
      run <- .hist_run(paste0("conversation_id:", id), ventanas, n_per_window, con,
                       mark = FALSE, verbose = FALSE)
      if (run$complete) .store_done(con, pendientes$task_key[[k]]) else incompletas <- c(incompletas, id)
      cat(k, "/", nrow(pendientes), " | conversacion ", id, ": ", .store_count(con, id),
          " tweets", if (!run$complete) " (incompleta)", " | total: ", .store_count(con), "\n", sep = "")
    }
  }, interrupt = function(e) cat("Recorrido interrumpido.\n"),
  tsr_search_throttled = function(e) message(conditionMessage(e)))

  out <- .store_read(con)
  if (nrow(out)) out <- out[order(out$conversation_id, out$fecha), ]
  quedan <- nrow(.store_plan_pending(con, "conv|"))
  cat("Recorrido terminado: ", nrow(out), " tweets; ", quedan, " conversaciones pendientes.\n", sep = "")
  if (length(incompletas)) {
    message("Conversaciones con consultas fallidas o incompletas: ", paste(incompletas, collapse = ", "))
  }
  if (quedan) {
    message(if (where$temp) "Para poder reanudar, usa `save = TRUE` o `db`." else
      paste0("Reanuda con getTweetsThreadsAPI(db = \"", where$path, "\")."))
  }
  if (!where$temp) cat("Guardado en ", where$path, "\n", sep = "")
  out
}
