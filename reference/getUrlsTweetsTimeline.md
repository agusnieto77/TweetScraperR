# Get URLs of User Timeline Tweets

[![\[Experimental\]](https://lifecycle.r-lib.org/articles/figures/lifecycle-experimental.svg)](https://lifecycle.r-lib.org/articles/stages.html#experimental)

**Obsoleta**: preférí getUserTweetsAPI(), basada en la API de X (datos
del JSON, mas robusta).

Esta función recupera URLs de tweets del timeline de unx usuarix
especificadx en Twitter. Opcionalmente puede iniciar sesión en Twitter
utilizando las credenciales proporcionadas si open=TRUE, navega al
perfil del usuarix especificadx, y recopila hasta `n_urls` URLs de
tweets. El proceso de recolección se detiene si se alcanza el número
máximo de URLs especificado o después de realizar 600 capturas y se
detiene el desplazamiento (scroll).

## Usage

``` r
getUrlsTweetsTimeline(
  username = "rstatstweet",
  n_urls = 100,
  open = FALSE,
  xuser = Sys.getenv("TWITTER_USER", Sys.getenv("USER")),
  xpass = Sys.getenv("TWITTER_PASS", Sys.getenv("PASS")),
  max_retries = 3,
  dir = getwd(),
  save = TRUE
)
```

## Arguments

- username:

  El nombre de usuarix de Twitter del cual quieres obtener el timeline.
  Por defecto es "rstatstweet".

- n_urls:

  El número máximo de URLs de tweets a obtener. Por defecto es 100.

- open:

  Indica si se debe realizar el proceso de autenticación (por defecto
  FALSE).

- xuser:

  Nombre de usuarix de Twitter para autenticación. Por defecto es el
  valor de la variable de entorno TWITTER_USER (o, si no está definida,
  USER).

- xpass:

  Contraseña de Twitter para autenticación. Por defecto es el valor de
  la variable de entorno TWITTER_PASS (o, si no está definida, PASS).

- max_retries:

  número máximo de intentos de conexión. Por defecto es 3.

- dir:

  Directorio donde se guardará el archivo de salida. Por defecto es el
  directorio de trabajo actual.

- save:

  Lógico. Indica si se debe guardar el resultado en un archivo RDS (por
  defecto TRUE).

## Value

Un vector que contiene las URLs de tweets obtenidas.

## Examples

``` r
if (FALSE) { # \dontrun{
# Sin autenticación
getUrlsTweetsTimeline(username = "rstatstweet", n_urls = 200)

# Con autenticación
getUrlsTweetsTimeline(username = "rstatstweet", n_urls = 200, open = TRUE)

# Sin guardar los resultados
getUrlsTweetsTimeline(username = "rstatstweet", n_urls = 200, save = FALSE)
} # }
```
