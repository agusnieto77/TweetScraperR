# HTMLImgReport (C12): generacion del HTML offline --------------------------

test_that("HTMLImgReport genera el HTML en output_file sin error, incluso con flags NA", {
  results <- make_img_results() # la fila 3 tiene todos los flags logicos en NA
  out <- tempfile(fileext = ".html")
  on.exit(unlink(out), add = TRUE)

  expect_no_error(suppressMessages(HTMLImgReport(results, output_file = out)))
  expect_true(file.exists(out))
  expect_gt(file.size(out), 0)

  html <- paste(readLines(out, warn = FALSE), collapse = "\n")
  # Las clasificaciones de todas las filas estan presentes (carrusel + miniaturas)
  for (clasif in results$clasificacion) {
    expect_match(html, clasif, fixed = TRUE)
  }
  # Los tags de la fila con TRUE aparecen; la fila con NA no rompe nada
  expect_match(html, "Discriminatorio")
  expect_match(html, "Inapropiado")
  # Texto por defecto cuando contiene_texto no es TRUE (FALSE o NA)
  expect_match(html, "No contiene texto")
})

test_that("HTMLImgReport con una sola fila funciona", {
  results <- make_img_results()[1, ]
  out <- tempfile(fileext = ".html")
  on.exit(unlink(out), add = TRUE)

  expect_no_error(suppressMessages(HTMLImgReport(results, output_file = out)))
  expect_true(file.exists(out))
})

test_that("HTMLImgReport con 0 filas falla de forma controlada (no crashea)", {
  vacio <- make_img_results()[0, ]
  out <- tempfile(fileext = ".html")

  # Error informativo del guard, no un crash criptico de seq()/lapply()
  expect_error(
    HTMLImgReport(vacio, output_file = out),
    "no contiene filas"
  )
  expect_false(file.exists(out))
})

test_that("HTMLImgReport emite mensaje de confirmacion con la ruta", {
  results <- make_img_results()
  out <- tempfile(fileext = ".html")
  on.exit(unlink(out), add = TRUE)

  expect_message(
    HTMLImgReport(results, output_file = out),
    "HTML generada y guardada"
  )
})
