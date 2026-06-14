# Get Live Tweet by Search II

[![\[Experimental\]](https://lifecycle.r-lib.org/articles/figures/lifecycle-experimental.svg)](https://lifecycle.r-lib.org/articles/stages.html#experimental)

**Obsoleta**: preférí getTweetsSearchAPI(), basada en la API de X (datos
del JSON, mas robusta).

Esta función recupera tweets basados en una consulta de búsqueda en
tiempo real en Twitter. Utiliza autenticación en Twitter mediante el
nombre de usuario y la contraseña proporcionados, o los valores
predeterminados de las variables de entorno del sistema. Versión
optimizada con mejor manejo de errores, procesamiento vectorizado y
gestión eficiente de memoria. Optimización realizada con asistencia de
Claude Sonnet 4 (Anthropic).

## Usage

``` r
getTweetsSearchStreaming2(
  search = "#RStats",
  n_tweets = 100,
  sleep = 15,
  xuser = Sys.getenv("TWITTER_USER", Sys.getenv("USER")),
  xpass = Sys.getenv("TWITTER_PASS", Sys.getenv("PASS")),
  dir = getwd(),
  save = TRUE,
  max_login_attempts = 3,
  max_collect_attempts = 5,
  backoff_factor = 1.5,
  verbose = TRUE
)
```

## Arguments

- search:

  La consulta de búsqueda para recuperar tweets. Por defecto es
  "#RStats".

- n_tweets:

  El número máximo de tweets a recuperar. Por defecto es 100.

- sleep:

  Tiempo de espera para la carga de tweets. Por defecto este valor es de
  15 segundos.

- xuser:

  Nombre de usuario de Twitter para autenticación. Por defecto es el
  valor de la variable de entorno TWITTER_USER (o USER si no está
  definida).

- xpass:

  Contraseña de Twitter para autenticación. Por defecto es el valor de
  la variable de entorno TWITTER_PASS (o PASS si no está definida).

- dir:

  Directorio para guardar el archivo RDS con las URLs recolectadas.

- save:

  Lógico. Indica si se debe guardar el resultado en un archivo RDS (por
  defecto TRUE).

- max_login_attempts:

  Número máximo de intentos de login (por defecto 3).

- max_collect_attempts:

  Número máximo de intentos consecutivos sin tweets nuevos (por defecto
  5).

- backoff_factor:

  Factor de backoff exponencial para reintentos (por defecto 1.5).

- verbose:

  Lógico. Mostrar mensajes detallados (por defecto TRUE).

## Value

Un tibble que contiene los tweets recuperados con información completa.

## References

Puedes encontrar más información sobre el paquete TweetScrapeR en:
<https://github.com/agusnieto77/TweetScraperR>

## Examples

``` r
if (FALSE) { # \dontrun{
getTweetsSearchStreaming2(search = "#RStats", n_tweets = 200)

# Sin guardar los resultados
getTweetsSearchStreaming2(search = "#RStats", n_tweets = 200, save = FALSE)

# Con configuración personalizada
getTweetsSearchStreaming2(
  search = "#datascience",
  n_tweets = 500,
  sleep = 10,
  max_collect_attempts = 8,
  verbose = FALSE
)
} # }
```
