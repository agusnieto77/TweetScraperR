# Get Historical Tweets Iteratively

[![\[Experimental\]](https://lifecycle.r-lib.org/articles/figures/lifecycle-experimental.svg)](https://lifecycle.r-lib.org/articles/stages.html#experimental)

**Obsoleta**: preferí getTweetsSearchAPI(), basada en la API de X (datos
del JSON, mas robusta).

Esta función realiza búsquedas históricas de tweets de forma iterativa,
permitiendo recolectar tweets en intervalos de tiempo específicos.

## Usage

``` r
getTweetsHistoricalSearchFor(
  iterations,
  search,
  n_tweets,
  since,
  until,
  interval_unit = "days",
  live = TRUE,
  xuser = Sys.getenv("TWITTER_USER", Sys.getenv("USER")),
  xpass = Sys.getenv("TWITTER_PASS", Sys.getenv("PASS")),
  dir = getwd(),
  system = "windows",
  kill_system = FALSE,
  sleep_time = 5 * 60
)
```

## Arguments

- iterations:

  Número de iteraciones a realizar.

- search:

  Término de búsqueda para los tweets.

- n_tweets:

  Número de tweets a recolectar por iteración.

- since:

  Fecha y hora de inicio para la búsqueda (formato:
  "YYYY-MM-DD_HH:MM:SS_UTC").

- until:

  Número de unidades de tiempo a avanzar en cada iteración.

- interval_unit:

  Unidad de tiempo para el intervalo ("days", "hours", o "minutes").

- live:

  Booleano que indica si se debe realizar una búsqueda en vivo (por
  defecto: TRUE).

- xuser:

  Nombre de usuario de Twitter para autenticación (por defecto: variable
  de entorno TWITTER_USER o, en su defecto, USER).

- xpass:

  Contraseña de Twitter para autenticación (por defecto: variable de
  entorno TWITTER_PASS o, en su defecto, PASS).

- dir:

  Directorio para guardar los tweets recolectados (por defecto:
  directorio de trabajo actual).

- system:

  Sistema operativo ("windows", "unix", o "mac"). Se mantiene por
  compatibilidad; el cierre del navegador ya no depende del sistema
  operativo.

- kill_system:

  Booleano que indica si se debe cerrar el navegador (solo las sesiones
  propias del paquete) después de cada iteración (por defecto: FALSE).

- sleep_time:

  Tiempo de espera entre iteraciones en segundos (por defecto: 300
  segundos).

## Value

No devuelve un valor explícito, pero guarda los tweets recolectados en
el directorio especificado.

## Details

La función realiza las siguientes operaciones:

1.  Valida el formato de la fecha y hora de inicio.

2.  Crea el directorio de destino si no existe.

3.  Ejecuta búsquedas históricas de tweets de forma iterativa.

4.  Calcula la fecha y hora de finalización para cada iteración
    basándose en el intervalo especificado.

5.  Cierra el navegador después de cada iteración si kill_system es
    TRUE.

6.  Espera un tiempo especificado entre iteraciones.

## Examples

``` r
if (FALSE) { # \dontrun{
getTweetsHistoricalSearchFor(
  iterations = 5,
  search = "cambio climático",
  n_tweets = 1000,
  since = "2023-01-01_15:55:00_UTC",
  until = 7,
  interval_unit = "days",
  live = TRUE,
  dir = "./datos/tweets",
  system = "windows",
  kill_system = FALSE,
  sleep_time = 300
)
} # }
```
