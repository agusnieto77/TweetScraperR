# Bridge R <-> motor Node/Playwright -------------------------------------
#
# El motor de scraping vive en inst/node/tsr-engine.js (Playwright + stealth).
# R lo invoca como subproceso, le pasa parametros JSON por stdin y parsea el
# JSON de stdout. La sesion autenticada se persiste con storageState, de modo
# que el login ocurre UNA sola vez y el resto de las operaciones lo reusan sin
# volver a autenticarse (clave para no disparar el rate-limit de X).

#' Devuelve el primer valor "no vacio"
#' @noRd
.pw_or <- function(a, b) {
  if (is.null(a) || length(a) == 0) return(b)
  if (is.character(a) && !nzchar(a[1])) return(b)
  a
}

#' Directorio del motor Node
#' @noRd
#' @description Prioridad: cache persistente fuera de la libreria de R (que
#'   sobrevive a las reinstalaciones del paquete, evitando perder node_modules
#'   en cada `R CMD INSTALL`), con fallback a inst/node del paquete. En ambos
#'   casos exige que el motor tenga sus dependencias de npm ya instaladas. El
#'   cache se mantiene al dia con el paquete instalado via `.pw_sync_engine()`.
.pw_engine_dir <- function() {
  d <- .pw_cache_dir(create = FALSE)
  if (file.exists(file.path(d, "tsr-engine.js")) &&
      dir.exists(file.path(d, "node_modules"))) {
    .pw_sync_engine(system.file("node", package = "TweetScraperR"), d)
    return(d)
  }
  d <- system.file("node", package = "TweetScraperR")
  if (nzchar(d) && dir.exists(d) &&
      dir.exists(file.path(d, "node_modules"))) {
    return(d)
  }
  stop("El motor Node/Playwright no est\u00e1 instalado (falta node_modules). ",
       "Corre installPlaywrightEngine() una vez por m\u00e1quina.")
}

#' Actualiza el tsr-engine.js del cache si cambio el del paquete
#'
#' Solo copia el script: si tambien cambio package.json (dependencias de npm
#' nuevas), el script nuevo podria no funcionar con el node_modules del cache,
#' asi que se mantiene el motor viejo y se avisa que hay que reinstalarlo.
#'
#' @param pkg_dir Directorio inst/node del paquete instalado.
#' @param cache_dir Directorio del motor en cache.
#' @return Invisiblemente, TRUE si el cache quedo al dia.
#' @noRd
.pw_sync_engine <- function(pkg_dir, cache_dir) {
  # Compara por lineas: segun como se instalo el paquete los archivos pueden
  # venir con finales CRLF o LF y un md5 los daria por distintos.
  same <- function(f) {
    a <- file.path(pkg_dir, f)
    b <- file.path(cache_dir, f)
    !file.exists(a) || (utils::file_test("-f", b) && identical(readLines(a, warn = FALSE), readLines(b, warn = FALSE)))
  }
  if (!nzchar(pkg_dir) || same("tsr-engine.js")) return(invisible(TRUE))
  if (!same("package.json")) {
    warning("El motor Playwright del paquete cambi\u00f3 sus dependencias; se sigue usando la versi\u00f3n anterior. ",
            "Corr\u00e9 installPlaywrightEngine() para actualizarlo.", call. = FALSE)
    return(invisible(FALSE))
  }
  ok <- suppressWarnings(file.copy(file.path(pkg_dir, "tsr-engine.js"), cache_dir, overwrite = TRUE))
  if (!isTRUE(ok)) {
    warning("No se pudo actualizar el motor Playwright en ", cache_dir, "; se sigue usando la versi\u00f3n anterior. ",
            "Corr\u00e9 installPlaywrightEngine() para actualizarlo.", call. = FALSE)
  }
  invisible(isTRUE(ok))
}

#' Directorio persistente del motor (cache del usuario)
#' @noRd
.pw_cache_dir <- function(create = TRUE) {
  d <- file.path(tools::R_user_dir("TweetScraperR", "cache"), "node")
  if (create && !dir.exists(d)) dir.create(d, recursive = TRUE)
  d
}

