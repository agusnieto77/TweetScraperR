# Get Tweet Data from URLs via the X API (experimental)

[![\[Experimental\]](https://lifecycle.r-lib.org/articles/figures/lifecycle-experimental.svg)](https://lifecycle.r-lib.org/articles/stages.html#experimental)

Recupera los datos de tweets a partir de sus URLs consultando la **API
GraphQL interna de X** (TweetDetail). Devuelve datos estructurados del
JSON. Es el reemplazo basado en API de
[`getTweetsData()`](https://agusnieto77.github.io/TweetScraperR/reference/getTweetsData.md).
Requiere una sesion importada con
[`importSessionX()`](https://agusnieto77.github.io/TweetScraperR/reference/importSessionX.md).

## Usage

``` r
getTweetsDataAPI(urls_tweets, dir = getwd(), save = TRUE)
```

## Arguments

- urls_tweets:

  Vector de URLs de tweets (formato https://x.com/u/status/123).

- dir:

  Directorio de destino del RDS. Por defecto el de trabajo.

- save:

  Logico. Si TRUE (por defecto) guarda el resultado en un RDS.

## Value

Un tibble con una fila por tweet (mismas columnas que getUserTweetsAPI).

## Examples

``` r
if (FALSE) { # \dontrun{
importSessionX(auth_token = "...", ct0 = "...")
getTweetsDataAPI(c("https://x.com/NASA/status/123", "https://x.com/NASA/status/456"))
} # }
```
