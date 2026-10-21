# Search Users via the X API (experimental)

[![\[Experimental\]](https://lifecycle.r-lib.org/articles/figures/lifecycle-experimental.svg)](https://lifecycle.r-lib.org/articles/stages.html#experimental)

Busca cuentas (pestania "Personas" del buscador de X) consultando la
**API GraphQL interna de X** (SearchTimeline). Requiere una sesion
importada con
[`importSessionX()`](https://agusnieto77.github.io/TweetScraperR/reference/importSessionX.md).

## Usage

``` r
getUsersSearchAPI(search, n_users = 40, dir = getwd(), save = FALSE)
```

## Arguments

- search:

  Consulta de busqueda (nombre, tema, etc.).

- n_users:

  Numero maximo de usuarixs a recuperar. Por defecto 40.

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
getUsersSearchAPI("rstats", n_users = 50)
} # }
```