#' Ruta al binario de Node.js
#' @noRd
.pw_node <- function() {
  n <- getOption("TweetScraperR.node", Sys.getenv("TWEETSCRAPERR_NODE", "node"))
  if (Sys.which(n) == "" && !file.exists(n)) {
    stop("No se encontr\u00f3 Node.js (>= 18). Instalalo y/o configur\u00e1 options(TweetScraperR.node = '/ruta/a/node').")
  }
  n
}

#' Invoca un comando del motor Node y devuelve el resultado parseado
#'
#' @param cmd Comando del motor ("doctor", "login", "collect", "harvest").
#' @param params Lista de parametros (se serializa a JSON y va por stdin).
#' @param timeout Timeout en segundos.
#' @param progress Si es TRUE, muestra un spinner de una sola linea con los
#'   eventos de progreso que el motor emite por stderr ("@@TSR <json>").
#'
#' @return Lista con el JSON de respuesta del motor mas `.stderr` y `.exit`.
#' @noRd
#' @description El motor corre como proceso asincrono (processx) para poder
#'   refrescar el progreso mientras trabaja. La salida estandar se redirige a
#'   un archivo temporal (en Windows las lineas largas por pipe se parten y
#'   corrompen el JSON) y se vuelve a leer intacta al terminar.
.pw_call <- function(cmd, params = list(), timeout = 300, simplify = TRUE, progress = FALSE) {
  script <- file.path(.pw_engine_dir(), "tsr-engine.js")
  json <- jsonlite::toJSON(params, auto_unbox = TRUE, null = "null")
  infile <- tempfile(fileext = ".json")
  outfile <- tempfile(fileext = ".json")
  on.exit(unlink(c(infile, outfile)), add = TRUE)
  writeLines(enc2utf8(json), infile, useBytes = TRUE)

  proc <- processx::process$new(
    .pw_node(), c(script, cmd),
    stdin = infile, stdout = outfile, stderr = "|",
    encoding = "UTF-8", cleanup_tree = TRUE
  )
  # Corre antes que el unlink: un Ctrl+C no deja Node/Chromium huerfanos.
  on.exit(if (proc$is_alive()) proc$kill_tree(), add = TRUE, after = FALSE)

  ui <- if (isTRUE(progress)) .pw_progress() else NULL
  if (!is.null(ui)) on.exit(ui$clear(), add = TRUE, after = FALSE)

  stderr_chr <- character(0)
  handle <- function(lines) {
    is_ev <- startsWith(lines, "@@TSR ")
    stderr_chr <<- c(stderr_chr, lines[!is_ev])
    if (!is.null(ui)) {
      for (l in lines[is_ev]) {
        ev <- tryCatch(jsonlite::fromJSON(substring(l, 7)), error = function(e) NULL)
        if (!is.null(ev)) ui$update(ev)
      }
    }
  }

  deadline <- Sys.time() + timeout
  timed_out <- FALSE
  while (proc$is_alive()) {
    if (Sys.time() > deadline) {
      proc$kill_tree()
      timed_out <- TRUE
      break
    }
    proc$poll_io(100)
    handle(proc$read_error_lines())
    if (!is.null(ui)) ui$draw()
  }
  # Tras kill_tree() el pipe de stderr queda cerrado y no se puede drenar.
  if (!timed_out) handle(proc$read_all_error_lines())
  proc$wait()
  status <- if (timed_out) 124L else proc$get_exit_status()

  txt <- paste(readLines(outfile, warn = FALSE, encoding = "UTF-8"), collapse = "\n")
  res <- tryCatch(
    jsonlite::fromJSON(txt, simplifyVector = simplify),
    error = function(e) {
      msg <- paste0(
        "salida no-JSON del motor (exit ",
        if (is.null(status) || status == 0) "0" else status,
        "): ", substr(txt, 1, 300)
      )
      if (length(stderr_chr) > 0) {
        msg <- paste0(msg, " | stderr: ", paste(utils::tail(stderr_chr, 5), collapse = " "))
      }
      list(ok = FALSE, error = msg)
    }
  )
  if (!is.list(res)) res <- list(ok = FALSE, error = "respuesta inesperada del motor")
  res$.stderr <- stderr_chr
  res$.exit <- if (is.null(status)) 0L else status
  res
}

