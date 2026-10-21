# Pool de cuentas de X (SQLite) --------------------------------------------
#
# Modelo portado de twscrape (accounts_pool.py, MIT): cada cuenta guarda su
# sesion (storageState), un proxy opcional y, por operacion GraphQL, un
# bloqueo `locks` (unix ts hasta el que no se usa) y un contador `stats`.
# El bloqueo es por (cuenta, operacion): una cuenta sin cupo en SearchTimeline
# sigue sirviendo para UserTweets. La cuenta se toma con un UPDATE ... RETURNING
# atomico, asi que varias sesiones de R en paralelo no toman la misma.

#' Directorio de datos del paquete (sesiones y base del pool)
#' @noRd
.tsr_data_dir <- function() {
  d <- getOption("TweetScraperR.data_dir", tools::R_user_dir("TweetScraperR", "data"))
  if (!dir.exists(d)) dir.create(d, recursive = TRUE)
  d
}

#' Ruta de la sesion de una sola cuenta de las versiones previas al pool
#' @noRd
.pw_state_path <- function() file.path(.tsr_data_dir(), "x-storage-state.json")

#' Ruta del storageState de una cuenta nueva del pool
#' @noRd
.pool_session_path <- function(account) {
  d <- file.path(.tsr_data_dir(), "sessions")
  if (!dir.exists(d)) dir.create(d, recursive = TRUE)
  file.path(d, paste0(gsub("[^A-Za-z0-9_.-]", "_", account), ".json"))
}

#' Tiempo maximo que una cuenta queda tomada mientras se usa
#'
#' Cubre el timeout de la cosecha (.pw_harvest_raw) mas un margen: si R muere a
#' mitad de camino, la cuenta se libera sola al vencer.
#' @noRd
.pool_hold_secs <- 960

.pool_now <- function() as.integer(Sys.time())

#' Ruta JSON de una operacion dentro de locks/stats
#' @noRd
.pool_op_path <- function(op) {
  if (!grepl("^[A-Za-z0-9_]+$", op)) stop("Nombre de operaci\u00f3n inv\u00e1lido: ", op)
  paste0("$.\"", op, "\"")
}

#' Abre la base del pool (creandola y migrandola si hace falta) y ejecuta f(con)
#' @noRd
.pool_with <- function(f) {
  con <- DBI::dbConnect(RSQLite::SQLite(), file.path(.tsr_data_dir(), "accounts.sqlite"))
  on.exit(DBI::dbDisconnect(con), add = TRUE)
  # Otra sesion de R escribiendo: esperar en lugar de fallar con "database is locked".
  DBI::dbExecute(con, "PRAGMA busy_timeout = 10000")
  .pool_migrate(con)
  f(con)
}

