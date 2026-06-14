# Create Line Graph of Tweets by Time

[![\[Experimental\]](https://lifecycle.r-lib.org/articles/figures/lifecycle-experimental.svg)](https://lifecycle.r-lib.org/articles/stages.html#experimental)

Esta función toma un dataframe de tweets y crea un gráfico de líneas
mostrando la frecuencia de tweets a lo largo del tiempo, con opciones
para agrupar por hora, día, semana, mes o año.

## Usage

``` r
plotTime(df, group_by = "hour", color = "blue")
```

## Arguments

- df:

  Un dataframe que contiene una columna 'fecha' con las fechas de los
  tweets.

- group_by:

  Una cadena que indica cómo agrupar las fechas. Opciones válidas son
  "hour", "day", "week", "month", "year".

- color:

  Color de la línea en el gráfico (por defecto "blue").

## Value

Un objeto ggplot con el gráfico de líneas.

## Examples

``` r

df <- data.frame(fecha = c(
  seq(as.POSIXct("2023-01-02 00:00:00"), by = "hour", length.out = 3),
  seq(as.POSIXct("2023-01-02 01:00:00"), by = "hour", length.out = 2),
  seq(as.POSIXct("2023-01-02 03:00:00"), by = "hour", length.out = 3),
  seq(as.POSIXct("2023-01-02 01:00:00"), by = "hour", length.out = 2),
  seq(as.POSIXct("2023-01-02 03:00:00"), by = "hour", length.out = 3),
  seq(as.POSIXct("2023-01-02 01:00:00"), by = "hour", length.out = 2),
  seq(as.POSIXct("2023-01-02 03:00:00"), by = "hour", length.out = 3)
))
plotTime(df, group_by = "hour")

```
