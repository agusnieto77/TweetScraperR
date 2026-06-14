# Open Twitter Login Page

[![\[Experimental\]](https://lifecycle.r-lib.org/articles/figures/lifecycle-experimental.svg)](https://lifecycle.r-lib.org/articles/stages.html#experimental)

**Obsoleta**: el login automatizado por navegador ya no funciona porque
X lo bloquea por fingerprint. Usá `importSessionX(auth_token, ct0)` para
cargar tu sesión desde el navegador.

Esta función permite abrir la página de inicio de sesión de Twitter en
un navegador web y guardar la instancia HTML en el entorno global. Es
útil para iniciar el proceso de autenticación antes de realizar la
recolección de datos de Twitter.

## Usage

``` r
openTwitter(view = TRUE)
```

## Arguments

- view:

  Logical. If TRUE (default), returns a view of the HTML instance. If
  FALSE, returns the HTML instance itself.

## Value

Si `view` es TRUE, devuelve una vista de la instancia HTML de la página
de inicio de sesión de Twitter. Si `view` es FALSE, devuelve la
instancia HTML directamente. En ambos casos, la información de la sesión
se guarda en la variable global `twitter` para su uso posterior.

## Examples

``` r
if (FALSE) { # \dontrun{
# Para obtener la vista (comportamiento predeterminado)
openTwitter()

# Para obtener el objeto twitter sin la vista
twitter <- openTwitter(view = FALSE)
} # }
```
