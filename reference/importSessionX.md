# Importar una sesion de X/Twitter desde las cookies de tu navegador

Como X bloquea el login automatizado (detecta el navegador de Playwright
por fingerprint), la via robusta es: logueate a mano en tu navegador
normal y pasale a esta funcion las cookies `auth_token` y `ct0` de tu
sesion (las encontras en DevTools -\> Application/Almacenamiento -\>
Cookies -\> x.com). La sesion queda guardada (storageState) y todas las
funciones de scraping la reusan sin volver a loguearse.

## Usage

``` r
importSessionX(auth_token, ct0, state = .pw_state_path())
```

## Arguments

- auth_token:

  Valor de la cookie `auth_token` de x.com.

- ct0:

  Valor de la cookie `ct0` de x.com.

- state:

  Ruta donde guardar la sesion. Por defecto la ubicacion estandar del
  paquete, que las demas funciones leen automaticamente.

## Value

Invisiblemente, la ruta del archivo de sesion.