#' Spinner de una sola linea para la cosecha
#'
#' Redibuja en el lugar (con `\r`) un spinner, el contador de tweets o
#' usuarixs, el tiempo transcurrido y el ultimo tweet recibido. Devuelve NULL
#' si la consola no soporta redibujar lineas (Rscript, knitr, logs).
#' @noRd
.pw_progress <- function() {
  if (!interactive() || !cli::is_dynamic_tty(stdout())) return(NULL)
  frames <- cli::get_spinner(if (cli::is_utf8_output()) "dots" else "line")$frames
  t0 <- Sys.time()
  i <- 0L
  tweets <- 0L
  users <- 0L
  status <- "Iniciando navegador..."
  drawn <- FALSE

  elapsed <- function() {
    s <- as.integer(difftime(Sys.time(), t0, units = "secs"))
    if (s < 60) paste0(s, "s") else sprintf("%dm %02ds", s %/% 60, s %% 60)
  }

  list(
    update = function(ev) {
      if (identical(ev$stage, "open")) {
        page <- sub("^https?://(www\\.)?", "", ev$url)
        status <<- if (isTRUE(ev$n > 1)) {
          paste0("Cargando ", ev$i, "/", ev$n, ": ", page)
        } else {
          paste0("Cargando ", page)
        }
      } else if (identical(ev$stage, "data")) {
        tweets <<- as.integer(.pw_or(ev$tweets, 0L))
        users <<- as.integer(.pw_or(ev$users, 0L))
        if (!is.null(ev$last)) status <<- gsub("\\s+", " ", ev$last)
      }
    },
    draw = function() {
      i <<- i %% length(frames) + 1L
      count <- if (tweets > 0) {
        paste(tweets, "tweets")
      } else if (users > 0) {
        paste(users, "usuarixs")
      } else {
        NULL
      }
      line <- paste(c(
        cli::col_cyan(frames[i]),
        if (!is.null(count)) cli::style_bold(count),
        cli::col_silver(elapsed()),
        status
      ), collapse = "  ")
      w <- max(20L, cli::console_width() - 1L)
      cat("\r", cli::ansi_align(cli::ansi_strtrim(line, w), w), sep = "")
      utils::flush.console()
      drawn <<- TRUE
    },
    clear = function() {
      if (drawn) cat("\r", strrep(" ", max(20L, cli::console_width() - 1L)), "\r", sep = "")
      drawn <<- FALSE
    }
  )
}

#' Login de bajo nivel via motor Node
#' @noRd
.pw_login <- function(xuser, xpass, email = "", state, headless = TRUE, proxy = NULL) {
  params <- list(
    user = xuser, pass = xpass, email = email,
    storageStatePath = state, headless = headless,
    shotDir = tempdir()
  )
  if (!is.null(proxy)) params$proxy <- proxy
  .pw_call("login", params, timeout = 180)
}

#' Motivo (para error_msg del pool) de cada corte que desactiva una cuenta
#' @noRd
.pw_disable_msgs <- c(
  expired       = "sesi\u00f3n expirada o revocada",
  not_logged_in = "sin sesi\u00f3n iniciada",
  banned        = "X limit\u00f3 o suspendi\u00f3 la cuenta (error 88 con cupo disponible)",
  locked        = "cuenta bloqueada por X (error 326)"
)

#' Corre el motor con una cuenta tomada del pool
#'
#' Si R corta antes de que el motor responda (Ctrl+C, error), libera la cuenta
#' para que no quede tomada hasta que venza el bloqueo.
#' @noRd
.pw_harvest_with <- function(acc, op, params) {
  done <- FALSE
  on.exit(if (!done) .pool_release(acc$username, op), add = TRUE)
  res <- .pw_call("harvest", params, timeout = 900, simplify = FALSE, progress = TRUE)
  done <- TRUE
  res
}

