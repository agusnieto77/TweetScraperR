# .sel: lista centralizada de selectores CSS ------------------------------

test_that(".sel existe y es una lista nombrada no vacia", {
  sel <- TweetScraperR:::.sel
  expect_type(sel, "list")
  expect_gt(length(sel), 0)
  expect_true(all(nzchar(names(sel))))
})

test_that(".sel: todos los elementos son strings no vacios de largo 1", {
  sel <- TweetScraperR:::.sel
  for (nm in names(sel)) {
    expect_true(is.character(sel[[nm]]), info = paste0(".sel$", nm, " no es character"))
    expect_length(sel[[nm]], 1)
    expect_true(nzchar(sel[[nm]]), info = paste0(".sel$", nm, " es string vacio"))
    expect_false(is.na(sel[[nm]]), info = paste0(".sel$", nm, " es NA"))
  }
})

test_that(".sel contiene las claves usadas por los helpers de extraccion", {
  sel <- TweetScraperR:::.sel
  claves <- c("login_url", "tweet_url", "tweet_user", "tweet_text",
              "tweet_time", "article", "quoted_user", "tweet_emoji")
  expect_true(all(claves %in% names(sel)))
})
