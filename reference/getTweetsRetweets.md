# Get Users Retweets with Data

[![\[Experimental\]](https://lifecycle.r-lib.org/articles/figures/lifecycle-experimental.svg)](https://lifecycle.r-lib.org/articles/stages.html#experimental)

**Obsoleta**: preféri getTweetsRetweetsAPI(), basada en la API de X
(datos del JSON, mas robusta).

Esta función recupera los retweets a un tweet específico en Twitter
(ahora X), incluyendo datos como el user name, name y URL. Utiliza web
scraping para acceder a la página del tweet, iniciar sesión con las
credenciales proporcionadas, y recolectar la información de los retweets
al tweet.

El proceso incluye:

1.  Iniciar sesión en Twitter usando las credenciales proporcionadas (si
    open=TRUE).

2.  Navegar a la URL del tweet especificado con "/retweets" para ver los
    retweets.

3.  Extraer la información de los retweets mediante scraping.

4.  Continuar scrolling y recolectando datos hasta alcanzar el número
    deseado o no encontrar nuevas citas.

La función guarda los datos recolectados en un archivo RDS en el
directorio especificado si el parámetro 'save' es TRUE, y los devuelve
como un data frame.

## Usage

``` r
getTweetsRetweets(
  url = "https://x.com/tipsder/status/1672311054922293254",
  n_users = 100,
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

  URL del tweet del cual se quieren obtener los retweets. Por defecto es
  "https://x.com/tipsder/status/1672311054922293254".

- n_users:

  El número máximo de users a recuperar. Por defecto es 100.

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

Un data frame que contiene información sobre los users que rt el tweet
especificado, incluyendo usuario, URL y fecha de captura.

## Note

Esta función utiliza web scraping y puede ser sensible a cambios en la
estructura de la página de Twitter.

## References

Puedes encontrar más información sobre el paquete TweetScraperR en:
<https://github.com/agusnieto77/TweetScraperR>

## Examples

``` r
if (FALSE) { # \dontrun{
getTweetsRetweets(url = "https://x.com/tipsder/status/1672311054922293254", n_users = 20)

# Sin guardar los resultados
getTweetsRetweets(
  url = "https://x.com/tipsder/status/1672311054922293254",
  n_users = 20,
  save = FALSE
)

# Sin abrir una nueva sesión de login
getTweetsRetweets(
  url = "https://x.com/tipsder/status/1672311054922293254",
  n_users = 20,
  open = TRUE
)
} # }
```
