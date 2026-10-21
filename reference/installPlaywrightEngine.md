# Instalar el motor Node/Playwright (npm install + browsers)

Ejecuta `npm install` dentro de inst/node, lo que instala Playwright, el
plugin stealth y descarga el navegador Chromium. Hay que correrlo una
vez por maquina antes de usar las funciones de scraping.

## Usage

``` r
installPlaywrightEngine(npm = "npm")
```

## Arguments

- npm:

  Ruta al binario de npm (por defecto "npm" del PATH).

## Value

Invisiblemente, el codigo de salida de npm.
