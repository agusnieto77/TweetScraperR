# Get a User's Profile Data via the X API (experimental)

[![\[Experimental\]](https://lifecycle.r-lib.org/articles/figures/lifecycle-experimental.svg)](https://lifecycle.r-lib.org/articles/stages.html#experimental)

Recupera los datos de perfil de unx o varixs usuarixs consultando la
**API GraphQL interna de X** (UserByScreenName). Requiere una sesion
importada con
[`importSessionX()`](https://agusnieto77.github.io/TweetScraperR/reference/importSessionX.md).

## Usage

``` r
getUsersDataAPI(usernames, dir = getwd(), save = TRUE)
```

## Arguments

- usernames:

  Vector de nombres de usuarix (sin @).

- dir:

  Directorio de destino del RDS. Por defecto el de trabajo.

- save:

  Logico. Si TRUE (por defecto) guarda el resultado en un RDS.

## Value

Un tibble con una fila por usuarix y columnas user, nombre, user_id,
descripcion, seguidores, siguiendo, tweets, favoritos, verificado,
ubicacion, fecha_creacion, url.

## Examples

``` r
if (FALSE) { # \dontrun{
importSessionX(auth_token = "...", ct0 = "...")
getUsersDataAPI(c("NASA", "rstatstweet"))
} # }
```
