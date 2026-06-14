# Close Timeline Session

[![\[Experimental\]](https://lifecycle.r-lib.org/articles/figures/lifecycle-experimental.svg)](https://lifecycle.r-lib.org/articles/stages.html#experimental)

**Obsoleta**: el login automatizado por navegador ya no funciona porque
X lo bloquea por fingerprint. Usá `importSessionX(auth_token, ct0)` para
cargar tu sesión desde el navegador.

Esta función cierra la sesión de la línea de tiempo de Twitter
previamente abierta con la función
[`openTimeline()`](https://agusnieto77.github.io/TweetScraperR/reference/openTimeline.md).
Intenta cerrar la sesión del navegador y elimina el objeto 'timeline'
del entorno global.

## Usage

``` r
closeTimeline()
```

## Value

No devuelve ningún valor, pero imprime mensajes en la consola sobre el
resultado de la operación.

## Details

La función realiza las siguientes acciones:

1.  Intenta cerrar la sesión del navegador asociada al objeto
    'timeline'.

2.  Espera un segundo para asegurar que la sesión se cierre
    correctamente.

3.  Elimina el objeto 'timeline' del entorno global.

4.  Muestra un mensaje de éxito si todas las operaciones se realizan
    correctamente.

Si ocurre algún error durante el proceso, se captura y se muestra un
mensaje de error.

## Note

Esta función asume que existe un objeto 'timeline' en el entorno global,
creado previamente por la función
[`openTimeline()`](https://agusnieto77.github.io/TweetScraperR/reference/openTimeline.md).
Si el objeto no existe, se producirá un error.

## See also

[`openTimeline`](https://agusnieto77.github.io/TweetScraperR/reference/openTimeline.md)
para abrir una línea de tiempo de Twitter.

## Examples

``` r
if (FALSE) { # \dontrun{
# Primero, abrir una línea de tiempo
openTimeline("rstatstweet")

# Luego, cerrar la línea de tiempo
closeTimeline()
} # }
```