#' Migraciones versionadas con PRAGMA user_version
#' @noRd
.pool_migrate <- function(con) {
  uv <- DBI::dbGetQuery(con, "PRAGMA user_version")[[1]]
  if (uv < 1L) {
    DBI::dbWithTransaction(con, {
      DBI::dbExecute(con, "
        CREATE TABLE IF NOT EXISTS accounts (
          username   TEXT PRIMARY KEY NOT NULL COLLATE NOCASE,
          state_path TEXT NOT NULL,
          proxy      TEXT,
          user_agent TEXT,
          active     INTEGER NOT NULL DEFAULT 1,
          locks      TEXT NOT NULL DEFAULT '{}',
          stats      TEXT NOT NULL DEFAULT '{}',
          last_used  INTEGER,
          error_msg  TEXT,
          added_at   INTEGER NOT NULL
        )")
      # La sesion unica de las versiones anteriores pasa a ser la cuenta "default".
      legacy <- .pw_state_path()
      if (file.exists(legacy)) {
        DBI::dbExecute(con,
          "INSERT OR IGNORE INTO accounts (username, state_path, added_at) VALUES ('default', ?, ?)",
          params = list(legacy, .pool_now()))
      }
      DBI::dbExecute(con, "PRAGMA user_version = 1")
    })
  }
  if (uv < 2L) {
    # @usuario real de X detras de cada cuenta (lo completa checkAccountsX()).
    DBI::dbWithTransaction(con, {
      DBI::dbExecute(con, "ALTER TABLE accounts ADD COLUMN screen_name TEXT")
      DBI::dbExecute(con, "PRAGMA user_version = 2")
    })
  }
  invisible()
}

#' Da de alta o actualiza una cuenta (conserva bloqueos y estadisticas)
#'
#' Al reimportar una cuenta se reactiva y se borra su error. `proxy` y
#' `user_agent` solo se pisan si se pasan.
#' @noRd
.pool_upsert <- function(account, state_path, proxy = NULL, user_agent = NULL) {
  .pool_with(function(con) {
    DBI::dbExecute(con, "
      INSERT INTO accounts (username, state_path, proxy, user_agent, added_at)
      VALUES (:u, :s, :p, :ua, :now)
      ON CONFLICT(username) DO UPDATE SET
        state_path = excluded.state_path,
        proxy      = COALESCE(excluded.proxy, proxy),
        user_agent = COALESCE(excluded.user_agent, user_agent),
        active     = 1,
        error_msg  = NULL",
      params = list(u = account, s = state_path, p = .pool_na(proxy),
                    ua = .pool_na(user_agent), now = .pool_now()))
  })
  invisible(account)
}

.pool_na <- function(x) if (is.null(x) || !nzchar(x)) NA_character_ else x

#' storageState registrado para una cuenta (NULL si no existe)
#' @noRd
.pool_state_of <- function(account) {
  r <- .pool_with(function(con) {
    DBI::dbGetQuery(con, "SELECT state_path FROM accounts WHERE username = ?", params = list(account))
  })
  if (nrow(r)) r$state_path[1] else NULL
}

#' Toma la cuenta activa usada hace mas tiempo que este libre para `op`
#'
#' La deja bloqueada para `op` por .pool_hold_secs hasta que se libere con
#' .pool_release(). Devuelve una lista (fila de la tabla) o NULL.
#' @noRd
.pool_acquire <- function(op) {
  now <- .pool_now()
  r <- .pool_with(function(con) {
    DBI::dbGetQuery(con, "
      UPDATE accounts SET
        locks = json_set(locks, :path, :hold),
        last_used = :now
      WHERE username = (
        SELECT username FROM accounts
        WHERE active = 1 AND COALESCE(json_extract(locks, :path), 0) <= :now
        ORDER BY COALESCE(last_used, 0), username
        LIMIT 1
      )
      RETURNING *",
      params = list(path = .pool_op_path(op), hold = now + .pool_hold_secs, now = now))
  })
  if (!nrow(r)) return(NULL)
  as.list(r[1, , drop = FALSE])
}

#' Libera una cuenta tras usarla para `op`
#'
#' @param until Unix ts hasta el que la cuenta no se usa para `op` (cupo
#'   agotado). 0 la deja libre.
#' @param n Respuestas obtenidas, se suman a las estadisticas de `op`.
#' @noRd
.pool_release <- function(account, op, until = 0L, n = 0L) {
  path <- .pool_op_path(op)
  .pool_with(function(con) {
    DBI::dbExecute(con, "
      UPDATE accounts SET
        locks = CASE WHEN :until > :now THEN json_set(locks, :path, :until)
                     ELSE json_remove(locks, :path) END,
        stats = json_set(stats, :path, COALESCE(json_extract(stats, :path), 0) + :n),
        last_used = :now
      WHERE username = :u",
      params = list(path = path, until = as.integer(until), now = .pool_now(),
                    n = as.integer(n), u = account))
  })
  invisible()
}

#' Desactiva una cuenta (sesion vencida, suspendida o bloqueada por X)
#' @noRd
.pool_disable <- function(account, op, error_msg, n = 0L) {
  path <- .pool_op_path(op)
  .pool_with(function(con) {
    DBI::dbExecute(con, "
      UPDATE accounts SET
        active = 0, error_msg = :msg,
        locks = json_remove(locks, :path),
        stats = json_set(stats, :path, COALESCE(json_extract(stats, :path), 0) + :n)
      WHERE username = :u",
      params = list(msg = error_msg, path = path, n = as.integer(n), u = account))
  })
  invisible()
}

#' Cuantas cuentas activas hay y cuando se libera la primera para `op`
#' @noRd
.pool_status <- function(op) {
  r <- .pool_with(function(con) {
    DBI::dbGetQuery(con, "
      SELECT COUNT(*) AS n_active,
             MIN(COALESCE(json_extract(locks, :path), 0)) AS next_at
      FROM accounts WHERE active = 1",
      params = list(path = .pool_op_path(op)))
  })
  list(n_active = as.integer(r$n_active), next_at = as.integer(.pw_or(r$next_at, NA)))
}

.pool_hms <- function(ts) format(as.POSIXct(ts, origin = "1970-01-01"), "%H:%M:%S")

#' Toma una cuenta para `op`, esperando si todas estan en pausa
#'
#' Espera como maximo getOption("TweetScraperR.wait_timeout", 900) segundos
#' (una ventana de rate-limit de X). Si la primera cuenta se libera despues de
#' ese plazo no espera en vano. Devuelve la cuenta, o NULL con el atributo
#' `reason` ("none": no hay cuentas activas; "busy": todas en pausa) y
#' `next_at`.
#' @noRd
.pool_acquire_wait <- function(op) {
  deadline <- .pool_now() + getOption("TweetScraperR.wait_timeout", 900)
  announced <- FALSE
  repeat {
    acc <- .pool_acquire(op)
    if (!is.null(acc)) return(acc)
    st <- .pool_status(op)
    if (st$n_active == 0L) return(structure(list(), reason = "none"))
    if (st$next_at > deadline) return(structure(list(), reason = "busy", next_at = st$next_at))
    if (!announced) {
      message("Todas las cuentas est\u00e1n en pausa para ", op, "; se libera una a las ",
              .pool_hms(st$next_at), ". Esperando...")
      announced <- TRUE
    }
    Sys.sleep(min(max(st$next_at - .pool_now(), 1), 5))
  }
}

#' Proxy efectivo de una cuenta: el propio, o el global del paquete
#' @noRd
.pool_proxy <- function(acc) {
  p <- acc$proxy
  if (!is.null(p) && !is.na(p) && nzchar(p)) return(p)
  p <- getOption("TweetScraperR.proxy", Sys.getenv("TWEETSCRAPERR_PROXY", ""))
  if (nzchar(p)) p else NULL
}

#' Extrae auth_token y ct0 de un export de cookies
#'
#' Acepta el header "auth_token=...; ct0=..." (DevTools, unjar), un objeto
#' JSON `{"auth_token": ..., "ct0": ...}` o el array JSON de extensiones como
#' Cookie-Editor (`[{"name": ..., "value": ...}, ...]`).
#' @noRd
.parse_cookies <- function(x) {
  x <- trimws(paste(x, collapse = "\n"))
  vals <- list()
  if (startsWith(x, "{") || startsWith(x, "[")) {
    j <- jsonlite::fromJSON(x, simplifyVector = FALSE)
    if (!is.null(names(j))) {
      vals <- j
    } else {
      for (ck in j) vals[[.pw_or(ck$name, "")]] <- ck$value
    }
  } else {
    for (kv in strsplit(x, ";", fixed = TRUE)[[1]]) {
      kv <- trimws(kv)
      eq <- regexpr("=", kv, fixed = TRUE)
      if (eq > 0) vals[[substr(kv, 1, eq - 1)]] <- substr(kv, eq + 1, nchar(kv))
    }
  }
  list(auth_token = vals$auth_token, ct0 = vals$ct0)
}

#' Escribe un storageState de Playwright con las cookies de sesion de X
#' @noRd
.write_session <- function(auth_token, ct0, path) {
  mk <- function(name, value, http_only) {
    list(name = name, value = value, domain = ".x.com", path = "/",
         expires = -1L, httpOnly = http_only, secure = TRUE, sameSite = "Lax")
  }
  st <- list(
    cookies = list(mk("auth_token", auth_token, TRUE), mk("ct0", ct0, FALSE)),
    origins = list()
  )
  writeLines(jsonlite::toJSON(st, auto_unbox = TRUE), path)
  invisible(path)
}

#' Importar una sesion de X/Twitter desde las cookies de tu navegador
#'
#' La via recomendada para autenticarse es iniciar sesion a mano en tu
#' navegador habitual y pasarle a esta funcion las cookies `auth_token` y `ct0`
#' de tu sesion (las encontras en DevTools -> Application/Almacenamiento ->
#' Cookies -> x.com). La sesion queda guardada en el pool de cuentas (en
#' `tools::R_user_dir("TweetScraperR", "data")`) y todas las funciones de
#' recoleccion la reusan sin volver a loguearse.
#'
#' Importando varias cuentas propias (con distintos `account`) se arma un
#' **pool** que distribuye la carga de trabajo entre ellas: cada cuenta respeta
#' los limites de uso que X informa por endpoint (p. ej. 50 busquedas cada 15
#' minutos) y, cuando una llega a su limite, queda en pausa hasta que X lo
#' renueve mientras la recoleccion continua con otra cuenta disponible. Ver
#' [accountsX()].
#'
#' @param auth_token Valor de la cookie `auth_token` de x.com.
#' @param ct0 Valor de la cookie `ct0` de x.com.
#' @param account Nombre local de la cuenta en el pool. Por defecto "default".
#'   Reimportar con el mismo nombre renueva la sesion y reactiva la cuenta,
#'   conservando su proxy y estadisticas.
#' @param proxy Proxy opcional de esta cuenta ("http://host:puerto",
#'   "usuario:clave@host:puerto" o "socks5://host:puerto"). Tiene prioridad
#'   sobre el proxy global `options(TweetScraperR.proxy = ...)`.
#' @param cookies Alternativa a `auth_token`/`ct0`: el header de cookies
#'   ("auth_token=...; ct0=...") o el JSON exportado por una extension de
#'   cookies (p. ej. Cookie-Editor).
#'
#' @return Invisiblemente, el nombre de la cuenta.
#' @export
#'
#' @examples
#' \dontrun{
#' importSessionX(auth_token = "...", ct0 = "...")
#' importSessionX(cookies = "auth_token=...; ct0=...", account = "cuenta2",
#'                proxy = "http://usuario:clave@host:8080")
#' }
importSessionX <- function(auth_token, ct0, account = "default", proxy = NULL, cookies = NULL) {
  if (!is.null(cookies)) {
    ck <- .parse_cookies(cookies)
    auth_token <- ck$auth_token
    ct0 <- ck$ct0
  }
  if (missing(auth_token) || is.null(auth_token) || !nzchar(auth_token) ||
      missing(ct0) || is.null(ct0) || !nzchar(ct0)) {
    stop("Necesito ambos valores: auth_token y ct0 (cookies de x.com).")
  }
  if (!nzchar(account)) stop("Necesito un nombre de cuenta.")
  state <- .pw_or(.pool_state_of(account), .pool_session_path(account))
  proxy <- .check_proxy(proxy)
  if (is.na(proxy)) proxy <- NULL
  .write_session(auth_token, ct0, state)
  .pool_upsert(account, state, proxy = proxy)
  message("Sesi\u00f3n importada en la cuenta \"", account, "\" del pool.")
  invisible(account)
}

#' Lee un CSV de cuentas detectando el separador y descartando la marca BOM
#' @noRd
.read_accounts_csv <- function(path) {
  header <- readLines(path, n = 1L, warn = FALSE, encoding = "UTF-8")
  seps <- c(",", ";", "\t")
  sep <- seps[which.max(vapply(seps, function(s) lengths(regmatches(header, gregexpr(s, header, fixed = TRUE))), integer(1)))]
  utils::read.csv(path, sep = sep, stringsAsFactors = FALSE, colClasses = "character",
                  fileEncoding = "UTF-8-BOM", strip.white = TRUE)
}

#' Agregar varias cuentas al pool de una vez
#'
#' @param accounts Un data frame, o la ruta a un CSV, con las columnas
#'   `account`, `auth_token` y `ct0`, y opcionalmente `proxy`. El separador
#'   del CSV (`,`, `;` o tabulador) se detecta solo, asi que sirven los CSV
#'   guardados por Excel en configuracion regional en espanol.
#'
#' @return Invisiblemente, los nombres de las cuentas agregadas.
#' @export
#'
#' @examples
#' \dontrun{
#' # cuentas.csv: account,auth_token,ct0,proxy
#' addAccountsX("cuentas.csv")
#' accountsX()
#' }
addAccountsX <- function(accounts) {
  if (is.character(accounts)) {
    accounts <- .read_accounts_csv(accounts)
  }
  names(accounts) <- trimws(tolower(names(accounts)))
  falta <- setdiff(c("account", "auth_token", "ct0"), names(accounts))
  if (length(falta)) stop("Faltan columnas: ", paste(falta, collapse = ", "))
  for (i in seq_len(nrow(accounts))) {
    proxy <- if ("proxy" %in% names(accounts)) accounts$proxy[i] else NULL
    if (!is.null(proxy) && is.na(proxy)) proxy <- NULL
    importSessionX(accounts$auth_token[i], accounts$ct0[i], account = accounts$account[i], proxy = proxy)
  }
  invisible(accounts$account)
}

# Entrada por consola (envueltas para poder simularlas en los tests).
.is_interactive <- function() interactive()
.ask_line <- function(prompt) readline(prompt)
.ask_secret <- function(prompt) {
  # askpass oculta lo tipeado/pegado (dialogo en RStudio, sin eco en terminal).
  x <- askpass::askpass(prompt)
  if (is.null(x)) "" else x
}

#' Cargar y validar cuentas de X desde la consola
#'
#' Asistente interactivo para armar el pool de cuentas sin escribir codigo ni
#' dejar las cookies en el historial de R: pide el nombre de cada cuenta, su
#' `auth_token` y su `ct0` (la entrada queda oculta) y un proxy opcional, la
#' importa con [importSessionX()] y la valida en el momento con
#' [checkAccountsX()]. Se termina dejando el nombre vacio.
#'
#' En el campo `auth_token` tambien se puede pegar el header completo de
#' cookies ("auth_token=...; ct0=...") o el JSON de una extension como
#' Cookie-Editor; en ese caso no se pide `ct0`.
#'
#' Para obtener las cookies de varias cuentas, abri cada una en un perfil de
#' navegador distinto (o en una ventana de incognito aparte) y cerra la
#' ventana **sin cerrar sesion**: cerrar sesion invalida el `auth_token`.
#'
#' @param validate Logico. Si TRUE (por defecto) valida cada cuenta apenas se
#'   carga.
#'
#' @return Invisiblemente, el estado del pool ([accountsX()]).
#' @export
#'
#' @examples
#' \dontrun{
#' setupAccountsX()
#' }
setupAccountsX <- function(validate = TRUE) {
  if (!.is_interactive()) {
    stop("setupAccountsX() es interactiva: ejecutala en la consola de R. ",
         "En scripts, usa importSessionX() o addAccountsX().")
  }
  cat("Carga de cuentas de X. Para cada una, copia las cookies auth_token y ct0 de x.com\n",
      "(F12 -> Application -> Cookies). Deja el nombre en blanco para terminar.\n\n", sep = "")
  repeat {
    account <- trimws(.ask_line("Nombre de la cuenta (Enter para terminar): "))
    if (!nzchar(account)) break
    auth <- trimws(.ask_secret(paste0("auth_token de \"", account, "\" (o el header de cookies): ")))
    if (grepl("auth_token", auth, fixed = TRUE)) {
      ck <- .parse_cookies(auth)
      auth <- .pw_or(ck$auth_token, "")
      ct0 <- .pw_or(ck$ct0, "")
    } else {
      ct0 <- trimws(.ask_secret(paste0("ct0 de \"", account, "\": ")))
    }
    if (!nzchar(auth) || !nzchar(ct0)) {
      message("Faltan auth_token o ct0; se omite \"", account, "\".\n")
      next
    }
    repeat {
      proxy <- tryCatch(.check_proxy(.ask_line("Proxy (opcional, Enter para ninguno): ")),
                        error = function(e) { message(conditionMessage(e)); FALSE })
      if (!isFALSE(proxy)) break
    }
    importSessionX(auth, ct0, account = account, proxy = if (is.na(proxy)) NULL else proxy)
    if (validate) {
      chk <- checkAccountsX(account)
      if (isTRUE(chk$valida)) {
        message("OK: \"", account, "\" es @", chk$usuario_x, ".\n")
      } else {
        message("\"", account, "\" no funciona: ", chk$motivo,
                ". Revisa las cookies y cargala de nuevo con el mismo nombre.\n")
      }
    }
  }
  acc <- accountsX()
  # Cuentas cargadas antes sin validar (p. ej. la "default" de versiones
  # previas): identificarlas permite detectar y reescribir duplicados.
  pendientes <- acc$cuenta[acc$activa & is.na(acc$usuario_x)]
  if (validate && length(pendientes)) {
    checkAccountsX(pendientes)
    acc <- accountsX()
  }
  cat("Pool: ", sum(acc$activa), " cuenta(s) activa(s) de ", nrow(acc), ".\n", sep = "")
  invisible(acc)
}

#' Estado del pool de cuentas de X
#'
#' Lista las cuentas importadas con [importSessionX()], si estan activas, en
#' pausa (y hasta cuando) por endpoint, y cuantas respuestas aportaron.
#'
#' @return Un tibble con una fila por cuenta y columnas: cuenta, usuario_x
#'   (@usuario real, lo completa [checkAccountsX()]), activa, pausas (endpoints
#'   en pausa y hora en que se liberan), requests (total de respuestas
#'   obtenidas), requests_por_endpoint, ultimo_uso, proxy, error.
#' @export
#'
#' @examples
#' \dontrun{
#' accountsX()
#' }
accountsX <- function() {
  r <- .pool_with(function(con) DBI::dbGetQuery(con, "SELECT * FROM accounts ORDER BY active DESC, username"))
  now <- .pool_now()
  pausas <- vapply(r$locks, function(l) {
    l <- unlist(jsonlite::fromJSON(l))
    l <- l[l > now]
    if (!length(l)) return(NA_character_)
    paste0(names(l), " hasta ", .pool_hms(l), collapse = "; ")
  }, character(1), USE.NAMES = FALSE)
  stats <- lapply(r$stats, function(s) unlist(jsonlite::fromJSON(s)))
  tibble::tibble(
    cuenta                = r$username,
    usuario_x             = r$screen_name,
    activa                = as.logical(r$active),
    pausas                = pausas,
    requests              = vapply(stats, function(s) as.integer(sum(s)), integer(1)),
    requests_por_endpoint = vapply(stats, function(s) {
      if (!length(s)) NA_character_ else paste0(names(s), ": ", s, collapse = "; ")
    }, character(1)),
    ultimo_uso            = as.POSIXct(r$last_used, origin = "1970-01-01"),
    proxy                 = r$proxy,
    error                 = r$error_msg
  )
}

#' Validar las sesiones del pool de cuentas
#'
#' Abre X con la sesion de cada cuenta y comprueba que siga autenticada,
#' registrando el @usuario real que hay detras (columna `usuario_x` de
#' [accountsX()]). Las cuentas con sesion vencida o bloqueada se desactivan;
#' las validas se reactivan. No consume cupo de los endpoints de recoleccion.
#' Si dos cuentas del pool resultan ser la misma cuenta de X (p. ej. la
#' "default" de versiones previas cargada de nuevo con otro nombre), se
#' reescribe: queda la agregada mas recientemente, con las pausas y
#' estadisticas de ambas.
#'
#' @param accounts Nombres de las cuentas a validar. Por defecto, todas
#'   (incluidas las desactivadas).
#'
#' @return Un tibble con una fila por cuenta y columnas cuenta, valida,
#'   usuario_x y motivo (por que no es valida).
#' @export
#'
#' @examples
#' \dontrun{
#' importSessionX(cookies = Sys.getenv("X2_COOKIES"), account = "cuenta2")
#' checkAccountsX()
#' }
checkAccountsX <- function(accounts = NULL) {
  r <- .pool_with(function(con) {
    DBI::dbGetQuery(con, "SELECT username, state_path, proxy, user_agent FROM accounts ORDER BY username")
  })
  if (!is.null(accounts)) r <- r[tolower(r$username) %in% tolower(accounts), , drop = FALSE]
  if (!nrow(r)) stop("No hay cuentas para validar. Importalas con importSessionX().")
  rows <- lapply(seq_len(nrow(r)), function(i) {
    acc <- as.list(r[i, , drop = FALSE])
    params <- list(storageStatePath = acc$state_path)
    proxy <- .pool_proxy(acc)
    if (!is.null(proxy)) params$proxy <- proxy
    if (!is.na(acc$user_agent)) params$userAgent <- acc$user_agent
    cat("Validando \"", acc$username, "\"...\n", sep = "")
    res <- .pw_call("whoami", params, timeout = 120)
    valida <- NA
    usuario <- NA_character_
    if (!isTRUE(res$ok)) {
      err <- .pw_or(res$error, "desconocido")
      code <- regmatches(err, regexpr("net::ERR_[A-Z_]+", err))
      motivo <- if (!is.null(proxy) && length(code)) {
        paste0("no se pudo conectar a traves del proxy (", sub("net::", "", code), "): revisa la direccion, ",
               "el usuario y la clave, o quitalo con setProxyX(\"", acc$username, "\", NULL)")
      } else {
        paste("error del motor:", err)
      }
    } else {
      valida <- isTRUE(res$valid)
      usuario <- .pw_or(res$screenName, NA_character_)
      motivo <- if (valida) NA_character_ else switch(.pw_or(res$reason, "unknown"),
        expired = .pw_disable_msgs[["expired"]],
        locked  = "cuenta bloqueada por X (hay que desbloquearla en x.com/account/access)",
        "X no carga la cuenta (error o control pendiente en x.com)"
      )
    }
    .pool_with(function(con) {
      if (isTRUE(valida)) {
        DBI::dbExecute(con, "UPDATE accounts SET active = 1, error_msg = NULL, screen_name = ? WHERE username = ?",
                       params = list(usuario, acc$username))
      } else if (isFALSE(valida) && res$reason %in% c("expired", "locked")) {
        DBI::dbExecute(con, "UPDATE accounts SET active = 0, error_msg = ? WHERE username = ?",
                       params = list(motivo, acc$username))
      }
    })
    tibble::tibble(cuenta = acc$username, valida = valida, usuario_x = usuario, motivo = motivo)
  })
  out <- dplyr::bind_rows(rows)
  for (u in unique(stats::na.omit(out$usuario_x[out$valida %in% TRUE]))) .pool_dedupe(u)
  out
}

#' Deja una sola entrada por cuenta real de X
#'
#' Si varias cuentas del pool son el mismo @usuario (p. ej. la "default" de
#' versiones previas y la misma sesion cargada de nuevo con otro nombre), se
#' conserva la agregada mas recientemente (la sesion mas fresca) y se le
#' traspasan las pausas (gana la mas larga: es la misma cuenta, comparte el
#' cupo) y las estadisticas (se suman). Las demas se borran con su sesion.
#' @return Invisiblemente, los nombres de las cuentas borradas.
#' @noRd
.pool_dedupe <- function(screen_name) {
  r <- .pool_with(function(con) {
    DBI::dbGetQuery(con, "
      SELECT username, state_path, locks, stats FROM accounts
      WHERE screen_name = ? COLLATE NOCASE
      ORDER BY added_at DESC, username",
      params = list(screen_name))
  })
  if (nrow(r) < 2L) return(invisible(character(0)))
  merge_json <- function(js, f) {
    vals <- unlist(lapply(js, function(j) unlist(jsonlite::fromJSON(j))))
    if (!length(vals)) return("{}")
    agg <- tapply(vals, names(vals), f)
    as.character(jsonlite::toJSON(as.list(agg), auto_unbox = TRUE))
  }
  keep <- r$username[1]
  drop <- r[-1, , drop = FALSE]
  .pool_with(function(con) {
    DBI::dbWithTransaction(con, {
      DBI::dbExecute(con, "UPDATE accounts SET locks = ?, stats = ? WHERE username = ?",
                     params = list(merge_json(r$locks, max), merge_json(r$stats, sum), keep))
      for (u in drop$username) DBI::dbExecute(con, "DELETE FROM accounts WHERE username = ?", params = list(u))
    })
  })
  unlink(drop$state_path)
  message("\"", keep, "\" reemplaza a ", paste0("\"", drop$username, "\"", collapse = ", "),
          " (misma cuenta de X, @", screen_name, ").")
  invisible(drop$username)
}

#' Eliminar cuentas del pool
#'
#' Borra las cuentas y sus archivos de sesion.
#'
#' @param accounts Nombres de las cuentas a eliminar.
#' @return Invisiblemente, la cantidad de cuentas eliminadas.
#' @export
#'
#' @examples
#' \dontrun{
#' removeAccountX("cuenta2")
#' }
removeAccountX <- function(accounts) {
  n <- 0L
  for (a in accounts) {
    state <- .pool_state_of(a)
    if (is.null(state)) {
      warning("No existe la cuenta \"", a, "\".")
      next
    }
    .pool_with(function(con) DBI::dbExecute(con, "DELETE FROM accounts WHERE username = ?", params = list(a)))
    unlink(state)
    n <- n + 1L
  }
  invisible(n)
}

#' Reactivar cuentas desactivadas del pool
#'
#' Una cuenta se desactiva cuando X rechaza su sesion o la limita. Si fue un
#' falso positivo (o ya se resolvio desde el navegador), se reactiva con esta
#' funcion. Si la sesion vencio, conviene reimportarla con [importSessionX()].
#'
#' @param accounts Nombres de las cuentas a reactivar.
#' @return Invisiblemente, la cantidad de cuentas reactivadas.
#' @export
#'
#' @examples
#' \dontrun{
#' reactivateAccountX("cuenta2")
#' }
reactivateAccountX <- function(accounts) {
  n <- .pool_with(function(con) {
    sum(vapply(accounts, function(a) {
      DBI::dbExecute(con, "UPDATE accounts SET active = 1, error_msg = NULL WHERE username = ?",
                     params = list(a))
    }, numeric(1)))
  })
  invisible(as.integer(n))
}

#' Valida y normaliza una direccion de proxy (NA si no hay proxy)
#' @noRd
.check_proxy <- function(proxy) {
  proxy <- .pool_na(if (is.null(proxy) || is.na(proxy)) NULL else trimws(proxy))
  if (is.na(proxy)) return(proxy)
  if (grepl("^socks5?://[^/]*@", proxy, ignore.case = TRUE)) {
    stop("Chromium no admite proxies SOCKS5 con usuario y clave. ",
         "Usa la direccion HTTP que da tu proveedor (http://usuario:clave@host:puerto).", call. = FALSE)
  }
  if (!grepl("^((https?|socks[45]?)://)?([^@/]+@)?[^:@/]+:[0-9]+/?$", proxy, ignore.case = TRUE)) {
    stop("No reconozco el proxy \"", proxy, "\". Formato: http://usuario:clave@host:puerto", call. = FALSE)
  }
  proxy
}

#' Asignar, cambiar o quitar el proxy de cuentas del pool
#'
#' Cambia el proxy de cuentas ya cargadas sin tocar su sesion (no hace falta
#' volver a pegar las cookies). Conviene que cada cuenta salga siempre por la
#' misma IP: usa proxies "sticky" (IP fija), no rotativos.
#'
#' @param accounts Nombres de las cuentas.
#' @param proxy Direccion del proxy: "http://usuario:clave@host:puerto",
#'   "usuario:clave@host:puerto" o "socks5://host:puerto". Chromium no admite
#'   SOCKS5 con usuario y clave: para proxies autenticados usa la direccion
#'   HTTP del proveedor. NULL (o "") quita el proxy y la cuenta pasa a usar el
#'   global (`options(TweetScraperR.proxy = ...)`) o tu conexion directa.
#' @param validate Logico. Si TRUE (por defecto) valida cada cuenta a traves
#'   del proxy nuevo con [checkAccountsX()], lo que confirma que el proxy anda.
#'
#' @return Invisiblemente, el resultado de [checkAccountsX()] si `validate`
#'   es TRUE, o los nombres de las cuentas si no.
#' @export
#'
#' @examples
#' \dontrun{
#' setProxyX("cuenta2", "http://usuario:clave@gate.proveedor.com:10000")
#' setProxyX("cuenta2", NULL)   # quitarlo
#' }
setProxyX <- function(accounts, proxy, validate = TRUE) {
  if (missing(accounts) || !length(accounts)) stop("Necesito al menos una cuenta.")
  if (missing(proxy)) stop("Indica el proxy, o NULL para quitarlo.")
  proxy <- .check_proxy(proxy)
  faltan <- accounts[vapply(accounts, function(a) is.null(.pool_state_of(a)), logical(1))]
  if (length(faltan)) stop("No existe(n) en el pool: ", paste0("\"", faltan, "\"", collapse = ", "))
  .pool_with(function(con) {
    for (a in accounts) DBI::dbExecute(con, "UPDATE accounts SET proxy = ? WHERE username = ?", params = list(proxy, a))
  })
  message(if (is.na(proxy)) "Proxy quitado de " else "Proxy asignado a ",
          paste0("\"", accounts, "\"", collapse = ", "), ".")
  if (validate) return(invisible(checkAccountsX(accounts)))
  invisible(accounts)
}

#' Quitar las pausas de rate-limit de todas las cuentas
#'
#' Util si una recoleccion se corto a la fuerza (Ctrl+C, error) y dejo
#' cuentas tomadas o pausas desactualizadas.
#'
#' @return Invisiblemente, la cantidad de cuentas afectadas.
#' @export
#'
#' @examples
#' \dontrun{
#' resetLocksX()
#' }
resetLocksX <- function() {
  invisible(.pool_with(function(con) DBI::dbExecute(con, "UPDATE accounts SET locks = '{}'")))
}
