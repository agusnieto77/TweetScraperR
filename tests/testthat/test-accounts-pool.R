# Pool de cuentas (SQLite) y rotacion en .pw_harvest_raw ---------------------

# Directorio de datos aislado: base del pool y sesiones en un temporal.
local_pool <- function(env = parent.frame()) {
  d <- tempfile("tsr-data-")
  dir.create(d)
  withr::local_options(TweetScraperR.data_dir = d, TweetScraperR.wait_timeout = 0, .local_envir = env)
  d
}

add_account <- function(name, proxy = NULL) {
  suppressMessages(importSessionX(paste0("tok_", name), paste0("ct0_", name), account = name, proxy = proxy))
}

test_that("la sesion unica de versiones previas se registra como la cuenta 'default'", {
  d <- local_pool()
  writeLines("{}", file.path(d, "x-storage-state.json"))

  acc <- accountsX()

  expect_equal(acc$cuenta, "default")
  expect_true(acc$activa)
})

test_that("importSessionX guarda las cookies como storageState de Playwright", {
  local_pool()
  add_account("a")

  st <- jsonlite::fromJSON(TweetScraperR:::.pool_state_of("a"), simplifyVector = FALSE)
  vals <- vapply(st$cookies, function(ck) ck$value, character(1))
  names(vals) <- vapply(st$cookies, function(ck) ck$name, character(1))

  expect_equal(vals[["auth_token"]], "tok_a")
  expect_equal(vals[["ct0"]], "ct0_a")
})

test_that("el bloqueo es por (cuenta, operacion) y se reparte la cuenta usada hace mas tiempo", {
  local_pool()
  add_account("a")
  add_account("b")

  first <- TweetScraperR:::.pool_acquire("SearchTimeline")
  second <- TweetScraperR:::.pool_acquire("SearchTimeline")

  expect_setequal(c(first$username, second$username), c("a", "b"))
  expect_null(TweetScraperR:::.pool_acquire("SearchTimeline"))
  # Tomadas para SearchTimeline, siguen libres para otra operacion
  expect_false(is.null(TweetScraperR:::.pool_acquire("UserTweets")))
})

test_that("release con cupo agotado pausa la cuenta hasta el reset; sin cupo agotado la libera", {
  local_pool()
  add_account("a")
  add_account("b")
  a <- TweetScraperR:::.pool_acquire("SearchTimeline")
  b <- TweetScraperR:::.pool_acquire("SearchTimeline")

  TweetScraperR:::.pool_release(a$username, "SearchTimeline", until = as.integer(Sys.time()) + 600L, n = 3L)
  TweetScraperR:::.pool_release(b$username, "SearchTimeline", until = 0L, n = 2L)

  again <- TweetScraperR:::.pool_acquire("SearchTimeline")
  expect_equal(again$username, b$username)
  acc <- accountsX()
  expect_equal(acc$requests[acc$cuenta == a$username], 3L)
  expect_match(acc$pausas[acc$cuenta == a$username], "^SearchTimeline hasta ")
})

test_that("una cuenta desactivada no se toma hasta reactivarla", {
  local_pool()
  add_account("a")
  TweetScraperR:::.pool_disable("a", "SearchTimeline", "sesion expirada")

  expect_null(TweetScraperR:::.pool_acquire("SearchTimeline"))
  expect_equal(accountsX()$error, "sesion expirada")

  reactivateAccountX("a")
  expect_equal(TweetScraperR:::.pool_acquire("SearchTimeline")$username, "a")
})

test_that("reimportar una cuenta la reactiva y conserva su proxy", {
  local_pool()
  add_account("a", proxy = "http://p:1")
  TweetScraperR:::.pool_disable("a", "SearchTimeline", "sesion expirada")

  add_account("a")

  acc <- accountsX()
  expect_true(acc$activa)
  expect_true(is.na(acc$error))
  expect_equal(acc$proxy, "http://p:1")
})

