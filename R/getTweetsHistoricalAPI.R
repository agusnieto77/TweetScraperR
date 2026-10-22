# Busqueda historica por ventanas -------------------------------------------
#
# Una sola consulta de busqueda de X devuelve como mucho unos cientos de
# tweets (X deja de paginar), asi que un periodo denso se pierde casi entero.
# Este modo trocea el periodo en ventanas con since_time:/until_time: (epoch,
# sin ambiguedad de zona horaria) y, cuando una ventana se satura, sigue
# pidiendo desde la "frontera" hacia atras; si la frontera no avanza,
# subdivide con una frecuencia mas fina. Estrategia adaptada del modo
# "optimized search" de t-hoarder-twscrape (Mariluz Congosto, GPL-3; solo se
# reutiliza la idea, no el codigo).

#' Escalera de frecuencias de las ventanas, de la mas gruesa a la mas fina
#' @noRd
.HIST_LADDER <- c("1 month", "1 week", "1 day", "6 hours", "3 hours", "1 hour", "30 mins")

#' Tweets por pagina de SearchTimeline
#' @noRd
.HIST_PAGE <- 20L

#' Dias que cubre el indice denso de la busqueda de X
#'
#' Fuera de esa ventana Latest devuelve un residuo (decenas de tweets por
#' dia), mientras que Destacados ("Top") en ventanas de 3 h devuelve unas diez
#' veces mas (pruebas del 21-10-2026: 410 contra 37 en un dia). Con ventanas
#' de 1 h Top devuelve 0, asi que no se subdivide mas.
#' @noRd
.HIST_DENSE_DAYS <- 7L

#' Ventana fija de Destacados para el tramo anterior al indice denso
#' @noRd
.HIST_TOP_WINDOW <- "3 hours"

#' Reloj de la busqueda historica (indireccion para poder testear)
#' @noRd
.hist_now <- function() Sys.time()

#' Primer instante (00:00 UTC) dentro del indice denso de la busqueda
#' @noRd
.hist_dense_cutoff <- function() {
  hoy <- as.POSIXct(format(.hist_now(), "%Y-%m-%d", tz = "UTC"), tz = "UTC")
  hoy - .HIST_DENSE_DAYS * 86400
}

#' Frecuencia inicial segun la duracion del periodo
#' @noRd
.hist_initial_level <- function(a, b) {
  days <- as.numeric(difftime(b, a, units = "days"))
  if (days < 7) 3L else if (days < 31) 2L else 1L
}

#' Cortes de [a, b) cada `freq`, terminando exactamente en b
#' @noRd
.hist_breaks <- function(a, b, freq) {
  s <- seq(a, b, by = freq)
  if (s[length(s)] < b) s <- c(s, b)
  s
}

#' Hasta donde llega sin huecos lo recibido de una ventana saturada [a, b)
#'
#' X entrega Latest de lo mas nuevo a lo mas viejo, pero con rezagados mas
#' viejos mezclados en cualquier posicion: la frontera es la mediana de las
#' fechas de la ultima pagina (en orden de llegada) dentro de la ventana.
#' @return POSIXct, o NULL si ningun tweet cae en la ventana.
#' @noRd
.hist_frontier <- function(fechas, a, b) {
  f <- fechas[!is.na(fechas) & fechas >= a & fechas < b]
  if (!length(f)) return(NULL)
  m <- stats::median(as.numeric(utils::tail(f, .HIST_PAGE)))
  as.POSIXct(m, origin = "1970-01-01", tz = "UTC")
}

