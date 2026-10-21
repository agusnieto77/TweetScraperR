# Get the Users Who Retweeted a Tweet via the X API (experimental)

[![\[Experimental\]](https://lifecycle.r-lib.org/articles/figures/lifecycle-experimental.svg)](https://lifecycle.r-lib.org/articles/stages.html#experimental)

Recupera lxs usuarixs que repostearon un tweet consultando la **API
GraphQL interna de X** (Retweeters). Requiere una sesion importada con
[`importSessionX()`](https://agusnieto77.github.io/TweetScraperR/reference/importSessionX.md).

## Usage

``` r
getTweetsRetweetsAPI(url, n_users = 100, dir = getwd(), save = FALSE)
```

## Arguments

- url:

  URL del tweet.

- n_users:

  Numero maximo de usuarixs a recuperar. Por defecto 100.

- dir:

  Directorio de destino del RDS. Por defecto el de trabajo.

- save:

  Logico. Si TRUE guarda el resultado en un RDS dentro de `dir`. Por
  defecto FALSE: no se escribe ningun archivo.

## Value

Un tibble con una fila por usuarix (mismas columnas que
getUsersDataAPI).

## Examples

``` r
if (FALSE) { # \dontrun{
importSessionX(auth_token = "...", ct0 = "...")
getTweetsRetweetsAPI("https://x.com/sanchezcastejon/status/2111426246517072370", n_users = 100)
} # }
```
