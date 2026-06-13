# plotTime: grafico de frecuencia temporal ---------------------------------

# Fechas POSIXct que cruzan dias, semanas, meses y anios
df_fechas <- data.frame(
  fecha = seq(
    as.POSIXct("2023-01-15 10:00:00", tz = "UTC"),
    by = "5 weeks",
    length.out = 12
  )
)

test_that("plotTime construye sin error para todos los group_by (C06 corregido)", {
  # week/month/year fallaban antes del fix C06 (escala de eje x incorrecta)
  for (g in c("hour", "day", "week", "month", "year")) {
    p <- plotTime(df_fechas, group_by = g)
    expect_s3_class(p, "ggplot")
    built <- NULL
    expect_no_error(built <- ggplot2::ggplot_build(p))
    expect_gte(nrow(built$data[[1]]), 1)
  }
})

test_that("plotTime agrupa las fechas segun group_by", {
  df <- data.frame(
    fecha = as.POSIXct(
      c(
        "2023-01-02 00:10:00", "2023-01-02 00:50:00",
        "2023-01-02 01:30:00", "2023-01-03 10:00:00"
      ),
      tz = "UTC"
    )
  )
  p_hour <- plotTime(df, group_by = "hour")
  expect_equal(nrow(p_hour$data), 3) # 00hs (x2), 01hs, y 10hs del dia 3

  p_day <- plotTime(df, group_by = "day")
  expect_equal(nrow(p_day$data), 2) # 2023-01-02 (x3) y 2023-01-03
  expect_equal(p_day$data$count, c(3, 1))
})

test_that("plotTime usa el color indicado", {
  p <- plotTime(df_fechas, group_by = "day", color = "red")
  built <- ggplot2::ggplot_build(p)
  expect_true(all(built$data[[1]]$colour == "red"))
})

test_that("plotTime valida sus inputs", {
  expect_error(
    plotTime(data.frame(x = 1)),
    "columna llamada 'fecha'"
  )
  expect_error(
    plotTime(data.frame(fecha = "2023-01-01")),
    "POSIXct/POSIXlt"
  )
  expect_error(
    plotTime(data.frame(fecha = as.Date("2023-01-01"))),
    "POSIXct/POSIXlt"
  )
  expect_error(
    plotTime(df_fechas, group_by = "decade"),
    "group_by debe ser uno de"
  )
})