#' Descarga [a, b) a la frecuencia `.HIST_LADDER[level]`
#'
#' `fetch(a, b, freq)` descarga una ventana y devuelve sus tweets (en orden de
#' llegada); `on_overflow(a, b, freq, n, action)` anota saturaciones y
#' continuaciones. `on_continue(b)` recibe el nuevo fin cada vez que la
#' ventana sigue hacia atras ([b, fin original) ya quedo completo); solo se
#' pasa a la ventana de nivel superior, para guardar el avance y reanudar
#' desde ahi.
#'
#' Una respuesta corta no prueba que la ventana este agotada: X trunca
#' respuestas al azar (en pruebas del 22-10-2026 la misma media hora densa
#' devolvio 0 y 900, y otra ventana 20 tweets de una sola pagina). Por eso,
#' tras cualquier respuesta con tweets se sigue pidiendo lo anterior al mas
#' viejo recibido, y la ventana se cierra solo cuando no llega nada mas viejo.
#' @noRd
.hist_window <- function(a, b, level, fetch, threshold, on_overflow, on_continue = NULL) {
  freq <- .HIST_LADDER[[level]]
  repeat {
    tw <- fetch(a, b, freq)
    f <- if (NROW(tw)) tw$fecha[!is.na(tw$fecha) & tw$fecha >= a & tw$fecha < b]
    if (!length(f)) return(invisible())
    if (NROW(tw) < threshold) {
      # Respuesta corta: seguir desde el tweet mas viejo recibido (incluido su
      # segundo; el solape se deduplica). Sin avance, la ventana esta agotada.
      rest <- .epoch_time(floor(min(as.numeric(f))) + 1)
      if (rest >= b) return(invisible())
      on_overflow(a, b, freq, nrow(tw), paste("respuesta corta, se sigue hasta", format(rest, "%Y-%m-%d %H:%M:%S")))
      b <- rest
      if (!is.null(on_continue)) on_continue(b)
      next
    }
    frontier <- .hist_frontier(tw$fecha, a, b)
    if (is.null(frontier) || frontier <= a) {
      on_overflow(a, b, freq, nrow(tw), "inicio de la ventana alcanzado")
      return(invisible())
    }
    # El epoch va en segundos: se redondea hacia arriba para no dejar fuera
    # el segundo de la frontera (el solape se deduplica al final).
    rest <- as.POSIXct(ceiling(as.numeric(frontier)) + 1, origin = "1970-01-01", tz = "UTC")
    if (rest < b) {
      on_overflow(a, b, freq, nrow(tw), paste("se continua hasta", format(rest, "%Y-%m-%d %H:%M:%S")))
      b <- rest
      if (!is.null(on_continue)) on_continue(b)
      next
    }
    if (level < length(.HIST_LADDER)) {
      on_overflow(a, b, freq, nrow(tw), paste("sin avance, se subdivide en", .HIST_LADDER[[level + 1L]]))
      br <- .hist_breaks(a, b, .HIST_LADDER[[level + 1L]])
      for (j in seq_len(length(br) - 1L)) {
        .hist_window(br[[j]], br[[j + 1L]], level + 1L, fetch, threshold, on_overflow)
      }
    } else {
      on_overflow(a, b, freq, nrow(tw), "frecuencia minima alcanzada: puede estar incompleta")
    }
    return(invisible())
  }
}

#' Plan de ventanas de nivel superior de [a0, b0)
#'
#' Lo posterior a `cutoff` va a Latest con la frecuencia inicial adaptativa; lo
#' anterior, a Destacados en ventanas fijas de 3 h. Se calcula una sola vez al
#' crear la base y se guarda en `plan`: reanudar no lo recalcula aunque el
#' corte de los 7 dias haya avanzado.
#' @return data.frame con `task_key`, `a`, `b` (POSIXct), `product`, `level`.
#' @noRd
.hist_plan <- function(a0, b0, cutoff, prefix = "hist") {
  rows <- list()
  add <- function(br, product, level) {
    n <- length(br) - 1L
    if (n < 1L) return()
    a <- br[seq_len(n)]
    b <- br[seq_len(n) + 1L]
    rows[[length(rows) + 1L]] <<- data.frame(
      task_key = paste(prefix, .epoch_chr(a), .epoch_chr(b), product, sep = "|"),
      a = a, b = b, product = product, level = level, stringsAsFactors = FALSE
    )
  }
  if (b0 > cutoff) {
    a1 <- max(a0, cutoff)
    level <- .hist_initial_level(a1, b0)
    add(.hist_breaks(a1, b0, .HIST_LADDER[[level]]), "Latest", level)
  }
  if (a0 < cutoff) add(.hist_breaks(a0, min(b0, cutoff), .HIST_TOP_WINDOW), "Top", NA_integer_)
  if (length(rows)) do.call(rbind, rows) else
    data.frame(task_key = character(0), a = .epoch_time(numeric(0)), b = .epoch_time(numeric(0)),
               product = character(0), level = integer(0))
}

