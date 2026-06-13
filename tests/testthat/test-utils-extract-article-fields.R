# .extract_article_fields: extraccion rica de 17 columnas ------------------

columnas_esperadas <- c(
  "fecha", "username", "texto", "tweet_citado", "user_citado", "emoticones",
  "links_img_user", "links_img_post", "links_externos", "respuestas",
  "reposteos", "megustas", "reproducciones", "metricas", "urls", "hilo", "url"
)

test_that(".extract_article_fields devuelve un tibble de 1 fila con 17 columnas", {
  art <- read_fixture("article_full.html")
  res <- TweetScraperR:::.extract_article_fields(art, "https://x.com/fakeuser/status/1111111111")

  expect_s3_class(res, "tbl_df")
  expect_equal(nrow(res), 1)
  expect_named(res, columnas_esperadas)
})

test_that(".extract_article_fields parsea fecha, texto y username correctamente", {
  art <- read_fixture("article_full.html")
  res <- TweetScraperR:::.extract_article_fields(art, "https://x.com/fakeuser/status/1111111111")

  expect_s3_class(res$fecha, "POSIXct")
  expect_true(res$fecha == lubridate::ymd_hms("2024-05-01 12:34:56", tz = "UTC"))
  expect_equal(res$username, "fakeuser")
  # El <img> del emoji se reemplaza por su atributo alt en el texto
  expect_equal(res$texto, "Hola mundo grinning_face tests")
  expect_equal(res$url, "https://x.com/fakeuser/status/1111111111")
})

test_that(".extract_article_fields extrae username de URLs twitter.com (bug C03 corregido)", {
  art <- read_fixture("article_full.html")
  res <- TweetScraperR:::.extract_article_fields(art, "https://twitter.com/fakeuser/status/1111111111")
  expect_equal(res$username, "fakeuser")
})

test_that(".extract_article_fields extrae las metricas bilingues", {
  art <- read_fixture("article_full.html")
  res <- TweetScraperR:::.extract_article_fields(art, "https://x.com/fakeuser/status/1111111111")

  expect_identical(res$respuestas, 5L)
  expect_identical(res$reposteos, 10L)
  expect_equal(res$megustas, 20)
  expect_equal(res$reproducciones, 100)
  expect_identical(res$hilo, res$respuestas)
  expect_match(res$metricas, "Me gusta")
})

test_that(".extract_article_fields extrae emojis, links e imagenes", {
  art <- read_fixture("article_full.html")
  res <- TweetScraperR:::.extract_article_fields(art, "https://x.com/fakeuser/status/1111111111")

  expect_equal(res$emoticones[[1]], "grinning_face")
  expect_equal(res$links_img_user, "https://pbs.twimg.com/profile_images/123456/avatar.jpg")
  expect_equal(res$links_img_post[[1]], "https://pbs.twimg.com/media/FAKEMEDIA123.jpg")
  expect_equal(res$links_externos[[1]], "https://t.co/fakelink1")
  # El link /analytics se filtra; queda solo la URL de status limpia
  expect_equal(res$urls[[1]], "/fakeuser/status/1111111111")
})

test_that(".extract_article_fields sin tweet citado devuelve NA en esos campos", {
  art <- read_fixture("article_full.html")
  res <- TweetScraperR:::.extract_article_fields(art, "https://x.com/fakeuser/status/1111111111")

  expect_true(is.na(res$tweet_citado))
  expect_true(is.na(res$user_citado))
})

test_that(".extract_article_fields acepta una lista con el HTML como primer elemento", {
  art <- read_fixture("article_full.html")
  res <- TweetScraperR:::.extract_article_fields(list(art), "https://x.com/fakeuser/status/1111111111")
  expect_s3_class(res, "tbl_df")
  expect_equal(res$username, "fakeuser")
})

test_that(".extract_article_fields acepta un documento xml ya parseado", {
  art <- xml2::read_html(read_fixture("article_full.html"))
  res <- TweetScraperR:::.extract_article_fields(art, "https://x.com/fakeuser/status/1111111111")
  expect_s3_class(res, "tbl_df")
  expect_equal(res$username, "fakeuser")
})

test_that(".extract_article_fields con input invalido devuelve NULL con mensaje", {
  expect_message(
    res <- TweetScraperR:::.extract_article_fields(12345, "https://x.com/fakeuser/status/1"),
    "Error al procesar el tweet"
  )
  expect_null(res)
})
