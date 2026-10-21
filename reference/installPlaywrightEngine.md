# Instalar el motor Node/Playwright (npm install + navegador)

Copia el motor (`inst/node`) a la carpeta de cache del usuario
(`tools::R_user_dir("TweetScraperR", "cache")`) y ejecuta alli
`npm install`, que instala 'Playwright', 'playwright-extra' y su plugin
'stealth' (ajustes de compatibilidad para que el navegador automatizado
se presente como un 'Chromium' de escritorio estandar) y descarga el
navegador 'Chromium'. Nada de esto ocurre al instalar el paquete: hay
que llamar a esta funcion explicitamente, una vez por maquina, antes de
usar las funciones de recoleccion. Requiere 'Node.js' (\>= 18) con 'npm'
y conexion a internet.

## Usage

``` r
installPlaywrightEngine(npm = "npm")
```

## Arguments

- npm:

  Ruta al binario de npm (por defecto "npm" del PATH).

## Value

Invisiblemente, el codigo de salida de npm (0 si todo salio bien).

## Examples

``` r
if (FALSE) { # \dontrun{
installPlaywrightEngine()
} # }
```
