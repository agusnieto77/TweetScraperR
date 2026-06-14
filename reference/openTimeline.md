# Open Timeline User

[![\[Experimental\]](https://lifecycle.r-lib.org/articles/figures/lifecycle-experimental.svg)](https://lifecycle.r-lib.org/articles/stages.html#experimental)

**Obsoleta**: el login automatizado por navegador ya no funciona porque
X lo bloquea por fingerprint. Usá `importSessionX(auth_token, ct0)` para
cargar tu sesión desde el navegador.

Esta función abre la línea de tiempo de un usuario específico de Twitter
(X) y crea un objeto que contiene la información de la página. Intenta
abrir la página hasta tres veces en caso de error.

## Usage

``` r
openTimeline(username = "rstatstweet", view = TRUE)
```

## Arguments

- username:

  Character. El nombre de usuario de Twitter cuya línea de tiempo se
  desea abrir. Por defecto es "rstatstweet".

- view:

  Logical. Si es TRUE (por defecto), muestra la vista de la página web.
  Si es FALSE, solo crea el objeto sin mostrar la vista.

## Value

Si view es TRUE, devuelve la vista de la página web. Si view es FALSE,
devuelve un mensaje indicando que se ha creado el objeto "timeline". En
caso de error después de tres intentos, devuelve NULL.

## Details

La función utiliza
[`rvest::read_html_live()`](https://rvest.tidyverse.org/reference/read_html_live.html)
para leer la página web de la línea de tiempo del usuario especificado.
Crea un objeto global llamado "timeline" que contiene la información de
la página. Si ocurre un error al intentar abrir la página, la función
reintentará hasta tres veces antes de fallar.

## Note

Esta función requiere una conexión a Internet activa y puede estar
sujeta a las limitaciones de acceso impuestas por Twitter (X).

## Examples

``` r
if (FALSE) { # \dontrun{
# Abrir la línea de tiempo de un usuario específico y mostrar la vista
openTimeline("hadleywickham")

# Crear el objeto timeline sin mostrar la vista
openTimeline("rstudio", view = FALSE)
} # }
```
