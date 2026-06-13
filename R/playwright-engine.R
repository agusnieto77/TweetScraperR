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

#' Directorio del motor Node (inst/node)
#' @noRd
.pw_engine_dir <- function() {
  d <- system.file("node", package = "TweetScraperR")
  if (!nzchar(d) || !dir.exists(d)) {
    stop("No se encontr\u00f3 el motor Node (inst/node). \u00bfInstalaste el motor con installPlaywrightEngine()?")
  }
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
.pw_call <- function(cmd, params = list(), timeout = 300) {
  script <- file.path(.pw_engine_dir(), "tsr-engine.js")
  json <- jsonlite::toJSON(params, auto_unbox = TRUE, null = "null")
  errfile <- tempfile(fileext = ".log")
  on.exit(unlink(errfile), add = TRUE)
  out <- suppressWarnings(system2(
    .pw_node(),
    args = c(shQuote(script), cmd),
    input = json,
    stdout = TRUE,
    stderr = errfile,
    timeout = timeout
  ))
  status <- attr(out, "status")
  txt <- paste(out, collapse = "\n")
  res <- tryCatch(
    jsonlite::fromJSON(txt, simplifyVector = TRUE),
    error = function(e) list(ok = FALSE, error = paste0("salida no-JSON del motor: ", substr(txt, 1, 300)))
  )
  if (!is.list(res)) res <- list(ok = FALSE, error = "respuesta inesperada del motor")
  res$.stderr <- tryCatch(readLines(errfile, warn = FALSE), error = function(e) character(0))
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
  dir <- .pw_engine_dir()
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