test_that(".pool_acquire_wait distingue 'sin cuentas activas' de 'todas en pausa'", {
  local_pool()
  expect_identical(attr(TweetScraperR:::.pool_acquire_wait("SearchTimeline"), "reason"), "none")

  add_account("a")
  TweetScraperR:::.pool_acquire("SearchTimeline")
  busy <- TweetScraperR:::.pool_acquire_wait("SearchTimeline")
  expect_identical(attr(busy, "reason"), "busy")
  expect_gt(attr(busy, "next_at"), as.integer(Sys.time()))
})

test_that("el proxy de la cuenta tiene prioridad sobre el global", {
  withr::local_options(TweetScraperR.proxy = "http://global:1")
  expect_equal(TweetScraperR:::.pool_proxy(list(proxy = "http://cuenta:2")), "http://cuenta:2")
  expect_equal(TweetScraperR:::.pool_proxy(list(proxy = NA_character_)), "http://global:1")
})

test_that("setProxyX asigna y quita el proxy sin tocar la sesion", {
  local_pool()
  add_account("a")
  sesion <- readLines(TweetScraperR:::.pool_state_of("a"))

  suppressMessages(setProxyX("a", "http://u:p@host.com:10000", validate = FALSE))
  expect_equal(accountsX()$proxy, "http://u:p@host.com:10000")
  expect_identical(readLines(TweetScraperR:::.pool_state_of("a")), sesion)

  suppressMessages(setProxyX("a", NULL, validate = FALSE))
  expect_true(is.na(accountsX()$proxy))
})

test_that("setProxyX rechaza SOCKS5 autenticado, formatos invalidos y cuentas inexistentes", {
  local_pool()
  add_account("a")
  expect_error(setProxyX("a", "socks5://u:p@host.com:1080", validate = FALSE), "SOCKS5")
  expect_error(setProxyX("a", "host-sin-puerto", validate = FALSE), "No reconozco")
  expect_error(setProxyX("zz", "http://host.com:8080", validate = FALSE), "No existe")
  expect_true(is.na(accountsX()$proxy))
})

test_that("checkAccountsX explica un fallo de conexion por proxy sin desactivar la cuenta", {
  local_pool()
  add_account("a", proxy = "http://127.0.0.1:9")
  testthat::local_mocked_bindings(.pw_call = function(cmd, params, ...) {
    list(ok = FALSE, error = "page.goto: net::ERR_PROXY_CONNECTION_FAILED at https://x.com/home")
  })

  utils::capture.output(out <- checkAccountsX())

  expect_true(is.na(out$valida))
  expect_match(out$motivo, "proxy \\(ERR_PROXY_CONNECTION_FAILED\\)")
  expect_true(accountsX()$activa)
})

test_that("addAccountsX lee CSV de Excel en espanol (separador ';' y BOM)", {
  local_pool()
  f <- tempfile(fileext = ".csv")
  writeBin(c(as.raw(c(0xEF, 0xBB, 0xBF)), charToRaw("account;auth_token;ct0\r\nc1;T1;C1\r\nc2;T2;C2\r\n")), f)

  suppressMessages(addAccountsX(f))

  expect_setequal(accountsX()$cuenta, c("c1", "c2"))
  st <- jsonlite::fromJSON(TweetScraperR:::.pool_state_of("c2"))$cookies
  expect_equal(st$value[st$name == "auth_token"], "T2")
})

test_that("setupAccountsX vuelve a pedir el proxy si es invalido", {
  local_pool()
  lineas <- c("cuenta2", "socks5://u:p@h.com:1080", "http://u:p@h.com:8080", "")
  testthat::local_mocked_bindings(
    .is_interactive = function() TRUE,
    .ask_line = function(prompt) { x <- lineas[1]; lineas <<- lineas[-1]; x },
    .ask_secret = function(prompt) "auth_token=T; ct0=C"
  )

  utils::capture.output(suppressMessages(setupAccountsX(validate = FALSE)))

  expect_equal(accountsX()$proxy, "http://u:p@h.com:8080")
})

test_that(".parse_cookies acepta header, objeto JSON y array de Cookie-Editor", {
  esperado <- list(auth_token = "T", ct0 = "C")
  expect_equal(TweetScraperR:::.parse_cookies("guest_id=1; auth_token=T; ct0=C"), esperado)
  expect_equal(TweetScraperR:::.parse_cookies('{"auth_token":"T","ct0":"C"}'), esperado)
  expect_equal(
    TweetScraperR:::.parse_cookies('[{"name":"ct0","value":"C"},{"name":"auth_token","value":"T"}]'),
    esperado
  )
})

