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
#'   casos exige que el motor tenga sus dependencias de npm ya instaladas.
.pw_engine_dir <- function() {
  d <- .pw_cache_dir(create = FALSE)
  if (file.exists(file.path(d, "tsr-engine.js")) &&
      dir.exists(file.path(d, "node_modules"))) {
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

#' Ruta por defecto del storageState (sesion autenticada persistente)
#' @noRd
.pw_state_path <- function() {
  d <- tools::R_user_dir("TweetScraperR", "data")
  if (!dir.exists(d)) dir.create(d, recursive = TRUE)
  file.path(d, "x-storage-state.json")
}

#' Invoca un comando del motor Node y devuelve el resultado parseado
#'
#' @param cmd Comando del motor ("doctor", "login", "collect").
#' @param params Lista de parametros (se serializa a JSON y va por stdin).
#' @param timeout Timeout en segundos.
#'
#' @return Lista con el JSON de respuesta del motor mas `.stderr` y `.exit`.
#' @noRd
#' @description En Windows `system2(stdout = TRUE)` parte las lineas largas
#'   (>8KB por el limite de pipe de MSVCRT) y corrompe el JSON del motor, por
#'   lo que la salida estandar siempre se redirige a un archivo temporal y se
#'   vuelve a leer intacta.
.pw_call <- function(cmd, params = list(), timeout = 300, simplify = TRUE) {
  script <- file.path(.pw_engine_dir(), "tsr-engine.js")
  json <- jsonlite::toJSON(params, auto_unbox = TRUE, null = "null")
  errfile <- tempfile(fileext = ".log")
  outfile <- tempfile(fileext = ".json")
  on.exit(unlink(c(errfile, outfile)), add = TRUE)
  out <- suppressWarnings(system2(
    .pw_node(),
    args = c(shQuote(script), cmd),
    input = json,
    stdout = outfile,
    stderr = errfile,
    timeout = timeout
  ))
  status <- if (is.character(out)) attr(out, "status") else out
  stderr_chr <- tryCatch(readLines(errfile, warn = FALSE), error = function(e) character(0))
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
        msg <- paste0(msg, " | stderr: ", paste(tail(stderr_chr, 5), collapse = " "))
      }
      list(ok = FALSE, error = msg)
    }
  )
  if (!is.list(res)) res <- list(ok = FALSE, error = "respuesta inesperada del motor")
  res$.stderr <- stderr_chr
  res$.exit <- if (is.null(status)) 0L else status
  res
}

#' Login de bajo nivel via motor Node
#' @noRd
.pw_login <- function(xuser, xpass, email = "", state = .pw_state_path(),
                      headless = TRUE, proxy = NULL) {
  params <- list(
    user = xuser, pass = xpass, email = email,
    storageStatePath = state, headless = headless,
    shotDir = tempdir()
  )
  if (!is.null(proxy)) params$proxy <- proxy
  .pw_call("login", params, timeout = 180)
}

#' Recoleccion de bajo nivel via motor Node (reusa storageState, sin re-login)
#' @noRd
.pw_collect <- function(url, mode = c("articles", "urls", "users"), n_max = 100,
                        state = .pw_state_path(), max_attempts = 3,
                        scroll_px = 4000, wait_ms = 2500, headless = TRUE,
                        proxy = NULL) {
  mode <- match.arg(mode)
  params <- list(
    storageStatePath = state, url = url, mode = mode, nMax = n_max,
    maxAttempts = max_attempts, scrollPx = scroll_px, waitMs = wait_ms,
    headless = headless
  )
  if (!is.null(proxy)) params$proxy <- proxy
  .pw_call("collect", params, timeout = 600)
}

#' Cosecha cruda: invoca el motor para 1+ urls y devuelve los resultados por url
#'
#' Reusa UN solo navegador para todas las `urls` (batch). Maneja sesion no
#' iniciada / expirada y avisa si el rate-limit de X esta bajo. Devuelve la lista
#' `results` del motor (un elemento por url, cada uno con `url` y `bodies`).
#' @noRd
.pw_harvest_raw <- function(urls, op_names, max_scrolls = 25, state = .pw_state_path()) {
  res <- .pw_call("harvest", list(
    storageStatePath = state, urls = as.list(urls),
    opNames = as.list(op_names), maxScrolls = max_scrolls
  ), timeout = 900, simplify = FALSE)
  if (isTRUE(res$reason == "not_logged_in")) {
    stop("No hay una sesi\u00f3n activa de X. Import\u00e1 tu sesi\u00f3n con importSessionX(auth_token, ct0).")
  }
  if (isTRUE(res$expired)) {
    stop("Tu sesi\u00f3n de X parece haber expirado. Reimportala con importSessionX(auth_token, ct0).")
  }
  if (!isTRUE(res$ok)) {
    stop("La cosecha de la API fall\u00f3: ", .pw_or(res$error, .pw_or(res$reason, "error desconocido")))
  }
  rl <- res$rateLimit
  if (!is.null(rl$remaining) && !is.na(rl$remaining) && rl$remaining < 10) {
    warning("Rate-limit de X bajo: quedan ", rl$remaining,
            " consultas para este endpoint antes de un corte temporal.")
  }
  if (is.null(res$results)) list() else res$results
}

#' Cosecha de UNA url -> lista de respuestas JSON parseadas (listas anidadas)
#'
#' Los bodies no-JSON (p.ej. el texto plano "Rate limit exceeded" de X cuando
#' corta el ventanal) se saltean con un aviso en vez de frenar la recoleccion.
#' @noRd
.pw_harvest <- function(url, op_names, max_scrolls = 25, state = .pw_state_path()) {
  results <- .pw_harvest_raw(url, op_names, max_scrolls, state)
  if (!length(results)) return(list())
  bodies <- results[[1]]$bodies
  lapply(bodies, .pw_parse_body)
}

