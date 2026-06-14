# Get Iterative Tweets in Streaming II

[![\[Experimental\]](https://lifecycle.r-lib.org/articles/figures/lifecycle-experimental.svg)](https://lifecycle.r-lib.org/articles/stages.html#experimental)

**Obsoleta**: preferí getTweetsSearchAPI(), basada en la API de X (datos
del JSON, mas robusta).

Esta función recolecta tweets de forma iterativa utilizando la función
optimizada getTweetsSearchStreaming2, con manejo robusto de errores,
seguimiento de progreso, unificación de datos y gestión eficiente de
recursos del sistema. Optimización realizada con asistencia de Claude
Sonnet 4 (Anthropic).

## Usage

``` r
getTweetsSearchStreamingFor2(
  iterations,
  search,
  n_tweets,
  sleep = 15,
  xuser = Sys.getenv("TWITTER_USER", Sys.getenv("USER")),
  xpass = Sys.getenv("TWITTER_PASS", Sys.getenv("PASS")),
  dir = getwd(),
  system = "unix",
  kill_system = FALSE,
  sleep_time = 300,
  max_retries = 3,
  backoff_factor = 2,
  consolidate_data = TRUE,
  cleanup_individual = FALSE,
  verbose = TRUE,
  progress_file = NULL,
  resume_from = 1
)
```

## Arguments

- iterations:

  Número de iteraciones a realizar

- search:

  Término de búsqueda para los tweets

- n_tweets:

  Número de tweets a recolectar en cada iteración

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

  Directorio donde se guardarán los tweets

- system:

  Sistema operativo ('windows', 'unix', 'macOS'). Se mantiene por
  compatibilidad; el cierre del navegador ya no depende del sistema
  operativo.

- kill_system:

  Booleano que indica si se debe cerrar el navegador (solo las sesiones
  propias del paquete) después de cada iteración (por defecto: FALSE)

- sleep_time:

  Tiempo de espera entre iteraciones en segundos. Por defecto este valor
  es de 300 segundos.

- max_retries:

  Número máximo de reintentos por iteración (por defecto: 3)

- backoff_factor:

  Factor de backoff exponencial entre reintentos (por defecto: 2)

- consolidate_data:

  Booleano para unificar todos los datos en un único archivo al final
  (por defecto: TRUE)

- cleanup_individual:

  Booleano para eliminar archivos individuales después de unificar (por
  defecto: FALSE)

- verbose:

  Booleano para mostrar mensajes detallados (por defecto: TRUE)

- progress_file:

  Archivo para guardar el progreso de la recolección (por defecto:
  NULL). Si el archivo ya existe, la recolección se reanuda
  automáticamente desde la iteración siguiente a la última completada,
  reutilizando el directorio de salida de la sesión anterior.

- resume_from:

  Iteración desde la cual resumir la recolección (por defecto: 1). Si se
  indica explícitamente, tiene prioridad sobre el progreso guardado en
  progress_file.

## Value

Lista con estadísticas de la recolección y ruta del archivo unificado
(si aplica)

## References

Puedes encontrar más información sobre el paquete TweetScrapeR en:
<https://github.com/agusnieto77/TweetScraperR>

Función optimizada con asistencia de Claude Sonnet 4 (Anthropic, 2025).
Optimizaciones incluyen: manejo robusto de errores, seguimiento de
progreso, unificación de datos, y gestión eficiente de recursos del
sistema.

## Examples

``` r
if (FALSE) { # \dontrun{
# Uso básico
result <- getTweetsSearchStreamingFor2(
  iterations = 5,
  search = "Milei",
  n_tweets = 100,
  dir = "./data/tweets"
)

# Uso avanzado con opciones de recuperación
result <- getTweetsSearchStreamingFor2(
  iterations = 10,
  search = "#datascience",
  n_tweets = 200,
  dir = "./data/tweets",
  system = "unix",
  kill_system = TRUE,
  sleep_time = 600,
  max_retries = 5,
  consolidate_data = TRUE,
  cleanup_individual = TRUE,
  progress_file = "./progress.rds",
  verbose = TRUE
)

# Resumir recolección desde iteración específica
result <- getTweetsSearchStreamingFor2(
  iterations = 10,
  search = "#RStats",
  n_tweets = 150,
  dir = "./data/tweets",
  resume_from = 6,
  progress_file = "./progress.rds"
)
} # }
```
