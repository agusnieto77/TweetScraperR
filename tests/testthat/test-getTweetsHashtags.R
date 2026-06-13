# getTweetsHashtags: extraccion de hashtags sobre data.frame local ---------

test_that("getTweetsHashtags extrae hashtags de la columna 'texto'", {
  df <- data.frame(
    texto = c("Este es un #tweet con #hashtags", "Este no tiene hashtags", "Otro #ejemplo")
  )
  res <- getTweetsHashtags(df)

  expect_true("hashtags" %in% colnames(res))
  expect_type(res$hashtags, "list")
  expect_equal(res$hashtags[[1]], c("#tweet", "#hashtags"))
  expect_equal(res$hashtags[[2]], character(0))
  expect_equal(res$hashtags[[3]], "#ejemplo")
})

test_that("getTweetsHashtags extrae hashtags de la columna 'tweet'", {
  df <- data.frame(tweet = c("#solo #dos aca", "nada"))
  res <- getTweetsHashtags(df)

  expect_equal(res$hashtags[[1]], c("#solo", "#dos"))
  expect_equal(res$hashtags[[2]], character(0))
})

test_that("getTweetsHashtags prioriza 'texto' cuando existen ambas columnas", {
  df <- data.frame(
    texto = "#desde_texto",
    tweet = "#desde_tweet"
  )
  res <- getTweetsHashtags(df)
  expect_equal(res$hashtags[[1]], "#desde_texto")
})

test_that("getTweetsHashtags conserva las columnas y filas originales", {
  df <- data.frame(texto = c("#a", "#b"), otra = c(1, 2))
  res <- getTweetsHashtags(df)
  expect_equal(nrow(res), 2)
  expect_true(all(c("texto", "otra", "hashtags") %in% colnames(res)))
  expect_equal(res$otra, df$otra)
})

test_that("getTweetsHashtags falla sin columna 'texto' ni 'tweet'", {
  expect_error(
    getTweetsHashtags(data.frame(x = 1)),
    "columna llamada 'texto' o 'tweet'"
  )
})
