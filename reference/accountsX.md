# Estado del pool de cuentas de X

Lista las cuentas importadas con
[`importSessionX()`](https://agusnieto77.github.io/TweetScraperR/reference/importSessionX.md),
si estan activas, en pausa (y hasta cuando) por endpoint, y cuantas
respuestas aportaron.

## Usage

``` r
accountsX()
```

## Value

Un tibble con una fila por cuenta y columnas: cuenta, usuario_x
(@usuario real, lo completa
[`checkAccountsX()`](https://agusnieto77.github.io/TweetScraperR/reference/checkAccountsX.md)),
activa, pausas (endpoints en pausa y hora en que se liberan), requests
(total de respuestas obtenidas), requests_por_endpoint, ultimo_uso,
proxy, error.

## Examples

``` r
if (FALSE) { # \dontrun{
accountsX()
} # }
```
