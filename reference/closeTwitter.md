# Close Twitter Session

[![\[Experimental\]](https://lifecycle.r-lib.org/articles/figures/lifecycle-experimental.svg)](https://lifecycle.r-lib.org/articles/stages.html#experimental)

**Obsoleta**: el login automatizado por navegador ya no funciona porque
X lo bloquea por fingerprint. Usá `importSessionX(auth_token, ct0)` para
cargar tu sesión desde el navegador.

Esta función cierra la sesión activa de Twitter y elimina la variable
global `twitter` del entorno. Es útil para liberar recursos y limpiar el
entorno después de haber realizado operaciones de recolección de datos
en Twitter.

Usage closeTwitter()

## Usage

``` r
closeTwitter()
```

## Value

Esta función no devuelve valores. Imprime un mensaje de confirmación al
cerrar la sesión y elimina la variable `twitter` del entorno global.

## Examples

``` r
if (FALSE) { # \dontrun{
closeTwitter()
} # }
```