test_that("checkAccountsX desactiva sesiones vencidas, reactiva las validas y registra el usuario", {
  local_pool()
  add_account("a")
  add_account("b")
  TweetScraperR:::.pool_disable("a", "SearchTimeline", "sesion expirada")
  respuestas <- list(
    a = list(ok = TRUE, valid = TRUE, reason = NULL, screenName = "ana"),
    b = list(ok = TRUE, valid = FALSE, reason = "expired", screenName = NULL)
  )
  testthat::local_mocked_bindings(.pw_call = function(cmd, params, ...) {
    respuestas[[sub("\\.json$", "", basename(params$storageStatePath))]]
  })

  utils::capture.output(out <- checkAccountsX())

  expect_equal(out$valida, c(TRUE, FALSE))
  acc <- accountsX()
  expect_equal(acc$activa[acc$cuenta == "a"], TRUE)       # reactivada
  expect_equal(acc$usuario_x[acc$cuenta == "a"], "ana")
  expect_equal(acc$activa[acc$cuenta == "b"], FALSE)
  expect_match(acc$error[acc$cuenta == "b"], "expirada")
})

test_that("la misma cuenta de X cargada dos veces se reescribe: queda la sesion mas nueva con pausas y estadisticas", {
  local_pool()
  add_account("viejo")
  add_account("nuevo")
  TweetScraperR:::.pool_with(function(con) {
    DBI::dbExecute(con, "UPDATE accounts SET added_at = added_at - 100 WHERE username = 'viejo'")
  })
  pausa <- as.integer(Sys.time()) + 600L
  TweetScraperR:::.pool_release("viejo", "SearchTimeline", until = pausa, n = 7L)
  TweetScraperR:::.pool_release("nuevo", "SearchTimeline", until = 0L, n = 2L)
  sesion_vieja <- TweetScraperR:::.pool_state_of("viejo")
  testthat::local_mocked_bindings(.pw_call = function(cmd, params, ...) {
    list(ok = TRUE, valid = TRUE, screenName = if (grepl("viejo", params$storageStatePath)) "ana" else "ANA")
  })

  expect_message(utils::capture.output(checkAccountsX()), "\"nuevo\" reemplaza a \"viejo\"")

  acc <- accountsX()
  expect_equal(acc$cuenta, "nuevo")
  expect_equal(acc$requests, 9L)
  expect_match(acc$pausas, "^SearchTimeline hasta ")
  expect_false(file.exists(sesion_vieja))
})

test_that("setupAccountsX carga y valida las cuentas que se van ingresando por consola", {
  local_pool()
  lineas <- c("cuenta2", "", "cuenta3", "http://p:1", "")    # nombres, proxys y Enter final
  secretos <- c("TOK2", "CT02", "auth_token=TOK3; ct0=CT03")  # cuenta3 pega el header
  testthat::local_mocked_bindings(
    .is_interactive = function() TRUE,
    .ask_line = function(prompt) { x <- lineas[1]; lineas <<- lineas[-1]; x },
    .ask_secret = function(prompt) { x <- secretos[1]; secretos <<- secretos[-1]; x },
    .pw_call = function(cmd, params, ...) {
      list(ok = TRUE, valid = TRUE, screenName = sub("\\.json$", "", basename(params$storageStatePath)))
    }
  )

  utils::capture.output(suppressMessages(setupAccountsX()))

  acc <- accountsX()
  expect_setequal(acc$cuenta, c("cuenta2", "cuenta3"))
  expect_equal(acc$proxy[acc$cuenta == "cuenta3"], "http://p:1")
  expect_true(all(acc$activa))
  st <- jsonlite::fromJSON(TweetScraperR:::.pool_state_of("cuenta3"))$cookies
  expect_equal(st$value[st$name == "ct0"], "CT03")
})

