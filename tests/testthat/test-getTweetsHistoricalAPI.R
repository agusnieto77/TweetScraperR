# Busqueda historica por ventanas sobre un buscador simulado -----------------

# Simula SearchTimeline: devuelve los tweets de [since_time, until_time) del
# mas nuevo al mas viejo, cortando en `cap` como hace X. `now` es el reloj
# (por defecto 2026-10-22 10:00 UTC: el indice completo empieza el 2026-10-15).
# `on_call(n, search)` permite inyectar fallas, cortes o interrupciones; si
# devuelve un numero, la respuesta se corta a esa cantidad de tweets. La
# consulta testigo responde segun `set_canary()` (por defecto, X no frena).
local_fake_search <- function(corpus, cap, on_call = NULL, now = "2026-10-22 10:00:00",
                              env = parent.frame()) {
  calls <- data.frame(search = character(0), product = character(0))
  reloj <- as.POSIXct(now, tz = "UTC")
  testigo <- TRUE
  testthat::local_mocked_bindings(
    .hist_now = function() reloj,
    .search_canary = function() testigo,
    getTweetsSearchAPI = function(search, n_tweets, product = "Latest", ...) {
      calls <<- rbind(calls, data.frame(search = search, product = product))
      corte <- if (!is.null(on_call)) on_call(nrow(calls), search)
      a <- as.numeric(sub(".*since_time:(\\d+).*", "\\1", search))
      b <- as.numeric(sub(".*until_time:(\\d+).*", "\\1", search))
      t <- as.numeric(corpus$fecha)
      w <- corpus[t >= a & t < b, ]
      n <- min(n_tweets, cap, if (is.numeric(corte)) corte else Inf)
      utils::head(w[order(w$fecha, decreasing = TRUE), ], n)
    },
    .env = env
  )
  list(calls = function() calls, set_now = function(x) reloj <<- as.POSIXct(x, tz = "UTC"),
       set_canary = function(x) testigo <<- x)
}

corpus_every <- function(from, to, step) {
  f <- seq(as.POSIXct(from, tz = "UTC"), as.POSIXct(to, tz = "UTC"), by = step)
  tibble::tibble(tweet_id = as.character(1e12 + seq_along(f)), conversation_id = "1", fecha = f)
}

interrupt_now <- function() signalCondition(structure(list(message = "", call = NULL),
                                                      class = c("interrupt", "condition")))

quiet <- function(expr) suppressMessages(utils::capture.output(expr))

test_that("recupera todo un periodo denso aunque cada consulta corte en 600 tweets", {
  # 2 dias, un tweet cada 40 s: 4.320 tweets, 7 veces el tope por consulta.
  corpus <- corpus_every("2026-10-20 00:00:00", "2026-10-21 23:59:59", 40)
  fake <- local_fake_search(corpus, cap = 600)

  quiet(tw <- getTweetsHistoricalAPI("#x", since = "2026-10-20", until = "2026-10-21"))

  expect_setequal(tw$tweet_id, corpus$tweet_id)
  expect_false(is.unsorted(rev(tw$fecha)))
  expect_true(all(grepl("^#x since_time:\\d+ until_time:\\d+$", fake$calls()$search)))
  expect_true(all(fake$calls()$product == "Latest"))
})

test_that("lo anterior al indice completo se pide a Destacados en ventanas de 3 h", {
  corpus <- corpus_every("2026-10-14 00:00:00", "2026-10-15 23:00:00", 3600)
  fake <- local_fake_search(corpus, cap = 600)

  quiet(tw <- getTweetsHistoricalAPI("#x", since = "2026-10-14", until = "2026-10-15"))

  expect_setequal(tw$tweet_id, corpus$tweet_id)
  viejo <- fake$calls()[fake$calls()$product == "Top", "search"]
  a <- as.numeric(sub(".*since_time:(\\d+).*", "\\1", viejo))
  b <- as.numeric(sub(".*until_time:(\\d+).*", "\\1", viejo))
  expect_equal(length(viejo), 8)
  expect_true(all(b - a == 3 * 3600))
  expect_true(all(b <= as.numeric(as.POSIXct("2026-10-15", tz = "UTC"))))
  expect_true(any(fake$calls()$product == "Latest"))
})

test_that("un dia en until incluye el dia completo y descarta lo de fuera del periodo", {
  corpus <- corpus_every("2026-10-19 12:00:00", "2026-10-22 12:00:00", 3600)
  local_fake_search(corpus, cap = 600)

  quiet(tw <- getTweetsHistoricalAPI("#x", since = "2026-10-20", until = "2026-10-21"))

  expect_equal(nrow(tw), 48)
  expect_equal(range(tw$fecha), as.POSIXct(c("2026-10-20 00:00:00", "2026-10-21 23:00:00"), tz = "UTC"))
})

