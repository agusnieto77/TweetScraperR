# Iniciar sesion en X/Twitter con Playwright y guardar la sesion

Abre un navegador Chromium con tecnicas anti-deteccion (stealth),
realiza el login en X/Twitter con el flujo del modal actual y guarda la
sesion autenticada (cookies + storage) como una cuenta del pool. Las
demas funciones del paquete reusan esa sesion sin volver a loguearse, lo
que evita el rate-limit de X.

## Usage

``` r
loginX(
  xuser = Sys.getenv("TWITTER_USER", Sys.getenv("USER")),
  xpass = Sys.getenv("TWITTER_PASS", Sys.getenv("PASS")),
  email = Sys.getenv("TWITTER_EMAIL", ""),
  headless = TRUE,
  account = "default",
  proxy = NULL
)
```

## Arguments

- xuser:

  Usuario de X/Twitter. Por defecto la variable de entorno TWITTER_USER
  (con fallback a USER).

- xpass:

  Contrasena de X/Twitter. Por defecto la variable de entorno
  TWITTER_PASS (con fallback a PASS).

- email:

  Correo para el paso de verificacion de identidad, si X lo pide. Por
  defecto la variable de entorno TWITTER_EMAIL.

- headless:

  Logico. Si TRUE (por defecto) corre el navegador sin interfaz. Pone
  FALSE para ver/depurar el login.

- account:

  Nombre local de la cuenta en el pool. Por defecto "default".

- proxy:

  Proxy opcional para rutear el trafico (util si X bloquea tu IP).
  Acepta un string "http://host:puerto" o "usuario:clave@host:puerto", o
  una lista list(server=, username=, password=). Si es un string queda
  guardado como proxy de la cuenta.

## Value

Invisiblemente, el nombre de la cuenta. Lanza un error si el login falla
o si X limita el intento.
