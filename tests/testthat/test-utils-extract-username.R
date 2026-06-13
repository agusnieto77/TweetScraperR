# .extract_username: extraccion del username desde la URL del tweet -------

test_that(".extract_username extrae el username de URLs x.com", {
  expect_equal(
    TweetScraperR:::.extract_username("https://x.com/fakeuser/status/1111111111"),
    "fakeuser"
  )
})

test_that(".extract_username extrae el username de URLs twitter.com (bug C03 corregido)", {
  # El sub legacy con alternation devolvia string vacio para twitter.com
  expect_equal(
    TweetScraperR:::.extract_username("https://twitter.com/fakeuser/status/1111111111"),
    "fakeuser"
  )
})

test_that(".extract_username es vectorizado y maneja ambos dominios mezclados", {
  urls <- c(
    "https://x.com/pepe/status/123",
    "https://twitter.com/maria/status/456",
    "https://x.com/juan_77/status/789/photo/1"
  )
  expect_equal(TweetScraperR:::.extract_username(urls), c("pepe", "maria", "juan_77"))
})