test_that("un corte a mitad de camino se reanuda sin repetir ventanas hechas ni duplicar tweets", {
  corpus <- corpus_every("2026-10-16 00:00:00", "2026-10-21 23:59:59", 300)
  db <- withr::local_tempfile(fileext = ".sqlite")
  cortar <- TRUE
  fake <- local_fake_search(corpus, cap = 600, on_call = function(n, search) {
    if (cortar && n == 3) interrupt_now()
  })

  quiet(parcial <- getTweetsHistoricalAPI("#x", since = "2026-10-16", until = "2026-10-21", db = db))
  hechas_antes <- fake$calls()$search[1:2]
  expect_lt(nrow(parcial), nrow(corpus))

  cortar <- FALSE
  quiet(tw <- getTweetsHistoricalAPI("#x", db = db))

  expect_setequal(tw$tweet_id, corpus$tweet_id)
  expect_false(anyDuplicated(tw$tweet_id) > 0)
  # Las ventanas terminadas antes del corte no se vuelven a pedir.
  despues <- fake$calls()$search[-(1:3)]
  expect_false(any(hechas_antes %in% despues))
})

test_that("reanudar despues de la medianoche UTC usa el mismo plan y el fin guardado", {
  corpus <- corpus_every("2026-10-16 00:00:00", "2026-10-22 09:59:59", 900)
  db <- withr::local_tempfile(fileext = ".sqlite")
  cortar <- TRUE
  fake <- local_fake_search(corpus, cap = 600, on_call = function(n, search) {
    if (cortar && n == 2) interrupt_now()
  })

  # `until` omitido: el fin es "ahora" (2026-10-22 10:00) y queda guardado.
  quiet(getTweetsHistoricalAPI("#x", since = "2026-10-16", db = db))

  cortar <- FALSE
  fake$set_now("2026-10-24 08:00:00")  # el corte de 7 dias ya paso el inicio del periodo
  quiet(tw <- getTweetsHistoricalAPI("#x", db = db))

  # Mismo plan: ninguna consulta a Destacados aparece por el nuevo corte, y el
  # fin sigue siendo el guardado aunque el reloj avanzo.
  expect_true(all(fake$calls()$product == "Latest"))
  fin <- max(as.numeric(sub(".*until_time:(\\d+).*", "\\1", fake$calls()$search)))
  expect_equal(fin, as.numeric(as.POSIXct("2026-10-22 10:00:00", tz = "UTC")))
  expect_setequal(tw$tweet_id, corpus$tweet_id)

  # Un `until` explicito distinto del guardado se rechaza.
  expect_error(quiet(getTweetsHistoricalAPI("#x", until = "2026-10-21", db = db)), "until")
  expect_error(quiet(getTweetsHistoricalAPI("#otra", db = db)), "otra descarga")
})

test_that("una ventana con consultas fallidas o incompletas queda pendiente y se completa al reanudar", {
  corpus <- corpus_every("2026-10-20 00:00:00", "2026-10-21 23:59:59", 1800)
  db <- withr::local_tempfile(fileext = ".sqlite")
  dia_20 <- sprintf("since_time:%.0f ", as.numeric(as.POSIXct("2026-10-20", tz = "UTC")))
  dia_21 <- sprintf("since_time:%.0f ", as.numeric(as.POSIXct("2026-10-21", tz = "UTC")))
  fallar <- TRUE
  local_fake_search(corpus, cap = 600, on_call = function(n, search) {
    if (!fallar) return()
    if (grepl(dia_20, search, fixed = TRUE)) stop("HTTP 500")
    if (grepl(dia_21, search, fixed = TRUE)) {
      warning(warningCondition("sin cuentas", class = "tsr_partial_harvest"))
    }
  })

  msgs <- testthat::capture_messages(utils::capture.output(
    tw <- getTweetsHistoricalAPI("#x", since = "2026-10-20", until = "2026-10-21", db = db)
  ))
  expect_true(any(grepl("2 ventanas quedaron pendientes", msgs)))
  # Lo recibido en la ventana incompleta igual quedo guardado.
  expect_equal(sum(as.Date(tw$fecha) == as.Date("2026-10-21")), 48)

  fallar <- FALSE
  quiet(tw <- getTweetsHistoricalAPI("#x", db = db))
  expect_setequal(tw$tweet_id, corpus$tweet_id)
  con <- TweetScraperR:::.store_open(db)
  on.exit(DBI::dbDisconnect(con), add = TRUE)
  expect_equal(nrow(TweetScraperR:::.store_plan_pending(con, "hist|")), 0)
})