#' Cosecha cruda: invoca el motor para 1+ urls rotando cuentas del pool
#'
#' Reusa UN solo navegador por cuenta para todas las `urls` (batch). Si el
#' motor corta (cupo del endpoint agotado, sesion vencida, cuenta suspendida),
#' pausa o desactiva esa cuenta en el pool y retoma la url cortada con la
#' siguiente cuenta disponible: el motor inyecta el ultimo cursor de paginacion
#' obtenido en la primera request de la app, asi que la recoleccion sigue desde
#' donde quedo en vez de volver al principio. El cupo se cuenta por la primera
#' operacion de `op_names`.
#'
#' @param n Cantidad buscada por url (de `unit`: "tweets" o "users"). Al
#'   alcanzarla el motor deja de scrollear, sin gastar cupo de mas. NULL
#'   scrollea hasta `max_scrolls` o hasta que no lleguen datos nuevos.
#' @return Lista con un elemento por url (`url`, `bodies`).
#' @noRd
.pw_harvest_raw <- function(urls, op_names, max_scrolls = 25, n = NULL, unit = "tweets") {
  op <- op_names[[1]]
  bodies <- rep(list(character(0)), length(urls))
  cursors <- rep(NA_character_, length(urls))
  found <- integer(length(urls))
  pending <- seq_along(urls)
  last_disabled <- NULL
  while (length(pending)) {
    acc <- .pool_acquire_wait(op)
    if (!length(acc)) {
      msg <- if (identical(attr(acc, "reason"), "busy")) {
        paste0("Todas las cuentas est\u00e1n en pausa para ", op, " hasta las ",
               .pool_hms(attr(acc, "next_at")), ".")
      } else if (identical(last_disabled, "expired")) {
        "Tu sesi\u00f3n de X parece haber expirado. Reimportala con importSessionX(auth_token, ct0)."
      } else {
        "No hay una sesi\u00f3n activa de X. Import\u00e1 tu sesi\u00f3n con importSessionX(auth_token, ct0)."
      }
      if (any(lengths(bodies) > 0)) {
        warning(msg, " Se devuelven los datos recolectados hasta el corte.", call. = FALSE)
        break
      }
      stop(msg, call. = FALSE)
    }

    params <- list(storageStatePath = acc$state_path, urls = as.list(urls[pending]),
                   opNames = as.list(op_names), maxScrolls = max_scrolls)
    if (!is.null(n)) {
      params$targets <- as.list(pmax(as.integer(n) - found[pending], 1L))
      params$unit <- unit
    }
    if (any(!is.na(cursors[pending]))) {
      # NA logico -> null en el JSON: esa url arranca sin cursor.
      params$cursors <- lapply(cursors[pending], function(cu) if (is.na(cu)) NA else cu)
    }
    proxy <- .pool_proxy(acc)
    if (!is.null(proxy)) params$proxy <- proxy
    if (!is.na(acc$user_agent)) params$userAgent <- acc$user_agent
    dump <- getOption("TweetScraperR.debug_dir")
    if (!is.null(dump)) params$dumpDir <- dump

    res <- .pw_harvest_with(acc, op, params)
    if (!isTRUE(res$ok)) {
      .pool_release(acc$username, op)
      stop("La cosecha de la API fall\u00f3: ", .pw_or(res$error, "error desconocido"), call. = FALSE)
    }
    sent <- pending
    n_resp <- 0L
    for (i in seq_along(res$results)) {
      r <- res$results[[i]]
      j <- sent[i]
      b <- unlist(r$bodies)
      bodies[[j]] <- c(bodies[[j]], b)
      n_resp <- n_resp + length(b)
      found[j] <- found[j] + as.integer(.pw_or(r$count, 0L))
      if (!is.null(r$cursor)) cursors[j] <- r$cursor
    }
    rl <- res$rateLimits[[op]]
    stopped <- .pw_or(res$stopped, "")

    if (!nzchar(stopped)) {
      .pool_release(acc$username, op, if (isTRUE(rl$remaining == 0)) rl$reset else 0L, n_resp)
      break
    }
    pending <- sent[res$stoppedAt:length(sent)]
    if (stopped %in% c("rate_limited", "blocked")) {
      now <- .pool_now()
      reset <- .pw_or(rl$reset, 0L)
      until <- if (stopped == "rate_limited" && reset > now) reset else now + 900L
      .pool_release(acc$username, op, until, n_resp)
      message(
        "Cuenta \"", acc$username, "\": ",
        if (stopped == "blocked") "X devolvi\u00f3 una p\u00e1gina de bloqueo" else paste0("cupo de ", op, " agotado"),
        "; en pausa hasta las ", .pool_hms(until), ". Se retoma con la siguiente cuenta disponible."
      )
    } else {
      msg <- .pw_or(unname(.pw_disable_msgs[stopped]), stopped)
      .pool_disable(acc$username, op, msg, n_resp)
      last_disabled <- stopped
      message("Cuenta \"", acc$username, "\" desactivada: ", msg, ".")
    }
  }
  lapply(seq_along(urls), function(i) list(url = urls[i], bodies = bodies[[i]]))
}

