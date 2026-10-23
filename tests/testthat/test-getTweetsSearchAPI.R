# since/until -> operadores de fecha de la busqueda de X ---------------------

query_of <- function(...) {
  url <- NULL
  testthat::local_mocked_bindings(.pw_harvest = function(u, ...) { url <<- u; list() })
  utils::capture.output(getTweetsSearchAPI("#x", ...))
  utils::URLdecode(sub("^.*[?&]q=([^&]*).*$", "\\1", url))
}

test_that("un dia y una hora van como since_time:/until_time: en UTC; until incluye su dia", {
  # 2026-10-08 00:00 UTC = 1791417600; 2026-10-10 00:00 UTC = 1791590400
  expect_equal(query_of(since = "2026-10-08", until = "2026-10-09"),
               "#x since_time:1791417600 until_time:1791590400")
  expect_equal(query_of(since = "2026-10-08", until = "2026-10-08"),
               "#x since_time:1791417600 until_time:1791504000")
  # 2026-10-20 12:00:00 UTC = 1792497600
  expect_equal(query_of(since = "2026-10-20 12:00:00", until = "2026-10-20 12:10"),
               "#x since_time:1792497600 until_time:1792498200")
  expect_equal(query_of(since = "2026-10-20_12:00:00_UTC"), "#x since_time:1792497600")
  expect_equal(query_of(since = "2026-10-20T12:00:00"), "#x since_time:1792497600")
})

test_that("Date y POSIXct se aceptan; POSIXct respeta su zona horaria", {
  expect_equal(query_of(since = as.Date("2026-10-08")), "#x since_time:1791417600")
  art <- as.POSIXct("2026-10-20 09:00:00", tz = "America/Argentina/Buenos_Aires")
  expect_equal(query_of(since = art), "#x since_time:1792497600")
})

test_that("una fecha invalida se rechaza en vez de mandar una busqueda vacia", {
  expect_error(query_of(since = "2026-13-45"), "since")
  expect_error(query_of(until = "20/10/2026"), "until")
  expect_error(query_of(since = "2026-10-20 25:00"), "since")
})
