# Get Tweets Cites with Data

[![\[Experimental\]](https://lifecycle.r-lib.org/articles/figures/lifecycle-experimental.svg)](https://lifecycle.r-lib.org/articles/stages.html#experimental)

**Obsoleta**: preféri getTweetsSearchAPI(), basada en la API de X (datos
del JSON, mas robusta).

Esta función recupera las citas a un tweet específico en Twitter (ahora
X), incluyendo datos como el texto del tweet, usuario, fecha, y URL.
Utiliza web scraping para acceder a la página del tweet, iniciar sesión
con las credenciales proporcionadas, y recolectar la información de las
citas al tweet.

El proceso incluye:

1.  Iniciar sesión en Twitter usando las credenciales proporcionadas (si
    open=TRUE).

2.  Navegar a la URL del tweet especificado con "/quotes" para ver las
    citas.

3.  Extraer la información de las citas mediante scraping.

4.  Continuar scrolling y recolectando datos hasta alcanzar el número
    deseado o no encontrar nuevas citas.

La función guarda los datos recolectados en un archivo RDS en el
directorio especificado si el parámetro 'save' es TRUE, y los devuelve
como un data frame.

## Usage

``` r
getTweetsCites(
  url = "https://x.com/Picanumeros/status/1610715405705789442",
  n_tweets = 100,
  timeout = 2.5,
  xuser = Sys.getenv("TWITTER_USER", Sys.getenv("USER")),
  xpass = Sys.getenv("TWITTER_PASS", Sys.getenv("PASS")),
  view = FALSE,
  dir = getwd(),
  save = TRUE,
  open = FALSE
)
```

## Arguments

- url:

  URL del tweet del cual se quieren obtener las citas. Por defecto es
  "https://x.com/Picanumeros/status/1610715405705789442".

- n_tweets:

  El número máximo de tweets de citas a recuperar. Por defecto es 100.

- timeout:

  Tiempo de espera entre scrolls en segundos. Por defecto es 2.5.

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

  Directorio donde se guardará el archivo RDS con los datos
  recolectados. Por defecto es el directorio de trabajo actual.

- save:

  Lógico. Indica si se debe guardar el resultado en un archivo RDS (por
  defecto TRUE).

- open:

  Lógico. Indica si se debe abrir una nueva sesión de login en Twitter
  (por defecto FALSE).

## Value

Un data frame que contiene información sobre las citas al tweet
especificado, incluyendo usuario, texto, fecha, URL y fecha de captura.

## Note

Esta función utiliza web scraping y puede ser sensible a cambios en la
estructura de la página de Twitter.

## References

Puedes encontrar más información sobre el paquete TweetScraperR en:
<https://github.com/agusnieto77/TweetScraperR>

## Examples

``` r
if (FALSE) { # \dontrun{
getTweetsCites(url = "https://x.com/Picanumeros/status/1610715405705789442", n_tweets = 130)

# Sin guardar los resultados
getTweetsCites(
  url = "https://x.com/Picanumeros/status/1610715405705789442",
  n_tweets = 130,
  save = FALSE
)

# Sin abrir una nueva sesión de login
getTweetsCites(
  url = "https://x.com/Picanumeros/status/1610715405705789442",
  n_tweets = 130,
  open = TRUE
)
} # }
```
