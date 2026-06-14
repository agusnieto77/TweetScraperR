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
  dir = getwd(),
  save = TRUE
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

- dir:

  Directorio de destino del RDS. Por defecto el de trabajo.

- save:

  Logico. Si TRUE (por defecto) guarda el resultado en un RDS.

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
