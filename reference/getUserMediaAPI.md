# Get a User's Media Tweets via the X API (experimental)

[![\[Experimental\]](https://lifecycle.r-lib.org/articles/figures/lifecycle-experimental.svg)](https://lifecycle.r-lib.org/articles/stages.html#experimental)

Recupera los tweets con media (fotos/videos) de unx usuarix consultando
la **API GraphQL interna de X** (UserMedia). Devuelve datos
estructurados del JSON. Requiere una sesion importada con
[`importSessionX()`](https://agusnieto77.github.io/TweetScraperR/reference/importSessionX.md).

## Usage

``` r
getUserMediaAPI(username = "NASA", n_tweets = 40, dir = getwd(), save = TRUE)
```

## Arguments

- username:

  Nombre de usuarix (sin @). Por defecto "NASA".

- n_tweets:

  Numero maximo de tweets a recuperar. Por defecto 40.

- dir:

  Directorio de destino del RDS. Por defecto el de trabajo.

- save:

  Logico. Si TRUE (por defecto) guarda el resultado en un RDS.

## Value

Un tibble con un tweet por fila (mismas columnas que getUserTweetsAPI).

## Examples

``` r
if (FALSE) { # \dontrun{
importSessionX(auth_token = "...", ct0 = "...")
getUserMediaAPI("NASA", n_tweets = 100)
} # }
```
