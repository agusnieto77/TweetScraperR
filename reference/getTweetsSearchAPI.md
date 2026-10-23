# Search Tweets via the X API (experimental)

[![\[Experimental\]](https://lifecycle.r-lib.org/articles/figures/lifecycle-experimental.svg)](https://lifecycle.r-lib.org/articles/stages.html#experimental)

Busca tweets que coinciden con una consulta consultando la **API GraphQL
interna de X** (en lugar de scrapear HTML). Devuelve datos estructurados
del JSON: texto completo, fecha exacta y metricas (respuestas, retweets,
citas, me gusta, vistas). Requiere una sesion importada con
[`importSessionX()`](https://agusnieto77.github.io/TweetScraperR/reference/importSessionX.md).

## Usage

``` r
getTweetsSearchAPI(
  search = "#RStats",
  n_tweets = 40,
  product = c("Latest", "Top", "Media"),
  since = NULL,
  until = NULL,
  dir = getwd(),
  save = FALSE
)
```

## Arguments

- search:

  Consulta de busqueda (soporta operadores de X, p.ej. "from:NASA",
  "#RStats", "lang:es"). Por defecto "#RStats".

- n_tweets:

  Numero maximo de tweets a recuperar. Por defecto 40.

- product:

  Pestania de resultados: "Latest" (recientes, por defecto), "Top"
  (destacados) o "Media".

- since:

  Desde cuando (opcional). Un dia `"YYYY-MM-DD"` (desde las 00:00 UTC de
  ese dia) o un instante `"YYYY-MM-DD HH:MM[:SS]"` en UTC (tambien con
  `_` o `T` como separador y sufijo `_UTC`). Acepta objetos `Date` y
  `POSIXct`. Se traduce al operador `since_time:` de X.

- until:

  Hasta cuando (opcional), mismos formatos que `since`. Un dia incluye
  ese dia completo (UTC); se traduce a `until_time:`.

- dir:

  Directorio de destino del RDS. Por defecto el de trabajo.

- save:

  Logico. Si TRUE guarda el resultado en un RDS dentro de `dir`. Por
  defecto FALSE: no se escribe ningun archivo.

## Value

Un tibble con un tweet por fila (mismas columnas que
[`getUserTweetsAPI()`](https://agusnieto77.github.io/TweetScraperR/reference/getUserTweetsAPI.md),
incluyendo media, hashtags, menciones, etc.).

## Examples

``` r
if (FALSE) { # \dontrun{
importSessionX(auth_token = "...", ct0 = "...")
tw <- getTweetsSearchAPI("#RStats", n_tweets = 100)
getTweetsSearchAPI("from:NASA artemis", product = "Top")
} # }
```