#' Cosecha de UNA url -> lista de respuestas JSON parseadas (listas anidadas)
#'
#' Los bodies no-JSON (p.ej. el texto plano "Rate limit exceeded" de X cuando
#' corta el ventanal) se saltean con un aviso en vez de frenar la recoleccion.
#' @noRd
.pw_harvest <- function(url, op_names, max_scrolls = 25, n = NULL, unit = "tweets") {
  results <- .pw_harvest_raw(url, op_names, max_scrolls, n, unit)
  lapply(results[[1]]$bodies, .pw_parse_body)
}

#' Cosecha de VARIAS urls en un solo navegador -> lista (por url) de respuestas
#' @noRd
.pw_harvest_batch <- function(urls, op_names, max_scrolls = 25, n = NULL, unit = "tweets") {
  results <- .pw_harvest_raw(urls, op_names, max_scrolls, n, unit)
  lapply(results, function(rr) {
    lapply(rr$bodies, .pw_parse_body)
  })
}

#' Tope de scrolls para juntar `n` items
#'
#' Es solo un techo de seguridad: el motor deja de scrollear apenas llega a
#' `n` o cuando X deja de mandar datos nuevos.
#' @noRd
.scrolls_for <- function(n) max(5L, as.integer(ceiling(n / 10) + 5L))

#' Parsea un body crudo a lista R anidada (detallada y tolerante)
#'
#' simplifyVector = FALSE garantiza que todo doc sea una lista R estricta, los
#' parsers asumen eso. Un body no-JSON se reporta y devuelve NULL (lo saltean
#' los callers que iteran docs y chequean NULL).
#' @noRd
.pw_parse_body <- function(b) {
  tryCatch(
    jsonlite::fromJSON(b, simplifyVector = FALSE),
    error = function(e) {
      warning("Respuesta no-JSON del motor salteada: ", substr(b, 1, 120))
      NULL
    }
  )
}

#' Comprobar que el motor Node/Playwright esta instalado y operativo
#'
#' Ejecuta el comando `doctor` del motor y devuelve la informacion de versiones.
#'
#' @return Invisiblemente, una lista con `ok`, version de Playwright, version
#'   de Node y ruta de Chromium. Lanza un error si el motor no responde.
#' @export
#'
#' @examples
#' \dontrun{
#' checkPlaywrightEngine()
#' }
checkPlaywrightEngine <- function() {
  res <- .pw_call("doctor", list(), timeout = 60)
  if (!isTRUE(res$ok)) {
    stop("El motor Playwright no respondi\u00f3 correctamente: ", .pw_or(res$error, "error desconocido"))
  }
  message("Motor Playwright OK \u2014 Playwright ", res$playwright, " | Node ", res$node)
  invisible(res)
}

