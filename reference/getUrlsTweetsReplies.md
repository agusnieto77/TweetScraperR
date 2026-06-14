# Get Tweets URLs Replies

[![\[Experimental\]](https://lifecycle.r-lib.org/articles/figures/lifecycle-experimental.svg)](https://lifecycle.r-lib.org/articles/stages.html#experimental)

**Obsoleta**: preférí getTweetsRepliesAPI(), basada en la API de X
(datos del JSON, mas robusta).

Esta función recupera las URLs de las respuestas a un tweet específico
en Twitter (ahora X). Utiliza web scraping para acceder a la página del
tweet, iniciar sesión con las credenciales proporcionadas, y recolectar
las URLs de las respuestas al tweet.

El proceso incluye:

1.  Iniciar sesión en Twitter usando las credenciales proporcionadas.

2.  Navegar a la URL del tweet especificado.

3.  Extraer las URLs de las respuestas mediante scraping.

4.  Continuar scrolling y recolectando URLs hasta alcanzar el número
    deseado o no encontrar nuevas URLs.

La función guarda las URLs recolectadas en un archivo RDS en el
directorio especificado si el parámetro 'save' es TRUE, y las devuelve
como un vector de cadenas.

## Usage

``` r
getUrlsTweetsReplies(
  url = "https://x.com/Picanumeros/status/1610715405705789442",
  n_urls = 100,
  xuser = Sys.getenv("TWITTER_USER", Sys.getenv("USER")),
  xpass = Sys.getenv("TWITTER_PASS", Sys.getenv("PASS")),
  view = FALSE,
  dir = getwd(),
  save = TRUE
)
```

## Arguments

- url:

  URL del tweet del cual se quieren obtener las respuestas. Por defecto
  es "https://x.com/Picanumeros/status/1610715405705789442".

- n_urls:

  El número máximo de URLs de respuestas a recuperar. Por defecto es
  100.

- xuser:

  Nombre de usuario de Twitter para autenticación. Por defecto es el
  valor de la variable de entorno TWITTER_USER y, si no está definida,
  el de la variable de entorno del sistema USER.

- xpass:

  Contraseña de Twitter para autenticación. Por defecto es el valor de
  la variable de entorno TWITTER_PASS y, si no está definida, el de la
  variable de entorno del sistema PASS.

- view:

  Ver el navegador. Por defecto es FALSE.

- dir:

  Directorio donde se guardará el archivo RDS con las URLs recolectadas.
  Por defecto es el directorio de trabajo actual.

- save:

  Lógico. Indica si se debe guardar el resultado en un archivo RDS (por
  defecto TRUE).

## Value

Un vector que contiene las URLs de las respuestas al tweet especificado.

## Note

Esta función utiliza web scraping y puede ser sensible a cambios en la
estructura de la página de Twitter.

## References

Puedes encontrar más información sobre el paquete TweetScraperR en:
<https://github.com/agusnieto77/TweetScraperR>

## Examples

``` r
if (FALSE) { # \dontrun{
getUrlsTweetsReplies(url = "https://x.com/Picanumeros/status/1610715405705789442", n_urls = 130)

# Sin guardar los resultados
getUrlsTweetsReplies(
  url = "https://x.com/Picanumeros/status/1610715405705789442",
  n_urls = 130,
  save = FALSE
)
} # }
```
