# Cargar y validar cuentas de X desde la consola

Asistente interactivo para armar el pool de cuentas sin escribir codigo
ni dejar las cookies en el historial de R: pide el nombre de cada
cuenta, su `auth_token` y su `ct0` (la entrada queda oculta) y un proxy
opcional, la importa con
[`importSessionX()`](https://agusnieto77.github.io/TweetScraperR/reference/importSessionX.md)
y la valida en el momento con
[`checkAccountsX()`](https://agusnieto77.github.io/TweetScraperR/reference/checkAccountsX.md).
Se termina dejando el nombre vacio.

## Usage

``` r
setupAccountsX(validate = TRUE)
```

## Arguments

- validate:

  Logico. Si TRUE (por defecto) valida cada cuenta apenas se carga.

## Value

Invisiblemente, el estado del pool
([`accountsX()`](https://agusnieto77.github.io/TweetScraperR/reference/accountsX.md)).

## Details

En el campo `auth_token` tambien se puede pegar el header completo de
cookies ("auth_token=...; ct0=...") o el JSON de una extension como
Cookie-Editor; en ese caso no se pide `ct0`.

Para obtener las cookies de varias cuentas, abri cada una en un perfil
de navegador distinto (o en una ventana de incognito aparte) y cerra la
ventana **sin cerrar sesion**: cerrar sesion invalida el `auth_token`.

## Examples

``` r
if (FALSE) { # \dontrun{
setupAccountsX()
} # }
```
