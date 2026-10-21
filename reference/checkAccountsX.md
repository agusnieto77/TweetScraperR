# Validar las sesiones del pool de cuentas

Abre X con la sesion de cada cuenta y comprueba que siga autenticada,
registrando el @usuario real que hay detras (columna `usuario_x` de
[`accountsX()`](https://agusnieto77.github.io/TweetScraperR/reference/accountsX.md)).
Las cuentas con sesion vencida o bloqueada se desactivan; las validas se
reactivan. No consume cupo de los endpoints de recoleccion. Si dos
cuentas del pool resultan ser la misma cuenta de X (p. ej. la "default"
de versiones previas cargada de nuevo con otro nombre), se reescribe:
queda la agregada mas recientemente, con las pausas y estadisticas de
ambas.

## Usage

``` r
checkAccountsX(accounts = NULL)
```

## Arguments

- accounts:

  Nombres de las cuentas a validar. Por defecto, todas (incluidas las
  desactivadas).

## Value

Un tibble con una fila por cuenta y columnas cuenta, valida, usuario_x y
motivo (por que no es valida).

## Examples

``` r
if (FALSE) { # \dontrun{
importSessionX(cookies = Sys.getenv("X2_COOKIES"), account = "cuenta2")
checkAccountsX()
} # }
```