#' Cosecha de VARIAS urls en un solo navegador -> lista (por url) de respuestas
#' @noRd
.pw_harvest_batch <- function(urls, op_names, max_scrolls = 25, state = .pw_state_path()) {
  results <- .pw_harvest_raw(urls, op_names, max_scrolls, state)
  lapply(results, function(rr) {
    lapply(rr$bodies, .pw_parse_body)
  })
}

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
#' @return Una lista con `ok`, version de Playwright, version de Node y ruta de
#'   Chromium. Lanza un error si el motor no responde.
#' @export
checkPlaywrightEngine <- function() {
  res <- .pw_call("doctor", list(), timeout = 60)
  if (!isTRUE(res$ok)) {
    stop("El motor Playwright no respondi\u00f3 correctamente: ", .pw_or(res$error, "error desconocido"))
  }
  message("Motor Playwright OK \u2014 Playwright ", res$playwright, " | Node ", res$node)
  invisible(res)
}

#' Instalar el motor Node/Playwright (npm install + browsers)
#'
#' Ejecuta `npm install` dentro de inst/node, lo que instala Playwright, el
#' plugin stealth y descarga el navegador Chromium. Hay que correrlo una vez
#' por maquina antes de usar las funciones de scraping.
#'
#' @param npm Ruta al binario de npm (por defecto "npm" del PATH).
#'
#' @return Invisiblemente, el codigo de salida de npm.
#' @export
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

#' Importar una sesion de X/Twitter desde las cookies de tu navegador
#'
#' Como X bloquea el login automatizado (detecta el navegador de Playwright por
#' fingerprint), la via robusta es: logueate a mano en tu navegador normal y
#' pasale a esta funcion las cookies `auth_token` y `ct0` de tu sesion (las
#' encontras en DevTools -> Application/Almacenamiento -> Cookies -> x.com).
#' La sesion queda guardada (storageState) y todas las funciones de scraping la
#' reusan sin volver a loguearse.
#'
#' @param auth_token Valor de la cookie `auth_token` de x.com.
#' @param ct0 Valor de la cookie `ct0` de x.com.
#' @param state Ruta donde guardar la sesion. Por defecto la ubicacion estandar
#'   del paquete, que las demas funciones leen automaticamente.
#'
#' @return Invisiblemente, la ruta del archivo de sesion.
#' @export
importSessionX <- function(auth_token, ct0, state = .pw_state_path()) {
  if (missing(auth_token) || !nzchar(auth_token) || missing(ct0) || !nzchar(ct0)) {
    stop("Necesito ambos valores: auth_token y ct0 (cookies de x.com).")
  }
  mk <- function(name, value, http_only) {
    list(name = name, value = value, domain = ".x.com", path = "/",
         expires = -1L, httpOnly = http_only, secure = TRUE, sameSite = "Lax")
  }
  st <- list(
    cookies = list(mk("auth_token", auth_token, TRUE), mk("ct0", ct0, FALSE)),
    origins = list()
  )
  writeLines(jsonlite::toJSON(st, auto_unbox = TRUE), state)
  message("Sesi\u00f3n importada y guardada en: ", state)
  invisible(state)
}

#' Iniciar sesion en X/Twitter con Playwright y guardar la sesion
#'
#' Abre un navegador Chromium con tecnicas anti-deteccion (stealth), realiza el
#' login en X/Twitter con el flujo del modal actual y guarda la sesion
#' autenticada (cookies + storage) en disco. Las demas funciones del paquete
#' reusan esa sesion sin volver a loguearse, lo que evita el rate-limit de X.
#'
#' @param xuser Usuario de X/Twitter. Por defecto la variable de entorno
#'   TWITTER_USER (con fallback a USER).
#' @param xpass Contrasena de X/Twitter. Por defecto la variable de entorno
#'   TWITTER_PASS (con fallback a PASS).
#' @param email Correo para el paso de verificacion de identidad, si X lo pide.
#'   Por defecto la variable de entorno TWITTER_EMAIL.
#' @param headless Logico. Si TRUE (por defecto) corre el navegador sin
#'   interfaz. Pone FALSE para ver/depurar el login.
#' @param state Ruta del archivo donde se guarda la sesion (storageState).
#' @param proxy Proxy opcional para rutear el trafico (util si X bloquea tu IP).
#'   Acepta un string "http://host:puerto" o "usuario:clave@host:puerto", o una
#'   lista list(server=, username=, password=).
#'
#' @return Invisiblemente, la ruta del archivo de sesion. Lanza un error si el
#'   login falla o si X limita el intento.
#' @export
loginX <- function(xuser = Sys.getenv("TWITTER_USER", Sys.getenv("USER")),
                   xpass = Sys.getenv("TWITTER_PASS", Sys.getenv("PASS")),
                   email = Sys.getenv("TWITTER_EMAIL", ""),
                   headless = TRUE,
                   state = .pw_state_path(),
                   proxy = NULL) {
  res <- .pw_login(xuser, xpass, email, state = state, headless = headless, proxy = proxy)
  if (isTRUE(res$ok)) {
    message("Login OK. Sesi\u00f3n guardada en: ", state)
    return(invisible(state))
  }
  if (isTRUE(res$limited)) {
    stop("X limit\u00f3 temporalmente el inicio de sesi\u00f3n (rate-limit). Esper\u00e1 un rato y reintent\u00e1. URL: ", .pw_or(res$url, "?"))
  }
  stop("Login fallido (", .pw_or(res$reason, "desconocido"), "). ", substr(.pw_or(res$hint, ""), 1, 200))
}