#' Consulta testigo: TRUE si la busqueda de X esta devolviendo resultados
#'
#' Tras muchas consultas X frena en silencio: toda busqueda vuelve vacia sin
#' avisar del limite (pruebas del 22-10-2026: "milei" y "lang:en" sin fechas
#' devolvieron 0). Una busqueda que nunca puede estar vacia distingue una
#' ventana realmente vacia de un freno.
#' @noRd
.search_canary <- function() {
  tw <- tryCatch({
    utils::capture.output(r <- suppressMessages(
      getTweetsSearchAPI("lang:en", n_tweets = 20, product = "Latest", save = FALSE)
    ))
    r
  }, error = function(e) NULL)
  NROW(tw) > 0
}

#' Ejecuta ventanas de una busqueda historica guardando cada lote en `con`
#'
#' Cada consulta queda `ok` (respondio, aunque sea vacia), `failed` (dos o mas
#' intentos dieron error sin datos) o `partial` (el motor corto por falta de
#' cuentas). Una ventana se da por terminada solo si todas las consultas de
#' su recursion quedaron `ok`; si `mark` es TRUE se marca en `plan`. Antes de
#' aceptar un vacio se verifica con `.search_canary()` que X no este frenando;
#' si lo esta, se corta con una condicion de clase `tsr_search_throttled`. No
#' atrapa interrupciones ni errores al guardar: llegan al llamador sin marcar
#' la ventana en curso.
#' @param windows Salida de `.hist_plan()` o de `.store_plan_pending()`.
#' @param stats Environment donde se acumulan `consultas` y `saturadas` (lo
#'   pasa el llamador para conservar los conteos aunque haya un Ctrl+C).
#' @return Lista invisible: `complete` (todas las ventanas terminadas) y
#'   `pending` (claves no terminadas).
#' @noRd
.hist_run <- function(search, windows, n_per_window, con, mark = TRUE, verbose = TRUE,
                      stats = new.env()) {
  threshold <- min(n_per_window, 500)
  if (is.null(stats$consultas)) stats$consultas <- 0L
  if (is.null(stats$saturadas)) stats$saturadas <- 0L
  stats$ok <- TRUE
  say <- function(...) if (verbose) cat(..., sep = "")

  fetch <- function(a, b, freq, product = "Latest") {
    tw <- NULL
    errores <- 0L
    parcial <- FALSE
    nuevos <- 0L
    # X devuelve vacios y errores intermitentes, y suele repetir el resultado
    # de una consulta identica: hasta 3 intentos, cada uno con `until_time` un
    # segundo mas tarde (la ventana crece, no se pierde nada; el solape se
    # deduplica). Un vacio se acepta solo si al menos dos intentos
    # respondieron vacio sin error.
    for (intento in 1:3) {
      stats$consultas <- stats$consultas + 1L
      q <- paste0(search, " since_time:", .epoch_chr(a), " until_time:",
                  sprintf("%.0f", ceiling(as.numeric(b)) + intento - 1))
      tw <- tryCatch(
        withCallingHandlers({
          utils::capture.output(
            r <- getTweetsSearchAPI(q, n_tweets = n_per_window, product = product, save = FALSE)
          )
          r
        }, tsr_partial_harvest = function(w) {
          parcial <<- TRUE
          message("Consulta incompleta (", format(a, "%Y-%m-%d %H:%M"), "): ", conditionMessage(w))
          invokeRestart("muffleWarning")
        }),
        error = function(e) {
          errores <<- errores + 1L
          message("Consulta fallida (", format(a, "%Y-%m-%d %H:%M"), "): ", conditionMessage(e))
          NULL
        })
      nuevos <- nuevos + .store_add(con, tw)
      if (NROW(tw)) break
    }
    if (parcial || (!NROW(tw) && errores >= 2L)) stats$ok <- FALSE
    if (!NROW(tw) && stats$ok) {
      # Un vacio cierra la ventana: antes, confirmar que X no esta frenando
      # (el testigo se reusa durante 5 minutos).
      vigente <- !is.null(stats$testigo) && difftime(Sys.time(), stats$testigo, units = "secs") < 300
      if (!vigente) {
        stats$consultas <- stats$consultas + 1L
        if (!.search_canary()) {
          stop(errorCondition(paste0(
            "X esta devolviendo busquedas vacias sin avisar del limite (freno silencioso). ",
            "Lo descargado quedo guardado; reanuda mas tarde."), class = "tsr_search_throttled"))
        }
        stats$testigo <- Sys.time()
      }
    }
    if (is.null(tw)) tw <- tibble::tibble()
    say(format(a, "%Y-%m-%d %H:%M"), " -> ", format(b, "%Y-%m-%d %H:%M"), " (",
        if (product == "Latest") freq else paste(product, freq), "): ",
        NROW(tw), " tweets, ", nuevos, " nuevos | total: ", .store_count(con), "\n")
    tw
  }
  on_overflow <- function(a, b, freq, n, action) {
    if (n >= threshold) stats$saturadas <- stats$saturadas + 1L
    say(if (n >= threshold) "  ventana saturada (" else "  ", n, " tweets", if (n >= threshold) ")", ": ",
        action, "\n")
  }

  pending <- character(0)
  for (k in seq_len(nrow(windows))) {
    w <- windows[k, ]
    stats$ok <- TRUE
    if (identical(w$product, "Top")) {
      fetch(w$a, w$b, .HIST_TOP_WINDOW, product = "Top")
    } else {
      # El avance de la continuacion se guarda: al reanudar se sigue desde la
      # frontera en lugar de volver a pedir lo ya completo.
      avance <- if (mark) function(b) .store_plan_progress(con, w$task_key, b)
      .hist_window(w$a, w$b, w$level, fetch, threshold, on_overflow, avance)
    }
    if (stats$ok) {
      if (mark) .store_done(con, w$task_key)
    } else {
      pending <- c(pending, w$task_key)
    }
  }
  invisible(list(complete = !length(pending), pending = pending))
}