test_that("setupAccountsX se niega a correr fuera de una consola interactiva", {
  testthat::local_mocked_bindings(.is_interactive = function() FALSE)
  expect_error(setupAccountsX(), "interactiva")
})

# Rotacion: el motor se reemplaza por respuestas guionadas -------------------

mock_engine <- function(responses, env = parent.frame()) {
  calls <- list()
  testthat::local_mocked_bindings(
    .pw_call = function(cmd, params, ...) {
      calls[[length(calls) + 1L]] <<- params
      responses[[length(calls)]]
    },
    .env = env
  )
  function() calls
}

engine_res <- function(bodies, stopped = NULL, at = NULL, remaining = 40L, reset = 0L,
                       cursors = NULL, counts = NULL) {
  list(
    ok = TRUE,
    results = lapply(seq_along(bodies), function(i) {
      list(url = "u", bodies = as.list(bodies[[i]]),
           cursor = cursors[[i]], count = if (is.null(counts)) 0L else counts[[i]])
    }),
    rateLimits = list(SearchTimeline = list(remaining = remaining, reset = reset)),
    stopped = stopped, stoppedAt = at
  )
}

test_that("un corte por cupo pausa la cuenta y retoma la url cortada con la siguiente", {
  local_pool()
  add_account("a")
  add_account("b")
  reset <- as.integer(Sys.time()) + 600L
  calls <- mock_engine(list(
    engine_res(list("{1}", "{2a}"), stopped = "rate_limited", at = 2L, remaining = 0L, reset = reset),
    engine_res(list("{2b}", "{3}"))
  ))

  res <- suppressMessages(TweetScraperR:::.pw_harvest_raw(c("u1", "u2", "u3"), "SearchTimeline"))

  expect_equal(lapply(res, `[[`, "bodies"), list("{1}", c("{2a}", "{2b}"), "{3}"))
  expect_equal(unlist(calls()[[2]]$urls), c("u2", "u3"))
  expect_false(identical(calls()[[1]]$storageStatePath, calls()[[2]]$storageStatePath))
  acc <- accountsX()
  cortada <- acc[!is.na(acc$pausas), ]
  expect_equal(nrow(cortada), 1L)
  expect_equal(cortada$requests, 2L)
})

test_that("la url cortada se retoma desde su cursor y pidiendo solo lo que falta", {
  local_pool()
  add_account("a")
  add_account("b")
  calls <- mock_engine(list(
    engine_res(list("{1}", "{2a}"), stopped = "rate_limited", at = 2L, remaining = 0L,
               reset = as.integer(Sys.time()) + 600L,
               cursors = list("C1", "C2"), counts = list(50L, 30L)),
    engine_res(list("{2b}"))
  ))

  suppressMessages(TweetScraperR:::.pw_harvest_raw(c("u1", "u2"), "SearchTimeline", n = 50))

  expect_equal(calls()[[1]]$targets, list(50L, 50L))
  expect_null(calls()[[1]]$cursors)
  expect_equal(unlist(calls()[[2]]$urls), "u2")
  expect_equal(calls()[[2]]$cursors, list("C2"))
  expect_equal(calls()[[2]]$targets, list(20L))
})

test_that("una sesion vencida desactiva la cuenta; sin otras cuentas ni datos, error claro", {
  local_pool()
  add_account("a")
  mock_engine(list(engine_res(list(character(0)), stopped = "expired", at = 1L)))

  expect_error(
    suppressMessages(TweetScraperR:::.pw_harvest_raw("u1", "SearchTimeline")),
    "expirado"
  )
  acc <- accountsX()
  expect_false(acc$activa)
  expect_match(acc$error, "expirada")
})

test_that("si todas las cuentas quedan en pausa se devuelve lo parcial con un aviso", {
  local_pool()
  add_account("a")
  mock_engine(list(
    engine_res(list("{1}"), stopped = "rate_limited", at = 1L, remaining = 0L,
               reset = as.integer(Sys.time()) + 600L)
  ))

  expect_warning(
    res <- suppressMessages(TweetScraperR:::.pw_harvest_raw("u1", "SearchTimeline")),
    "en pausa"
  )
  expect_equal(res[[1]]$bodies, "{1}")
})
