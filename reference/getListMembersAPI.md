# Get the Members of an X List via the X API (experimental)

[![\[Experimental\]](https://lifecycle.r-lib.org/articles/figures/lifecycle-experimental.svg)](https://lifecycle.r-lib.org/articles/stages.html#experimental)

Recupera las cuentas que integran una Lista de X consultando la **API
GraphQL interna de X** (ListMembers). Requiere una sesion importada con
[`importSessionX()`](https://agusnieto77.github.io/TweetScraperR/reference/importSessionX.md).

## Usage

``` r
getListMembersAPI(list_id, n_users = 100, dir = getwd(), save = FALSE)
```

## Arguments

- list_id:

  Id numerico de la lista o su URL (`https://x.com/i/lists/<id>`).

- n_users:

  Numero maximo de usuarixs a recuperar. Por defecto 100.

- dir:

  Directorio de destino del RDS. Por defecto el de trabajo.

- save:

  Logico. Si TRUE guarda el resultado en un RDS dentro de `dir`. Por
  defecto FALSE: no se escribe ningun archivo.

## Value

Un tibble con una fila por usuarix (mismas columnas que
[`getUsersDataAPI()`](https://agusnieto77.github.io/TweetScraperR/reference/getUsersDataAPI.md)).

## Examples

``` r
if (FALSE) { # \dontrun{
importSessionX(auth_token = "...", ct0 = "...")
getListMembersAPI("53645372")
} # }
```
