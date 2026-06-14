# Get a User's Followers via the X API (experimental)

[![\[Experimental\]](https://lifecycle.r-lib.org/articles/figures/lifecycle-experimental.svg)](https://lifecycle.r-lib.org/articles/stages.html#experimental)

Recupera lxs seguidorxs de unx usuarix consultando la **API GraphQL
interna de X** (Followers). Requiere una sesion importada con
[`importSessionX()`](https://agusnieto77.github.io/TweetScraperR/reference/importSessionX.md).

## Usage

``` r
getUserFollowersAPI(username, n_users = 100, dir = getwd(), save = TRUE)
```

## Arguments

- username:

  Nombre de usuarix (sin @).

- n_users:

  Numero maximo de usuarixs a recuperar. Por defecto 100.

- dir:

  Directorio de destino del RDS. Por defecto el de trabajo.

- save:

  Logico. Si TRUE (por defecto) guarda el resultado en un RDS.

## Value

Un tibble con una fila por usuarix (mismas columnas que
getUsersDataAPI).

## Examples

``` r
if (FALSE) { # \dontrun{
importSessionX(auth_token = "...", ct0 = "...")
getUserFollowersAPI("rstatstweet", n_users = 200)
} # }
```
