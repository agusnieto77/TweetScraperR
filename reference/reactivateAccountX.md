# Reactivar cuentas desactivadas del pool

Una cuenta se desactiva cuando X rechaza su sesion o la limita. Si fue
un falso positivo (o ya se resolvio desde el navegador), se reactiva con
esta funcion. Si la sesion vencio, conviene reimportarla con
[`importSessionX()`](https://agusnieto77.github.io/TweetScraperR/reference/importSessionX.md).

## Usage

``` r
reactivateAccountX(accounts)
```

## Arguments

- accounts:

  Nombres de las cuentas a reactivar.

## Value

Invisiblemente, la cantidad de cuentas reactivadas.
