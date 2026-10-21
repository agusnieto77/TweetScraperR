# Captura en vivo: polling con since_id sobre getTweetsSearchAPI -------------

# Reloj falso: .live_sleep() avanza el reloj en vez de dormir.
local_fake_live <- function(responses, env = parent.frame()) {
  reloj <- as.POSIXct("2026-10-21 12:00:00", tz = "UTC")
  queries <- character(0)
  testthat::local_mocked_bindings(
    .live_now = function() reloj,
    .live_sleep = function(seconds) reloj <<- reloj + seconds,
    getTweetsSearchAPI = function(search, ...) {
      queries <<- c(queries, search)
      r <- responses[[length(queries)]]
      if (inherits(r, "error")) stop(r)
      r
    },
    .env = env
  )
  function() queries
}

ids <- function(...) tibble::tibble(tweet_id = c(...))

test_that("cada ronda pide desde el mayor ID visto, acumula sin duplicar y sobrevive a una ronda fallida", {
  queries <- local_fake_live(list(
    ids("99", "100"),          # "100" > "99" aunque como texto sea menor
    ids("101", "100"),
    simpleError("timeout"),
    ids("102")
  ))
  dir <- withr::local_tempdir()

  res <- suppressMessages(capture.output(
    out <- getTweetsLiveAPI("#x", interval = 300, duration = 900, dir = dir, save = TRUE)
  ))

  expect_equal(queries(), c("#x", "#x since_id:100", "#x since_id:101", "#x since_id:101"))
  expect_equal(out$tweet_id, c("102", "101", "99", "100"))
  guardado <- list.files(dir, pattern = "^api_live_.*\\.rds$", full.names = TRUE)
  expect_length(guardado, 1)
  expect_equal(readRDS(guardado), out)
})

test_that("la captura termina al alcanzar max_tweets", {
  queries <- local_fake_live(list(ids("1", "2"), ids("3"), ids("4")))

  out <- suppressMessages(capture.output(
    res <- getTweetsLiveAPI("#x", interval = 60, duration = 3600, max_tweets = 3)
  ))

  expect_length(queries(), 2)
  expect_equal(nrow(res), 3)
})

test_that("se avisa cuando una ronda llega al tope y puede haber huecos", {
  local_fake_live(list(ids("1", "2"), ids("4", "3")))

  expect_message(
    capture.output(getTweetsLiveAPI("#x", interval = 60, duration = 60, n_tweets = 2)),
    "tope de 2"
  )
})

test_that("interval menor a 60 segundos se rechaza", {
  expect_error(getTweetsLiveAPI("#x", interval = 10), "interval")
})
