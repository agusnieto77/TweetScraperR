# Get the Combined Timeline of Several Users via the X API (experimental)

[![\[Experimental\]](https://lifecycle.r-lib.org/articles/figures/lifecycle-experimental.svg)](https://lifecycle.r-lib.org/articles/stages.html#experimental)

Recupera y combina los timelines de varias cuentas consultando la **API
GraphQL interna de X**, en una sola sesion de navegador (batch). Util
para monitorear un conjunto curado de cuentas (lo que harias con una
Lista de X, pero sin necesitar un list_id). Devuelve un unico tibble
ordenado por fecha (mas reciente primero) y deduplicado. Requiere una
sesion importada con
[`importSessionX()`](https://agusnieto77.github.io/TweetScraperR/reference/importSessionX.md).

## Usage

``` r
getTweetsTimelinesAPI(usernames, n_tweets = 40, dir = getwd(), save = TRUE)
```

## Arguments

- usernames:

  Vector de nombres de usuarix (acepta "NASA", "@NASA" o la URL completa
  "https://x.com/NASA").

- n_tweets:

  Numero maximo de tweets a recuperar **por cuenta**. Por defecto 40.

- dir:

  Directorio de destino del RDS. Por defecto el de trabajo.

- save:

  Logico. Si TRUE (por defecto) guarda el resultado en un RDS.

## Value

Un tibble con un tweet por fila (mismas columnas que
[`getUserTweetsAPI()`](https://agusnieto77.github.io/TweetScraperR/reference/getUserTweetsAPI.md)),
combinado y ordenado por fecha.

## Examples

``` r
if (FALSE) { # \dontrun{
importSessionX(auth_token = "...", ct0 = "...")
getTweetsTimelinesAPI(c("elravignani", "NucleoIdaes", "BNMMArgentina"), n_tweets = 100)
} # }
```
