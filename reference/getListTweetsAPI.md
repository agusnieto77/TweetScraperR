# Get the Tweets of an X List via the X API (experimental)

[![\[Experimental\]](https://lifecycle.r-lib.org/articles/figures/lifecycle-experimental.svg)](https://lifecycle.r-lib.org/articles/stages.html#experimental)

Recupera los tweets mas recientes de una Lista de X consultando la **API
GraphQL interna de X** (ListLatestTweetsTimeline). Requiere una sesion
importada con
[`importSessionX()`](https://agusnieto77.github.io/TweetScraperR/reference/importSessionX.md).

## Usage

``` r
getListTweetsAPI(list_id, n_tweets = 40, dir = getwd(), save = TRUE)
```

## Arguments

- list_id:

  Id numerico de la lista o su URL (`https://x.com/i/lists/<id>`).

- n_tweets:

  Numero maximo de tweets a recuperar. Por defecto 40.

- dir:

  Directorio de destino del RDS. Por defecto el de trabajo.

- save:

  Logico. Si TRUE (por defecto) guarda el resultado en un RDS.

## Value

Un tibble con un tweet por fila (mismas columnas que
[`getUserTweetsAPI()`](https://agusnieto77.github.io/TweetScraperR/reference/getUserTweetsAPI.md)).

## Examples

``` r
if (FALSE) { # \dontrun{
importSessionX(auth_token = "...", ct0 = "...")
getListTweetsAPI("https://x.com/i/lists/53645372", n_tweets = 100)
} # }
```