#' Periodo [a0, b0) en epoch UTC entero a partir de `since`/`until`
#'
#' Un dia en `until` incluye ese dia completo.
#' @return Lista con `a0`/`b0` (POSIXct UTC, segundos enteros) o NULL donde
#'   no se paso el valor.
#' @noRd
.hist_bounds <- function(since, until) {
  s <- .parse_search_time(since, "since")
  u <- .parse_search_time(until, "until")
  list(
    a0 = if (!is.null(s)) .epoch_time(floor(as.numeric(s$time))),
    b0 = if (!is.null(u)) .epoch_time(floor(as.numeric(u$time)) + if (u$day) 86400 else 0)
  )
}

#' Historical Search over a Date Range (experimental)
#'
#' @description
#'
#' <a href="https://lifecycle.r-lib.org/articles/stages.html#experimental" target="_blank"><img src="https://lifecycle.r-lib.org/articles/figures/lifecycle-experimental.svg" alt="[Experimental]"></a>
#'
#' Descarga todos los tweets de una busqueda en un periodo. Una sola consulta
#' de [getTweetsSearchAPI()] devuelve como mucho unos cientos de tweets (X deja
#' de paginar), asi que en periodos densos se pierde casi todo. Esta funcion
#' trocea el periodo en ventanas (mes, semana o dia segun su duracion) y,
#' cuando una ventana se satura, sigue pidiendo desde el tweet mas viejo
#' recibido hacia atras; si no avanza, la subdivide (6 h, 3 h, 1 h, 30 min).
#' La estrategia esta adaptada del modo "optimized search" de
#' [t-hoarder-twscrape](https://github.com/congosto/t-hoarder-twscrape).
#'
#' **Limite de X:** el buscador solo tiene completo el contenido de los
#' **ultimos ~7 dias** (desde las 00:00 UTC de hace 7 dias). Mas atras, la
#' pestania "Latest" devuelve un residuo (en las pruebas, 37 tweets en un dia
#' con miles). Para ese tramo la funcion usa "Destacados" (`Top`) en ventanas
#' fijas de 3 horas, que en las pruebas devolvio unas diez veces mas (410 en
#' el mismo dia). Aun asi es una **muestra** de lo que X considera relevante,
#' no el total: para eventos en curso, descarga mientras estan dentro de los 7
#' dias, o sigue el tema con [getTweetsLiveAPI()].
#'
#' **Guardado y reanudacion:** con `save = TRUE` o `db`, cada consulta se
#' guarda en una base SQLite apenas llega (un corte no pierde lo confirmado).
#' Si la descarga se corta (Ctrl+C, error, falta de cuentas), se reanuda
#' llamando de nuevo con el mismo `search` y `db = "<ruta>.sqlite"`: solo se
#' piden las ventanas pendientes, con el periodo y el plan de ventanas
#' guardados al crear la base, y una ventana saturada sigue desde la frontera
#' a la que habia llegado. Una ventana con alguna consulta fallida o
#' incompleta queda pendiente. Como X trunca respuestas al azar, una respuesta
#' corta no cierra la ventana: se sigue pidiendo lo anterior al tweet mas
#' viejo recibido. Antes de aceptar un vacio se verifica con una consulta
#' testigo que X no este frenando en silencio (tras muchas consultas devuelve
#' vacio todo sin avisar); si frena, la descarga se corta y queda pendiente
#' para reanudar mas tarde. Cada tweet ocupa unos 2 KB en la base.
#'
#' @param search Consulta de busqueda (soporta los operadores de X).
#' @param since Comienzo del periodo: un dia `"YYYY-MM-DD"` (00:00 UTC) o un
#'   instante `"YYYY-MM-DD HH:MM[:SS]"` en UTC; tambien `Date` o `POSIXct`.
#'   Obligatorio al empezar; al reanudar se puede omitir.
#' @param until Fin del periodo, mismos formatos. Un dia incluye ese dia
#'   completo (hasta las 24:00 UTC). Por defecto, ahora (al reanudar, el fin
#'   guardado).
#' @param n_per_window Tope de tweets por consulta. Una ventana que devuelve
#'   500 o mas (o `n_per_window`, si es menor) se considera saturada. Minimo
#'   100. Por defecto 900.
#' @param db Ruta a una base `.sqlite`. Si no existe se crea; si existe, se
#'   reanuda la descarga guardada en ella. Por defecto NULL.
#' @param dir Directorio donde se crea la base cuando `save = TRUE` y no se
#'   pasa `db`. Por defecto el de trabajo.
#' @param save Logico. Si TRUE y no se pasa `db`, crea una base nueva
#'   `api_historical_<consulta>_<fecha>.sqlite` en `dir`. Por defecto FALSE:
#'   se usa una base temporal que se borra al terminar.
#'
#' @return Un tibble con un tweet por fila, del mas nuevo al mas viejo, solo
#'   con tweets dentro del periodo (mismas columnas que [getTweetsSearchAPI()]).
#'   Al reanudar incluye lo descargado en las corridas anteriores.
#' @export
#'
#' @examples
#' \dontrun{
#' importSessionX(auth_token = "...", ct0 = "...")
#' tw <- getTweetsHistoricalAPI("milei", since = "2026-10-20", until = "2026-10-21",
#'                              save = TRUE)
#' # Si se corto: reanudar con la base que creo
#' tw <- getTweetsHistoricalAPI("milei", db = "api_historical_milei_2026_10_21_22_43_04.sqlite")
#' }
getTweetsHistoricalAPI <- function(search, since = NULL, until = NULL, n_per_window = 900,
                                   db = NULL, dir = getwd(), save = FALSE) {
  if (!is.numeric(n_per_window) || length(n_per_window) != 1L || is.na(n_per_window) ||
      n_per_window < 100) {
    stop("`n_per_window` debe ser un numero >= 100.", call. = FALSE)
  }
  bounds <- .hist_bounds(since, until)
  where <- .store_path(db, save, dir, paste0("api_historical_", gsub("[^A-Za-z0-9]+", "_", search)))
  if (where$temp) on.exit(.store_unlink(where$path), add = TRUE)
  con <- .store_open(where$path)
  on.exit(.store_close(con), add = TRUE, after = FALSE)

  meta <- .store_meta(con)
  if (length(meta)) {
    # Reanudar: todo sale de la base; lo explicito tiene que coincidir.
    if (!identical(meta$`function`, "historical") || !identical(meta$search, search) ||
        !identical(meta$n_per_window, .epoch_chr(n_per_window))) {
      stop("La base ", where$path, " es de otra descarga (", meta$`function`, ": \"", meta$search,
           "\", n_per_window = ", meta$n_per_window, ").", call. = FALSE)
    }
    for (k in c("a0", "b0")) {
      if (!is.null(bounds[[k]]) && !identical(.epoch_chr(bounds[[k]]), meta[[k]])) {
        stop("`", if (k == "a0") "since" else "until", "` no coincide con el de la descarga guardada (",
             format(.epoch_time(meta[[k]]), "%Y-%m-%d %H:%M:%S"), " UTC).", call. = FALSE)
      }
    }
    a0 <- .epoch_time(meta$a0)
    b0 <- .epoch_time(meta$b0)
    cutoff <- .epoch_time(meta$cutoff)
    cat("Reanudando descarga guardada en ", where$path, "\n", sep = "")
  } else {
    if (is.null(bounds$a0)) stop("Hace falta `since` para empezar una descarga.", call. = FALSE)
    a0 <- bounds$a0
    b0 <- if (is.null(bounds$b0)) .epoch_time(floor(as.numeric(.hist_now()))) else bounds$b0
    if (b0 <= a0) stop("`until` debe ser posterior a `since`.", call. = FALSE)
    cutoff <- .hist_dense_cutoff()
    .store_set_meta(con, list(`function` = "historical", search = search,
                              a0 = .epoch_chr(a0), b0 = .epoch_chr(b0), cutoff = .epoch_chr(cutoff),
                              n_per_window = .epoch_chr(n_per_window),
                              version = as.character(utils::packageVersion("TweetScraperR"))))
    .store_plan_add(con, .hist_plan(a0, b0, cutoff))
  }

  if (a0 < cutoff) {
    message("Aviso: el tramo anterior a ", format(cutoff, "%Y-%m-%d"), " (00:00 UTC) esta ",
            "fuera del indice completo de X (ultimos ", .HIST_DENSE_DAYS, " dias). Se descarga ",
            "con Destacados en ventanas de 3 h: es una muestra, no el total.")
  }
  windows <- .store_plan_pending(con, "hist|")
  viejas <- sum(windows$product == "Latest" & windows$a < .hist_dense_cutoff())
  if (viejas) {
    message("Aviso: ", viejas, " ventanas pendientes ya quedaron fuera de los ultimos ",
            .HIST_DENSE_DAYS, " dias: vendran incompletas.")
  }
  cat("Busqueda historica de: ", search, " (", format(a0, "%Y-%m-%d %H:%M"), " a ",
      format(b0, "%Y-%m-%d %H:%M"), " UTC, ", nrow(windows), " ventanas pendientes)\n", sep = "")

  stats <- new.env()
  tryCatch(.hist_run(search, windows, n_per_window, con, stats = stats),
           interrupt = function(e) cat("Descarga interrumpida.\n"),
           tsr_search_throttled = function(e) message(conditionMessage(e)))
  pendientes <- nrow(.store_plan_pending(con, "hist|"))

  tweets <- .store_read(con, a0, b0)
  cat("Descarga terminada: ", nrow(tweets), " tweets en ", .or_null(stats$consultas, 0L), " consultas (",
      .or_null(stats$saturadas, 0L), " ventanas saturadas).\n", sep = "")
  if (pendientes) {
    message(pendientes, " ventanas quedaron pendientes (cortadas, fallidas o incompletas). ",
            if (where$temp) "Para poder reanudar, usa `save = TRUE` o `db`." else
              paste0("Reanuda con getTweetsHistoricalAPI(\"", search, "\", db = \"", where$path, "\")."))
  }
  if (!where$temp) cat("Guardado en ", where$path, "\n", sep = "")
  tweets
}
