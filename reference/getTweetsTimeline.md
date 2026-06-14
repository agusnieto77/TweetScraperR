# Get Tweets from User Timeline

[![\[Experimental\]](https://lifecycle.r-lib.org/articles/figures/lifecycle-experimental.svg)](https://lifecycle.r-lib.org/articles/stages.html#experimental)

**Obsoleta**: preférí getUserTweetsAPI(), basada en la API de X (datos
del JSON, mas robusta).

Esta función recupera tweets del timeline de unx usuarix especificadx en
Twitter. La función inicia sesión en Twitter utilizando las credenciales
proporcionadas, navega al perfil de le usuarix especificadx, y recopila
hasta `n_tweets` tweets. El proceso de recolección se detiene si se
alcanza el número máximo de tweets especificado o después de alcanzar
los 600 tweets con el desplazamiento (scroll).

## Usage

``` r
getTweetsTimeline(
  username = "rstatstweet",
  n_tweets = 100,
  view = FALSE,
  open = FALSE,
  xuser = Sys.getenv("TWITTER_USER", Sys.getenv("USER")),
  xpass = Sys.getenv("TWITTER_PASS", Sys.getenv("PASS")),
  mailx = NULL,
  dir = getwd(),
  save = TRUE
)
```

## Arguments

- username:

  El nombre de usuarix de Twitter del cual quieres obtener el timeline.

- n_tweets:

  El número máximo de tweets a obtener. Por defecto es 100.

- view:

  Mostrar una vista en vivo de Twitter/X TRUE o FALSE

- open:

  Indica si se debe realizar el proceso de autenticación (por defecto
  FALSE)

- xuser:

  Nombre de usuarix de Twitter para autenticación. Por defecto es el
  valor de la variable de entorno TWITTER_USER y, si no está definida,
  el de la variable de entorno del sistema USER.

- xpass:

  Contraseña de Twitter para autenticación. Por defecto es el valor de
  la variable de entorno TWITTER_PASS y, si no está definida, el de la
  variable de entorno del sistema PASS.

- mailx:

  Dirección de e-mail para la autenticación. Tiene que ser la misma que
  la usada en Twitter/X.

- dir:

  El directorio donde se guardará el archivo de salida. Por defecto es
  el directorio de trabajo actual.

- save:

  Lógico. Indica si se debe guardar el resultado en un archivo RDS (por
  defecto TRUE).

## Value

Un tibble que contiene los tweets obtenidos.

## References

Puedes encontrar más información sobre el paquete TweetScrapeR en:
<https://github.com/agusnieto77/TweetScraperR>

## Examples

``` r
if (FALSE) { # \dontrun{
getTweetsTimeline(username = "rstatstweet", n_tweets = 200)

# Con autenticación
getTweetsTimeline(username = "rstatstweet", n_tweets = 200, open = TRUE)

# Sin guardar los resultados
getTweetsTimeline(username = "rstatstweet", n_tweets = 200, save = FALSE)
} # }
```