#' Instalar el motor Node/Playwright (npm install + navegador)
#'
#' Copia el motor (`inst/node`) a la carpeta de cache del usuario
#' (`tools::R_user_dir("TweetScraperR", "cache")`) y ejecuta alli
#' `npm install`, que instala 'Playwright', 'playwright-extra' y su plugin
#' 'stealth' (ajustes de compatibilidad para que el navegador automatizado se
#' presente como un 'Chromium' de escritorio estandar) y descarga el navegador
#' 'Chromium'. Nada de esto ocurre al instalar el paquete: hay que llamar a esta
#' funcion explicitamente, una vez por maquina, antes de usar las funciones de
#' recoleccion. Requiere 'Node.js' (>= 18) con 'npm' y conexion a internet.
#'
#' @param npm Ruta al binario de npm (por defecto "npm" del PATH).
#'
#' @return Invisiblemente, el codigo de salida de npm (0 si todo salio bien).
#' @export
#'
#' @examples
#' \dontrun{
#' installPlaywrightEngine()
#' }
installPlaywrightEngine <- function(npm = "npm") {
  if (Sys.which(npm) == "" && !file.exists(npm)) {
    stop("No se encontr\u00f3 npm. Instal\u00e1 Node.js (>= 18), que incluye npm.")
  }
  dir <- .pw_cache_dir()
  src <- system.file("node", package = "TweetScraperR")
  if (!nzchar(src) || !dir.exists(src)) {
    stop("No se encontr\u00f3 el c\u00f3digo del motor (inst/node) en el paquete instalado.")
  }
  for (f in c("tsr-engine.js", "package.json")) {
    fp <- file.path(src, f)
    if (file.exists(fp)) {
      ok <- file.copy(fp, dir, overwrite = TRUE)
      if (!ok) stop("No se pudo copiar el motor a ", dir)
    }
  }
  message("Instalando el motor Playwright en ", dir, " (esto puede tardar)...")
  status <- system2(npm, args = c("install", "--prefix", shQuote(dir)), stdout = "", stderr = "")
  if (!identical(status, 0L)) {
    stop("npm install fall\u00f3 (c\u00f3digo ", status, ").")
  }
  message("Motor Playwright instalado.")
  invisible(status)
}

#' Iniciar sesion en X/Twitter con Playwright y guardar la sesion
#'
#' Abre un navegador 'Chromium' controlado por 'Playwright', realiza el login
#' en X/Twitter con el flujo del modal actual y guarda la sesion autenticada
#' (cookies + storage) como una cuenta del pool. Las demas funciones del
#' paquete reusan esa sesion sin volver a loguearse, lo que evita inicios de
#' sesion repetidos. La via recomendada es [importSessionX()], que reutiliza la
#' sesion de tu navegador habitual.
#'
#' @param xuser Usuario de X/Twitter. Por defecto la variable de entorno
#'   TWITTER_USER (con fallback a USER).
#' @param xpass Contrasena de X/Twitter. Por defecto la variable de entorno
#'   TWITTER_PASS (con fallback a PASS).
#' @param email Correo para el paso de verificacion de identidad, si X lo pide.
#'   Por defecto la variable de entorno TWITTER_EMAIL.
#' @param headless Logico. Si TRUE (por defecto) corre el navegador sin
#'   interfaz. Pone FALSE para ver/depurar el login.
#' @param account Nombre local de la cuenta en el pool. Por defecto "default".
#' @param proxy Proxy opcional para rutear el trafico (p. ej. en redes que
#'   exigen salir por un proxy).
#'   Acepta un string "http://host:puerto" o "usuario:clave@host:puerto", o una
#'   lista list(server=, username=, password=). Si es un string queda guardado
#'   como proxy de la cuenta.
#'
#' @return Invisiblemente, el nombre de la cuenta. Lanza un error si el login
#'   falla o si X limita el intento.
#' @export
#'
#' @examples
#' \dontrun{
#' loginX(xuser = "mi_usuario", xpass = Sys.getenv("TWITTER_PASS"),
#'        headless = FALSE)
#' }
loginX <- function(xuser = Sys.getenv("TWITTER_USER", Sys.getenv("USER")),
                   xpass = Sys.getenv("TWITTER_PASS", Sys.getenv("PASS")),
                   email = Sys.getenv("TWITTER_EMAIL", ""),
                   headless = TRUE,
                   account = "default",
                   proxy = NULL) {
  state <- .pw_or(.pool_state_of(account), .pool_session_path(account))
  res <- .pw_login(xuser, xpass, email, state = state, headless = headless, proxy = proxy)
  if (isTRUE(res$ok)) {
    .pool_upsert(account, state, proxy = if (is.character(proxy)) proxy else NULL)
    message("Login OK. Sesi\u00f3n guardada en la cuenta \"", account, "\" del pool.")
    return(invisible(account))
  }
  if (isTRUE(res$limited)) {
    stop("X limit\u00f3 temporalmente el inicio de sesi\u00f3n (rate-limit). Esper\u00e1 un rato y reintent\u00e1. URL: ", .pw_or(res$url, "?"))
  }
  stop("Login fallido (", .pw_or(res$reason, "desconocido"), "). ", substr(.pw_or(res$hint, ""), 1, 200))
}
