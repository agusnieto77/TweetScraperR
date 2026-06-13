# plotWords / plotEmojis: validacion de inputs invalidos -------------------

test_that("plotWords falla sin columna 'texto' ni 'tweet'", {
  expect_error(
    plotWords(data.frame(x = 1:3)),
    "columna llamada 'texto' o 'tweet'"
  )
})

test_that("plotWords valida que 'sw' sea character", {
  df <- data.frame(texto = c("hola mundo bonito", "otro texto largo"))
  expect_error(plotWords(df, sw = 123), "'sw' debe ser una cadena de texto")
  expect_error(plotWords(df, sw = TRUE), "'sw' debe ser una cadena de texto")
  expect_error(plotWords(df, sw = list("a")), "'sw' debe ser una cadena de texto")
})

test_that("plotEmojis falla sin columna 'emoticones'", {
  expect_error(
    plotEmojis(data.frame(x = 1:3)),
    "columna llamada 'emoticones'"
  )
})

test_that("plotEmojis valida que 'emoticones' sea columna de listas", {
  expect_error(
    plotEmojis(data.frame(emoticones = c("a", "b"))),
    "columna de listas"
  )
})

test_that("plotEmojis construye el grafico con una columna de listas valida", {
  df <- data.frame(emoticones = I(list(
    c("cara_feliz", "cara_risa", "cara_risa"),
    c("cara_feliz"),
    c("cara_risa", "corazon"),
    character(0)
  )))
  p <- plotEmojis(df)
  expect_s3_class(p, "ggplot")
  built <- NULL
  expect_no_error(built <- ggplot2::ggplot_build(p))
  expect_equal(nrow(built$data[[1]]), 3) # tres emojis distintos
})
