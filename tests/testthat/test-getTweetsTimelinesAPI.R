# Normalizacion de handles (.x_handle) -------------------------------------

test_that(".x_handle normaliza handles, @handles y URLs de x.com/twitter.com", {
  expect_equal(TweetScraperR:::.x_handle("NASA"), "NASA")
  expect_equal(TweetScraperR:::.x_handle("@NASA"), "NASA")
  expect_equal(TweetScraperR:::.x_handle("https://x.com/NASA"), "NASA")
  expect_equal(TweetScraperR:::.x_handle("https://twitter.com/NASA"), "NASA")
  expect_equal(TweetScraperR:::.x_handle("https://www.x.com/NASA/status/123"), "NASA")
  expect_equal(TweetScraperR:::.x_handle("  @elravignani  "), "elravignani")
  # vectorizado
  expect_equal(
    TweetScraperR:::.x_handle(c("@a", "https://x.com/b", "c")),
    c("a", "b", "c")
  )
})
