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
    c("fecha", "user", "texto", "idioma", "respuestas", "retweets", "citas",
      "megustas", "views", "emoticones", "hashtags", "menciones",
      "urls_externas", "media", "media_tipo", "es_retweet", "es_cita",
      "tweet_citado_id", "conversation_id", "url", "tweet_id")
  )

  t1 <- res$tweets[1, ]
  expect_equal(t1$user, "@NASA")           # screen_name via core.core
  expect_equal(t1$texto, "Texto rico uno #RStats")
  expect_equal(t1$megustas, 7203L)
  expect_equal(t1$views, 470857L)          # views como entero, no string
  expect_false(t1$es_cita)
  expect_equal(t1$url, "https://x.com/NASA/status/1001")
  expect_s3_class(t1$fecha, "POSIXct")

  # campos enriquecidos (entities / media / idioma)
  expect_equal(t1$idioma, "es")
  expect_equal(t1$hashtags[[1]], "RStats")
  expect_equal(t1$menciones[[1]], "NASA")
  expect_equal(t1$urls_externas[[1]], "https://example.com/a")
  expect_equal(t1$media[[1]], "https://pbs.twimg.com/media/x.jpg")
  expect_equal(t1$media_tipo[[1]], "photo")
  expect_equal(t1$conversation_id, "1001")

  t2 <- res$tweets[2, ]
  expect_equal(t2$user, "@NASA")           # screen_name via legacy (fallback) + TweetWithVisibilityResults desempaquetado
  expect_true(t2$es_cita)                  # is_quote_status = TRUE
  expect_equal(t2$tweet_id, "1002")
  expect_equal(t2$tweet_citado_id, "999")  # quoted_status_result.result.rest_id
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

# TweetDetail: hilos de conversacion (conversationthread) --------------------

test_that(".parse_timeline_tweets desarma conversationthread (tweet + respuestas)", {
  d <- jsonlite::fromJSON(testthat::test_path("fixtures", "tweet_detail.json"), simplifyVector = FALSE)
  res <- TweetScraperR:::.parse_timeline_tweets(d)
  # 1 tweet directo + 2 respuestas anidadas en items
  expect_equal(nrow(res$tweets), 3)
  expect_setequal(res$tweets$tweet_id, c("5000", "5001", "5002"))
  expect_equal(res$cursor, "TDCURSOR")
})

# .extract_emojis: compatibilidad con plotEmojis ----------------------------

test_that(".extract_emojis extrae los emojis de un texto", {
  expect_equal(TweetScraperR:::.extract_emojis("hola \U0001F52C\U0001F9E0 mundo"),
               c("\U0001F52C", "\U0001F9E0"))
  expect_equal(TweetScraperR:::.extract_emojis("sin emojis"), character(0))
  expect_equal(TweetScraperR:::.extract_emojis(NULL), character(0))
  expect_equal(TweetScraperR:::.extract_emojis(""), character(0))
})
