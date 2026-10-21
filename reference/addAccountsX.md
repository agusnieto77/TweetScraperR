# Agregar varias cuentas al pool de una vez

Agregar varias cuentas al pool de una vez

## Usage

``` r
addAccountsX(accounts)
```

## Arguments

- accounts:

  Un data frame, o la ruta a un CSV, con las columnas `account`,
  `auth_token` y `ct0`, y opcionalmente `proxy`. El separador del CSV
  (`,`, `;` o tabulador) se detecta solo, asi que sirven los CSV
  guardados por Excel en configuracion regional en espanol.

## Value

Invisiblemente, los nombres de las cuentas agregadas.

## Examples

``` r
if (FALSE) { # \dontrun{
# cuentas.csv: account,auth_token,ct0,proxy
addAccountsX("cuentas.csv")
accountsX()
} # }
```
