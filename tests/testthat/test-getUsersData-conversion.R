# Conversion K/M de getUsersData (C11) --------------------------------------

test_that("conversion K/M de getUsersData (C11): 1.2K, 12 mil y 3.4M", {
  ns <- asNamespace("TweetScraperR")
  candidatos <- c(
    ".convertir_numero", "convertir_numero",
    ".convert_number", ".convert_metric", ".parse_count", ".parse_metric"
  )
  helper <- NULL
  for (nm in candidatos) {
    if (exists(nm, envir = ns, inherits = FALSE)) {
      helper <- get(nm, envir = ns)
      break
    }
  }

  if (is.null(helper)) {
    skip(paste(
      "C11: convertir_numero sigue definida como funcion anidada dentro de",
      "getUsersData() (R/getUsersData.R), no accesible como helper interno",
      "del paquete. Cuando se promueva a R/utils-*.R, este test debe validar:",
      "'1.2K' -> 1200 (UI inglesa), '12 mil' -> 12000 (UI espaniola),",
      "'3.4M' -> 3400000."
    ))
  }

  expect_equal(helper("1.2K"), 1200)
  expect_equal(helper("12 mil"), 12000)
  expect_equal(helper("3.4M"), 3400000)
})
