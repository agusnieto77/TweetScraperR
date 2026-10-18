# Instalar el motor Node/Playwright (npm install + browsers)

Copia el motor (tsr-engine.js, package.json) desde inst/node hacia un
cache persistente del usuario (tools::R_user_dir de TweetScraperR) y
ejecuta `npm install` alli, lo que instala Playwright, el plugin stealth
y descarga el navegador Chromium. El cache sobrevive a las
reinstalaciones del paquete, por lo que solo hay que correrlo una vez
por maquina.

## Usage

``` r
installPlaywrightEngine(npm = "npm")
```

## Arguments

- npm:

  Ruta al binario de npm (por defecto "npm" del PATH).

## Value

Invisiblemente, el codigo de salida de npm.
