# Asignar, cambiar o quitar el proxy de cuentas del pool

Cambia el proxy de cuentas ya cargadas sin tocar su sesion (no hace
falta volver a pegar las cookies). Conviene que cada cuenta salga
siempre por la misma IP: usa proxies "sticky" (IP fija), no rotativos.

## Usage

``` r
setProxyX(accounts, proxy, validate = TRUE)
```

## Arguments

- accounts:

  Nombres de las cuentas.

- proxy:

  Direccion del proxy: "http://usuario:clave@host:puerto",
  "usuario:clave@host:puerto" o "socks5://host:puerto". Chromium no
  admite SOCKS5 con usuario y clave: para proxies autenticados usa la
  direccion HTTP del proveedor. NULL (o "") quita el proxy y la cuenta
  pasa a usar el global (`options(TweetScraperR.proxy = ...)`) o tu
  conexion directa.

- validate:

  Logico. Si TRUE (por defecto) valida cada cuenta a traves del proxy
  nuevo con
  [`checkAccountsX()`](https://agusnieto77.github.io/TweetScraperR/reference/checkAccountsX.md),
  lo que confirma que el proxy anda.

## Value

Invisiblemente, el resultado de
[`checkAccountsX()`](https://agusnieto77.github.io/TweetScraperR/reference/checkAccountsX.md)
si `validate` es TRUE, o los nombres de las cuentas si no.

## Examples

``` r
if (FALSE) { # \dontrun{
setProxyX("cuenta2", "http://usuario:clave@gate.proveedor.com:10000")
setProxyX("cuenta2", NULL)   # quitarlo
} # }
```
