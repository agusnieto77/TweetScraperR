# Bridge R <-> motor Node: .pw_call con un motor stub y .pw_sync_engine --------

# Motor falso: devuelve por stdout los parametros recibidos, escribe un log
# humano y un evento de progreso por stderr, y sale con `exit` (o se cuelga
# `sleepMs` milisegundos para probar el timeout).
stub_engine <- function() {
  d <- tempfile("stub-engine-")
  dir.create(d)
  writeLines(c(
    "let d = '';",
    "process.stdin.on('data', (c) => (d += c));",
    "process.stdin.on('end', () => {",
    "  const p = JSON.parse(d);",
    "  process.stderr.write('[stub] log humano\\n');",
    "  process.stderr.write('@@TSR ' + JSON.stringify({ stage: 'data', tweets: 1 }) + '\\n');",
    "  const done = () => {",
    "    process.stdout.write(JSON.stringify({ ok: true, cmd: process.argv[2], echo: p }));",
    "    process.exitCode = p.exit || 0;",
    "  };",
    "  if (p.sleepMs) setTimeout(done, p.sleepMs); else done();",
    "});"
  ), file.path(d, "tsr-engine.js"))
  d
}

test_that(".pw_call pasa los parametros por stdin y separa logs de eventos de progreso", {
  skip_on_cran()
  skip_if(Sys.which("node") == "", "Node.js no disponible")
  d <- stub_engine()
  local_mocked_bindings(.pw_engine_dir = function() d)

  res <- .pw_call("harvest", list(q = "#RStats \u00f1and\u00fa \U0001F680", n = 3L), timeout = 30, simplify = FALSE)

  expect_true(res$ok)
  expect_identical(res$cmd, "harvest")
  expect_identical(res$echo$q, "#RStats \u00f1and\u00fa \U0001F680")
  expect_identical(res$echo$n, 3L)
  expect_identical(res$.stderr, "[stub] log humano")
  expect_identical(res$.exit, 0L)
})

test_that(".pw_call propaga el codigo de salida del motor", {
  skip_on_cran()
  skip_if(Sys.which("node") == "", "Node.js no disponible")
  d <- stub_engine()
  local_mocked_bindings(.pw_engine_dir = function() d)

  res <- .pw_call("doctor", list(exit = 3L), timeout = 30)

  expect_identical(res$.exit, 3L)
})

test_that(".pw_call corta por timeout con exit 124 y error informativo", {
  skip_on_cran()
  skip_if(Sys.which("node") == "", "Node.js no disponible")
  d <- stub_engine()
  local_mocked_bindings(.pw_engine_dir = function() d)

  t0 <- Sys.time()
  res <- .pw_call("harvest", list(sleepMs = 20000L), timeout = 1)

  expect_lt(as.numeric(difftime(Sys.time(), t0, units = "secs")), 10)
  expect_false(res$ok)
  expect_identical(res$.exit, 124L)
  expect_match(res$error, "exit 124")
})

sync_dirs <- function(pkg_js, pkg_json, cache_js, cache_json) {
  pkg <- tempfile("pkg-")
  cache <- tempfile("cache-")
  dir.create(pkg)
  dir.create(cache)
  writeLines(pkg_js, file.path(pkg, "tsr-engine.js"))
  writeLines(pkg_json, file.path(pkg, "package.json"))
  writeLines(cache_js, file.path(cache, "tsr-engine.js"))
  writeLines(cache_json, file.path(cache, "package.json"))
  list(pkg = pkg, cache = cache)
}

test_that(".pw_sync_engine copia el motor nuevo cuando las dependencias no cambiaron", {
  d <- sync_dirs("nuevo", "{}", "viejo", "{}")

  expect_true(.pw_sync_engine(d$pkg, d$cache))
  expect_identical(readLines(file.path(d$cache, "tsr-engine.js")), "nuevo")
})

test_that(".pw_sync_engine no toca el cache si el motor ya esta al dia", {
  d <- sync_dirs("igual", "{}", "igual", "{}")

  expect_silent(expect_true(.pw_sync_engine(d$pkg, d$cache)))
})

test_that(".pw_sync_engine conserva el motor viejo y avisa si cambiaron las dependencias", {
  d <- sync_dirs("nuevo", '{"v":2}', "viejo", '{"v":1}')

  expect_warning(ok <- .pw_sync_engine(d$pkg, d$cache), "installPlaywrightEngine")
  expect_false(ok)
  expect_identical(readLines(file.path(d$cache, "tsr-engine.js")), "viejo")
})

test_that(".pw_sync_engine ignora diferencias de fin de linea (CRLF vs LF) en package.json", {
  d <- sync_dirs("nuevo", "{}", "viejo", "{}")
  writeBin(charToRaw('{\n  "v": 1\n}\n'), file.path(d$pkg, "package.json"))
  writeBin(charToRaw('{\r\n  "v": 1\r\n}\r\n'), file.path(d$cache, "package.json"))

  expect_silent(expect_true(.pw_sync_engine(d$pkg, d$cache)))
  expect_identical(readLines(file.path(d$cache, "tsr-engine.js")), "nuevo")
})

test_that(".pw_sync_engine avisa si no puede copiar el motor", {
  d <- sync_dirs("nuevo", "{}", "viejo", "{}")
  # Un directorio con el nombre del destino hace fallar a file.copy()
  unlink(file.path(d$cache, "tsr-engine.js"))
  dir.create(file.path(d$cache, "tsr-engine.js"))

  expect_warning(ok <- .pw_sync_engine(d$pkg, d$cache), "No se pudo actualizar")
  expect_false(ok)
})
