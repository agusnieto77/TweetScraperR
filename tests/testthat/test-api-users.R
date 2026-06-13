# Parser de usuarios de la API (.parse_users / .user_row) -------------------

test_that(".parse_users extrae usuarios y cursor del JSON de lista", {
  d <- jsonlite::fromJSON(testthat::test_path("fixtures", "users_list.json"), simplifyVector = FALSE)
  res <- TweetScraperR:::.parse_users(d)
  expect_equal(nrow(res$users), 2)
  expect_equal(res$cursor, "UCURSOR")
  expect_setequal(
    names(res$users),
    c("user", "nombre", "user_id", "descripcion", "seguidores", "siguiendo",
      "tweets", "favoritos", "verificado", "ubicacion", "fecha_creacion", "url")
  )
  u1 <- res$users[1, ]
  expect_equal(u1$user, "@RosanaFerrero")
  expect_equal(u1$nombre, "Rosana")
  expect_equal(u1$seguidores, 1200L)
  expect_true(u1$verificado)            # is_blue_verified
  expect_equal(u1$ubicacion, "Buenos Aires")
  expect_equal(u1$url, "https://x.com/RosanaFerrero")
  expect_s3_class(u1$fecha_creacion, "POSIXct")
})

test_that(".user_row devuelve NULL si no hay handle", {
  expect_null(TweetScraperR:::.user_row(NULL))
  expect_null(TweetScraperR:::.user_row(list(legacy = list(name = "x"))))
})
