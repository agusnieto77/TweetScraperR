# .save_rds: guardado en RDS con nombre timestampeado ----------------------

nuevo_dir_temporal <- function() {
  d <- file.path(tempdir(), paste0("save_rds_test_", as.integer(stats::runif(1, 1, 1e9))))
  dir.create(d)
  d
}

test_that(".save_rds con save=TRUE crea el archivo con el formato de nombre esperado", {
  d <- nuevo_dir_temporal()
  on.exit(unlink(d, recursive = TRUE), add = TRUE)
  obj <- data.frame(x = 1:3)

  res <- NULL
  out <- capture.output(
    res <- withVisible(TweetScraperR:::.save_rds(obj, d, "db_tweets", save = TRUE))
  )

  # Devuelve el path de forma invisible
  expect_false(res$visible)
  path <- res$value

  expect_true(file.exists(path))
  expect_equal(dirname(path), d)
  # prefijo + timestamp %Y_%m_%d_%H_%M_%S + .rds
  expect_match(
    basename(path),
    "^db_tweets_\\d{4}_\\d{2}_\\d{2}_\\d{2}_\\d{2}_\\d{2}\\.rds$"
  )
  # El contenido es recuperable
  expect_equal(readRDS(path), obj)
  # Mensaje legacy de guardado
  expect_match(paste(out, collapse = " "), "Datos procesados y guardados")
})

test_that(".save_rds con save=FALSE no crea ningun archivo pero devuelve el path", {
  d <- nuevo_dir_temporal()
  on.exit(unlink(d, recursive = TRUE), add = TRUE)

  res <- NULL
  out <- capture.output(
    res <- withVisible(TweetScraperR:::.save_rds(list(a = 1), d, "db_tweets", save = FALSE))
  )

  expect_false(res$visible)
  expect_type(res$value, "character")
  expect_match(basename(res$value), "^db_tweets_")
  # No se creo nada en el directorio
  expect_length(list.files(d), 0)
  expect_false(file.exists(res$value))
  # Mensaje legacy de no guardado
  expect_match(paste(out, collapse = " "), "No se han guardado en un archivo RDS")
})

test_that(".save_rds con label='URLs' emite la variante femenina del mensaje", {
  d <- nuevo_dir_temporal()
  on.exit(unlink(d, recursive = TRUE), add = TRUE)

  out_save <- capture.output(
    TweetScraperR:::.save_rds(1:3, d, "urls_tweets", save = TRUE, label = "URLs")
  )
  expect_match(paste(out_save, collapse = " "), "URLs procesadas y guardadas")

  out_nosave <- capture.output(
    TweetScraperR:::.save_rds(1:3, d, "urls_tweets", save = FALSE, label = "URLs")
  )
  expect_match(
    paste(out_nosave, collapse = " "),
    "URLs procesadas. No se han guardado"
  )
})
