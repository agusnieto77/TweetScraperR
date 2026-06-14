# Create Bar Chart of EmoticonsPNG in Tweets

[![\[Experimental\]](https://lifecycle.r-lib.org/articles/figures/lifecycle-experimental.svg)](https://lifecycle.r-lib.org/articles/stages.html#experimental)

Esta función toma un dataframe de tweets y crea un gráfico de barras
mostrando la frecuencia de los emoticones en colores utilizados en los
tweets.

## Usage

``` r
plotEmojisPNG(df, top_n = 10, fill = "skyblue", color = "grey30")
```

## Arguments

- df:

  Un dataframe que contiene una columna 'emoticones' con listas de
  emoticones.

- top_n:

  Número de emoticones más frecuentes a mostrar (por defecto 10).

- fill:

  Color de las barras en el gráfico (por defecto "skyblue").

- color:

  Color de los bordes de las barras en el gráfico (por defecto
  "grey30").

## Value

Un objeto ggplot con el gráfico de barras.

## Examples

``` r
if (FALSE) { # \dontrun{
df <- data.frame(emoticones = I(list(
  c("\U0001F60A", "\U0001F602", "\U0001F602"),
  c("\U0001F60A"),
  c("\U0001F602", "\U0001F60D"),
  character(0)
)))
plotEmojisPNG(df)
} # }
```
