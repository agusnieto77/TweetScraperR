# Get Iterative Tweets in Streaming

[![\[Experimental\]](https://lifecycle.r-lib.org/articles/figures/lifecycle-experimental.svg)](https://lifecycle.r-lib.org/articles/stages.html#experimental)

**Obsoleta**: preferí getTweetsSearchAPI(), basada en la API de X (datos
del JSON, mas robusta).

Esta función recolecta tweets de forma iterativa utilizando
TweetScraperR, con la opción de cerrar el navegador entre iteraciones.

## Usage

``` r
getTweetsSearchStreamingFor(
  iterations,
  search,
  n_tweets,
  sleep,
  dir,
  system = "unix",
  kill_system = FALSE,
  sleep_time = 300
)
```

## Arguments

- iterations:

  Número de iteraciones a realizar

- search:

  Término de búsqueda para los tweets

- n_tweets:

  Número de tweets a recolectar en cada iteración

- sleep:

  Tiempo de espera para la carga de tweets. Por defecto este valor es de
  3 segundos.

- dir:

  Directorio donde se guardarán los tweets

- system:

  Sistema operativo ('windows', 'unix', 'macOS'). Se mantiene por
  compatibilidad; el cierre del navegador ya no depende del sistema
  operativo.

- kill_system:

  Booleano que indica si se debe cerrar el navegador (solo las sesiones
  propias del paquete) después de cada iteración (por defecto: FALSE)

- sleep_time:

  Tiempo de espera entre iteraciones en segundos. Por defecto este valor
  es de 300 segundos.

## Value

No devuelve un valor, pero guarda los tweets en el directorio
especificado

## Examples

``` r
if (FALSE) { # \dontrun{
getTweetsSearchStreamingFor(
  iterations = 5,
  search = "Milei",
  n_tweets = 10,
  dir = "./data/tweets",
  system = "unix",
  kill_system = FALSE,
  sleep_time = 5
)
} # }
```
