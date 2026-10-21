# Importar una sesion de X/Twitter desde las cookies de tu navegador

Como X bloquea el login automatizado (detecta el navegador de Playwright
por fingerprint), la via robusta es: logueate a mano en tu navegador
normal y pasale a esta funcion las cookies `auth_token` y `ct0` de tu
sesion (las encontras en DevTools -\> Application/Almacenamiento -\>
Cookies -\> x.com). La sesion queda guardada en el pool de cuentas y
todas las funciones de scraping la reusan sin volver a loguearse.

## Usage

``` r
importSessionX(
  auth_token,
  ct0,
  account = "default",
  proxy = NULL,
  cookies = NULL
)
```

## Arguments

- auth_token:

  Valor de la cookie `auth_token` de x.com.

- ct0:

  Valor de la cookie `ct0` de x.com.

- account:

  Nombre local de la cuenta en el pool. Por defecto "default".
  Reimportar con el mismo nombre renueva la sesion y reactiva la cuenta,
  conservando su proxy y estadisticas.

- proxy:

  Proxy opcional de esta cuenta ("http://host:puerto",
  "usuario:clave@host:puerto" o "socks5://host:puerto"). Tiene prioridad
  sobre el proxy global `options(TweetScraperR.proxy = ...)`.

- cookies:

  Alternativa a `auth_token`/`ct0`: el header de cookies
  ("auth_token=...; ct0=...") o el JSON exportado por una extension de
  cookies (p. ej. Cookie-Editor).

## Value

Invisiblemente, el nombre de la cuenta.

## Details

Importando varias cuentas (con distintos `account`) se arma un **pool**:
cuando una cuenta agota el cupo de un endpoint de X (p. ej. 50 busquedas
cada 15 minutos), la recoleccion sigue con otra sin cortarse. Ver
[`accountsX()`](https://agusnieto77.github.io/TweetScraperR/reference/accountsX.md).

## Examples

``` r
if (FALSE) { # \dontrun{
importSessionX(auth_token = "...", ct0 = "...")
importSessionX(cookies = "auth_token=...; ct0=...", account = "cuenta2",
               proxy = "http://usuario:clave@host:8080")
} # }
```
