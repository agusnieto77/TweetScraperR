# Comprobar que el motor Node/Playwright esta instalado y operativo

Ejecuta el comando `doctor` del motor y devuelve la informacion de
versiones.

## Usage

``` r
checkPlaywrightEngine()
```

## Value

Una lista con `ok`, version de Playwright, version de Node y ruta de
Chromium. Lanza un error si el motor no responde.
