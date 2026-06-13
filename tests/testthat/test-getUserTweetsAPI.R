# Parser de la API GraphQL/JSON (getUserTweetsAPI) -------------------------

test_that(".x_parse_twitter_date parsea el formato de Twitter como UTC (sin depender del locale)", {
  d <- TweetScraperR:::.x_parse_twitter_date("Fri Jun 12 21:22:33 +0000 2026")
  expect_s3_class(d, "POSIXct")
  expect_equal(format(d, "%Y-%m-%d %H:%M:%S", tz = "UTC"), "2026-06-12 21:22:33")
  # entradas invalidas -> NA, sin error
  expect_true(is.na(TweetScraperR:::.x_parse_twitter_date(NULL)))
  expect_true(is.na(TweetScraperR:::.x_parse_twitter_date("basura")))
})

test_that(".parse_timeline_tweets extrae tweets, metricas y cursor del JSON", {
  d <- jsonlite::fromJSON(
    testthat::test_path("fixtures", "user_tweets.json"),
    simplifyVector = FALSE
  )
  res <- TweetScraperR:::.parse_timeline_tweets(d)

  expect_equal(nrow(res$tweets), 2)
  expect_equal(res$cursor, "CURSOR_ABC")
  expect_setequal(
    names(res$tweets),
    c("fecha", "user", "texto", "respuestas", "retweets", "citas",
      "megustas", "views", "es_retweet", "es_cita", "url", "tweet_id")
  )

  t1 <- res$tweets[1, ]
  expect_equal(t1$user, "@NASA")           # screen_name via core.core
  expect_equal(t1$texto, "Texto completo de prueba uno.")
  expect_equal(t1$megustas, 7203L)
  expect_equal(t1$retweets, 1194L)
  expect_equal(t1$views, 470857L)          # views como entero, no string
  expect_false(t1$es_cita)
  expect_equal(t1$url, "https://x.com/NASA/status/1001")
  expect_s3_class(t1$fecha, "POSIXct")

  t2 <- res$tweets[2, ]
  expect_equal(t2$user, "@NASA")           # screen_name via legacy (fallback) + TweetWithVisibilityResults desempaquetado
  expect_true(t2$es_cita)                  # is_quote_status = TRUE
  expect_equal(t2$tweet_id, "1002")
})

test_that(".parse_timeline_tweets devuelve NULL en tweets si no hay entradas", {
  vacio <- list(data = list(user = list(result = list(
    timeline = list(timeline = list(instructions = list(
      list(type = "TimelineAddEntries", entries = list())
    )))
  ))))
  res <- TweetScraperR:::.parse_timeline_tweets(vacio)
  expect_null(res$tweets)
})

# .find_instructions: ubicar el path correcto segun el endpoint --------------

test_that(".find_instructions encuentra las instructions en ambos paths (UserTweets y Search)", {
  ut <- jsonlite::fromJSON(testthat::test_path("fixtures", "user_tweets.json"), simplifyVector = FALSE)
  se <- jsonlite::fromJSON(testthat::test_path("fixtures", "search_timeline.json"), simplifyVector = FALSE)
  expect_type(TweetScraperR:::.find_instructions(ut), "list")
  expect_type(TweetScraperR:::.find_instructions(se), "list")
  expect_null(TweetScraperR:::.find_instructions(list(a = 1, b = "x")))
})

test_that(".parse_timeline_tweets parsea el JSON de SearchTimeline (otro path)", {
  se <- jsonlite::fromJSON(testthat::test_path("fixtures", "search_timeline.json"), simplifyVector = FALSE)
  res <- TweetScraperR:::.parse_timeline_tweets(se)
  expect_equal(nrow(res$tweets), 1)
  expect_equal(res$tweets$user, "@RosanaFerrero")
  expect_equal(res$tweets$url, "https://x.com/RosanaFerrero/status/3001")
  expect_equal(res$cursor, "SEARCH_CURSOR")
})
