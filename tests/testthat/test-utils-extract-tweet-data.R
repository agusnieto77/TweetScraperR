# .extract_tweet_data: parseo de articles a tibble fecha/user/tweet/url ----

test_that(".extract_tweet_data parsea un article valido", {
  art <- read_fixture("article_full.html")
  res <- TweetScraperR:::.extract_tweet_data(art)

  expect_s3_class(res, "tbl_df")
  expect_equal(nrow(res), 1)
  expect_named(
    res,
    c("art_html", "fecha", "user", "tweet", "url", "fecha_captura")
  )

  expect_s3_class(res$fecha, "POSIXct")
  expect_true(res$fecha == lubridate::ymd_hms("2024-05-01 12:34:56", tz = "UTC"))
  expect_equal(res$user, "Fake User")
  # html_text() no reemplaza el <img> del emoji: queda el texto plano
  expect_equal(res$tweet, "Hola mundo  tests")
  expect_equal(res$url, "https://x.com/fakeuser/status/1111111111")
  expect_s3_class(res$fecha_captura, "POSIXct")
})

test_that(".extract_tweet_data parsea varios articles y conserva el orden", {
  arts <- c(read_fixture("article_full.html"), read_fixture("article_second.html"))
  res <- TweetScraperR:::.extract_tweet_data(arts)

  expect_equal(nrow(res), 2)
  expect_equal(res$user, c("Fake User", "Otra Cuenta"))
  expect_equal(
    res$url,
    c(
      "https://x.com/fakeuser/status/1111111111",
      "https://x.com/otracuenta/status/2222222222"
    )
  )
  expect_equal(res$tweet[2], "Segundo tweet de prueba")
  expect_true(res$fecha[2] == lubridate::ymd_hms("2024-05-02 08:00:00", tz = "UTC"))
})

test_that(".extract_tweet_data deduplica por url", {
  art1 <- read_fixture("article_full.html")
  art2 <- read_fixture("article_second.html")
  res <- TweetScraperR:::.extract_tweet_data(c(art1, art1, art2, art1))

  expect_equal(nrow(res), 2)
  expect_equal(anyDuplicated(res$url), 0)
})

test_that(".extract_tweet_data filtra articles invalidos (sin fecha ni url)", {
  invalido <- read_fixture("article_invalid.html")
  valido <- read_fixture("article_full.html")

  # Solo invalidos: tibble sin filas
  res_inv <- TweetScraperR:::.extract_tweet_data(invalido)
  expect_equal(nrow(res_inv), 0)

  # Mezcla: solo sobrevive el valido
  res_mix <- TweetScraperR:::.extract_tweet_data(c(invalido, valido))
  expect_equal(nrow(res_mix), 1)
  expect_equal(res_mix$url, "https://x.com/fakeuser/status/1111111111")
})

test_that(".extract_tweet_data con input vacio devuelve tibble vacio", {
  res <- TweetScraperR:::.extract_tweet_data(character(0))
  expect_s3_class(res, "tbl_df")
  expect_equal(nrow(res), 0)
})
