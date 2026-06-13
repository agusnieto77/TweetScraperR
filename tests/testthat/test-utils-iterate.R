# Helpers de fecha de utils-iterate ----------------------------------------

test_that(".validate_datetime acepta el formato 'YYYY-MM-DD_HH:MM:SS_UTC'", {
  expect_silent(TweetScraperR:::.validate_datetime("2024-01-01_00:00:00_UTC"))
  expect_silent(TweetScraperR:::.validate_datetime("1999-12-31_23:59:59_UTC"))
})

test_that(".validate_datetime rechaza formatos invalidos", {
  expect_error(
    TweetScraperR:::.validate_datetime("2024-01-01 00:00:00"),
    "formato de 'since'"
  )
  expect_error(
    TweetScraperR:::.validate_datetime("2024-1-1_00:00:00_UTC"),
    "formato de 'since'"
  )
  expect_error(
    TweetScraperR:::.validate_datetime("2024-01-01_00:00:00"),
    "formato de 'since'"
  )
  expect_error(TweetScraperR:::.validate_datetime("garbage"), "formato de 'since'")
})

test_that(".parse_datetime convierte el formato del paquete a POSIXct", {
  dt <- TweetScraperR:::.parse_datetime("2024-03-15_12:30:45_UTC")
  expect_s3_class(dt, "POSIXct")
  expect_equal(dt, lubridate::ymd_hms("2024-03-15 12:30:45"))
})

test_that(".format_datetime es la inversa de .parse_datetime", {
  s <- "2024-03-15_12:30:45_UTC"
  expect_equal(
    TweetScraperR:::.format_datetime(TweetScraperR:::.parse_datetime(s)),
    s
  )
})

test_that(".calculate_untilok suma dias, horas y minutos correctamente", {
  desde <- "2024-01-01_00:00:00_UTC"
  expect_equal(
    TweetScraperR:::.calculate_untilok(desde, 2, "days"),
    "2024-01-03_00:00:00_UTC"
  )
  expect_equal(
    TweetScraperR:::.calculate_untilok(desde, 3, "hours"),
    "2024-01-01_03:00:00_UTC"
  )
  expect_equal(
    TweetScraperR:::.calculate_untilok(desde, 30, "minutes"),
    "2024-01-01_00:30:00_UTC"
  )
})

test_that(".calculate_untilok cruza limites de mes y anio", {
  expect_equal(
    TweetScraperR:::.calculate_untilok("2024-12-31_23:00:00_UTC", 2, "hours"),
    "2025-01-01_01:00:00_UTC"
  )
})

test_that(".calculate_untilok con unidad invalida emite warning y devuelve NULL", {
  expect_warning(
    res <- TweetScraperR:::.calculate_untilok("2024-01-01_00:00:00_UTC", 2, "weeks"),
    "Error al calcular la fecha"
  )
  expect_null(res)
})