test_that("dos fallos y un tercer intento con datos cierran la ventana y lo avisan", {
  corpus <- corpus_every("2026-10-20 00:00:00", "2026-10-20 23:59:59", 1800)
  db <- withr::local_tempfile(fileext = ".sqlite")
  local_fake_search(corpus, cap = 600, on_call = function(n, search) {
    if (n <= 2) stop("page.goto: Timeout 60000ms exceeded.")
  })

  msgs <- testthat::capture_messages(utils::capture.output(
    tw <- getTweetsHistoricalAPI("#x", since = "2026-10-20", until = "2026-10-20", db = db)
  ))
  expect_true(any(grepl("Consulta fallida .*intento 1/3", msgs)))
  expect_true(any(grepl("Consulta fallida .*intento 2/3", msgs)))
  expect_true(any(grepl("Consulta recuperada .*intento 3/3", msgs)))
  expect_setequal(tw$tweet_id, corpus$tweet_id)
  con <- TweetScraperR:::.store_open(db)
  on.exit(DBI::dbDisconnect(con), add = TRUE)
  expect_equal(nrow(TweetScraperR:::.store_plan_pending(con, "hist|")), 0)
})

test_that("una respuesta truncada por X no da la ventana por agotada", {
  # Regresion: X a veces devuelve una sola pagina de una ventana densa; antes
  # una respuesta de menos de 500 tweets cerraba la ventana y se perdia el resto.
  corpus <- corpus_every("2026-10-20 00:00:00", "2026-10-20 23:59:59", 300)
  local_fake_search(corpus, cap = 600, on_call = function(n, search) 20)

  quiet(tw <- getTweetsHistoricalAPI("#x", since = "2026-10-20", until = "2026-10-20"))

  expect_setequal(tw$tweet_id, corpus$tweet_id)
})

test_that("al reanudar una ventana saturada se sigue desde su frontera guardada", {
  # Un dia, un tweet por minuto: 1.440 tweets con tope de 600 por consulta.
  corpus <- corpus_every("2026-10-20 00:00:00", "2026-10-20 23:59:59", 60)
  db <- withr::local_tempfile(fileext = ".sqlite")
  cortar <- TRUE
  fake <- local_fake_search(corpus, cap = 600, on_call = function(n, search) {
    if (cortar && n == 2) interrupt_now()
  })

  quiet(getTweetsHistoricalAPI("#x", since = "2026-10-20", until = "2026-10-20", db = db))
  con <- TweetScraperR:::.store_open(db)
  fin_guardado <- DBI::dbGetQuery(con, "SELECT b FROM plan")$b
  DBI::dbDisconnect(con)
  expect_lt(fin_guardado, as.numeric(as.POSIXct("2026-10-21", tz = "UTC")))

  cortar <- FALSE
  quiet(tw <- getTweetsHistoricalAPI("#x", db = db))
  primera <- fake$calls()$search[3]
  expect_equal(as.numeric(sub(".*until_time:(\\d+).*", "\\1", primera)), fin_guardado)
  expect_setequal(tw$tweet_id, corpus$tweet_id)
})

test_that("un freno silencioso de X corta la descarga sin dar ventanas por vacias", {
  # X, tras muchas consultas, devuelve vacio todo sin avisar del limite.
  corpus <- corpus_every("2026-10-20 00:00:00", "2026-10-21 23:59:59", 1800)
  db <- withr::local_tempfile(fileext = ".sqlite")
  frenado <- FALSE
  fake <- local_fake_search(corpus, cap = 600, on_call = function(n, search) {
    if (n >= 2) frenado <<- TRUE
    if (frenado) 0
  })
  fake$set_canary(FALSE)

  msgs <- testthat::capture_messages(utils::capture.output(
    tw <- getTweetsHistoricalAPI("#x", since = "2026-10-20", until = "2026-10-21", db = db)
  ))
  expect_true(any(grepl("freno silencioso", msgs)))
  # Lo recibido antes del freno quedo guardado y ninguna ventana se cerro.
  expect_equal(nrow(tw), 48)
  con <- TweetScraperR:::.store_open(db)
  expect_equal(nrow(TweetScraperR:::.store_plan_pending(con, "hist|")), 2)
  DBI::dbDisconnect(con)

  frenado <- FALSE
  fake <- local_fake_search(corpus, cap = 600)
  quiet(tw <- getTweetsHistoricalAPI("#x", db = db))
  expect_setequal(tw$tweet_id, corpus$tweet_id)
})

test_that("parametros invalidos se rechazan", {
  expect_error(getTweetsHistoricalAPI("#x", since = "2026-10-20", n_per_window = 50), "n_per_window")
  expect_error(quiet(getTweetsHistoricalAPI("#x", since = "2026-10-21", until = "2026-10-20 12:00")),
               "posterior")
  expect_error(quiet(getTweetsHistoricalAPI("#x")), "since")
})

test_that("los epochs no se truncan a 32 bits (despues de 2038)", {
  t <- as.POSIXct("2040-01-01 00:00:00", tz = "UTC")
  expect_equal(TweetScraperR:::.epoch_chr(t), "2208988800")
})
