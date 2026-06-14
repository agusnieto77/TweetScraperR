# Create Word Cloud from Tweets

[![\[Experimental\]](https://lifecycle.r-lib.org/articles/figures/lifecycle-experimental.svg)](https://lifecycle.r-lib.org/articles/stages.html#experimental)

Esta función toma un dataframe de tweets y crea una nube de palabras
basada en el contenido de la columna 'texto' o 'tweet'.

## Usage

``` r
plotWords(
  df,
  min_freq = 3,
  max_words = 100,
  random_order = FALSE,
  colors = "random-dark",
  size = 0.3,
  lang = "es",
  sw = NULL
)
```

## Arguments

- df:

  Un dataframe que contiene una columna 'texto' o 'tweet' con el
  contenido de los tweets.

- min_freq:

  Frecuencia mínima de palabras para incluir en la nube (por defecto 3).

- max_words:

  Número máximo de palabras a incluir en la nube (por defecto 100).

- random_order:

  Booleano, si las palabras deben ordenarse aleatoriamente (por defecto
  FALSE).

- colors:

  Vector de colores para las palabras (por defecto 'random-dark').

- size:

  Tamaño de la fuente (por defecto 0.3).

- lang:

  idioma para las stopwords 'es', 'en', 'de', 'pt', etc. (por defecto
  'es').

- sw:

  vector de palabras extras para sumar a la lista de stopwords (por
  defecto NULL).

## Value

Un objeto de tipo wordcloud2.

## Examples

``` r

df <- data.frame(texto = c("Este es un tweet de ejemplo", "Otro tweet para la nube de palabras"))
plotWords(df, min_freq = 1)

{"x":{"word":["tweet","ejemplo","nube","palabras"],"freq":[2,1,1,1],"fontFamily":"Montserrat","fontWeight":"bold","color":"random-dark","minSize":0,"weightFactor":27,"backgroundColor":"white","gridSize":0,"minRotation":-0.7853981633974483,"maxRotation":0.7853981633974483,"shuffle":false,"rotateRatio":0.4,"shape":"circle","ellipticity":0.65,"figBase64":null,"hover":null},"evals":[],"jsHooks":{"render":[{"code":"function(el,x){\n                        console.log(123);\n                        if(!iii){\n                          window.location.reload();\n                          iii = False;\n\n                        }\n  }","data":null}]}}
```
