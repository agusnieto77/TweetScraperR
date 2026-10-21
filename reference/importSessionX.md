# Importar una sesion de X/Twitter desde las cookies de tu navegador

La via recomendada para autenticarse es iniciar sesion a mano en tu
navegador habitual y pasarle a esta funcion las cookies `auth_token` y
`ct0` de tu sesion (las encontras en DevTools -\>
Application/Almacenamiento -\> Cookies -\> x.com). La sesion queda
guardada en el pool de cuentas (en
`tools::R_user_dir("TweetScraperR", "data")`) y todas las funciones de
recoleccion la reusan sin volver a loguearse.

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

Importando varias cuentas propias (con distintos `account`) se arma un
**pool** que distribuye la carga de trabajo entre ellas: cada cuenta
respeta los limites de uso que X informa por endpoint (p. ej. 50
busquedas cada 15 minutos) y, cuando una llega a su limite, queda en
pausa hasta que X lo renueve mientras la recoleccion continua con otra
cuenta disponible. Ver
[`accountsX()`](https://agusnieto77.github.io/TweetScraperR/reference/accountsX.md).

## Examples

``` r
if (FALSE) { # \dontrun{
importSessionX(auth_token = "...", ct0 = "...")
importSessionX(cookies = "auth_token=...; ct0=...", account = "cuenta2",
               proxy = "http://usuario:clave@host:8080")
} # }
```
