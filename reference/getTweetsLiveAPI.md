# Capture Tweets from a Search as They Are Published (experimental)

[![\[Experimental\]](https://lifecycle.r-lib.org/articles/figures/lifecycle-experimental.svg)](https://lifecycle.r-lib.org/articles/stages.html#experimental)

Sigue una busqueda "hacia adelante": repite
[`getTweetsSearchAPI()`](https://agusnieto77.github.io/TweetScraperR/reference/getTweetsSearchAPI.md)
(pestania "Latest") cada `interval` segundos durante `duration` segundos
y acumula solo los tweets nuevos. Desde la segunda ronda la consulta
lleva el operador `since_id:` con el ID mas reciente ya recolectado, asi
que X devuelve solo lo publicado despues y no se vuelve a gastar cupo en
lo ya traido.

No es un streaming real: la granularidad es `interval`. Si en una ronda
aparecen `n_tweets` o mas tweets nuevos, los que exceden el tope quedan
sin recolectar (se avisa con un mensaje); en ese caso conviene bajar
`interval` o subir `n_tweets`. Un error en una ronda se informa y la
captura sigue con la proxima. Interrumpir con Esc / Ctrl+C termina la
captura y devuelve lo acumulado hasta ese momento.

## Usage

``` r
getTweetsLiveAPI(
  search = "#RStats",
  interval = 300,
  duration = 3600,
  n_tweets = 100,
  max_tweets = Inf,
  dir = getwd(),
  save = FALSE
)
```

## Arguments

- search:

  Consulta de busqueda (soporta operadores de X, p.ej. "lang:es",
  "-filter:retweets"). Por defecto "#RStats".

- interval:

  Segundos entre rondas. Minimo 60. Por defecto 300.

- duration:

  Segundos totales de captura. Por defecto 3600 (una hora).

- n_tweets:

  Tope de tweets por ronda. La primera ronda trae hasta `n_tweets` de
  los mas recientes como punto de partida. Por defecto 100.

- max_tweets:

  La captura termina al alcanzar este total acumulado. Por defecto `Inf`
  (solo limita `duration`).

- dir:

  Directorio de destino del RDS. Por defecto el de trabajo.

- save:

  Logico. Si TRUE guarda lo acumulado en un RDS dentro de `dir` despues
  de cada ronda (si la sesion de R se corta, lo recolectado no se
  pierde). Por defecto FALSE: no se escribe ningun archivo.

## Value

Un tibble con un tweet por fila, del mas nuevo al mas viejo (mismas
columnas que
[`getTweetsSearchAPI()`](https://agusnieto77.github.io/TweetScraperR/reference/getTweetsSearchAPI.md)).

## Examples

``` r
if (FALSE) { # \dontrun{
importSessionX(auth_token = "...", ct0 = "...")
# Una hora de captura, una ronda cada 5 minutos, guardando en cada ronda
vivo <- getTweetsLiveAPI("#RStats", interval = 300, duration = 3600, save = TRUE)
} # }
```
