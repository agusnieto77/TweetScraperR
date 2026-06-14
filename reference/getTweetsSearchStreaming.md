# Get Live Tweet by Search

[![\[Experimental\]](https://lifecycle.r-lib.org/articles/figures/lifecycle-experimental.svg)](https://lifecycle.r-lib.org/articles/stages.html#experimental)

**Obsoleta**: preférí getTweetsSearchAPI(), basada en la API de X (datos
del JSON, mas robusta).

Esta función recupera tweets basados en una consulta de búsqueda en
tiempo real en Twitter. Utiliza autenticación en Twitter mediante el
nombre de usuario y la contraseña proporcionados, o los valores
predeterminados de las variables de entorno del sistema. Después de
autenticar al usuario, la función realiza la búsqueda especificada por
el parámetro `search` y recoge las URLs de los tweets que coinciden con
la consulta. El proceso de recolección de URLs se ejecuta en un bucle
que continúa hasta que se alcanza el número máximo de URLs especificado
por el parámetro `n_tweets` o hasta que se realizan varios intentos
consecutivos sin encontrar nuevas URLs, indicando que no hay más
resultados disponibles en ese momento. La función incorpora mecanismos
de manejo de errores y tiempos de espera para asegurar que las
conexiones y búsquedas se realicen de manera robusta y continua. Las
URLs de los tweets recolectados se almacenan en un vector y se guardan
en un archivo con formato `.rds` en el directorio especificado por el
parámetro `dir` si el parámetro `save` es TRUE. Este archivo se nombra
de manera única utilizando la consulta de búsqueda y la marca de tiempo
del momento en que se realiza la recolección, asegurando que no se
sobrescriban archivos anteriores.

## Usage

``` r
getTweetsSearchStreaming(
  search = "#RStats",
  timeout = 10,
  n_tweets = 100,
  sleep = 3,
  xuser = Sys.getenv("TWITTER_USER", Sys.getenv("USER")),
  xpass = Sys.getenv("TWITTER_PASS", Sys.getenv("PASS")),
  dir = getwd(),
  save = TRUE
)
```

## Arguments

- search:

  La consulta de búsqueda para recuperar tweets. Por defecto es
  "#RStats".

- timeout:

  Tiempo de espera.

- n_tweets:

  El número máximo de tweets a recuperar. Por defecto es 100.

- sleep:

  Tiempo de espera para la carga de tweets. Por defecto este valor es de
  3 segundos.

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

## Value

Un vector que contiene las URLs de tweets recuperadas.

## References

Puedes encontrar más información sobre el paquete TweetScrapeR en:
<https://github.com/agusnieto77/TweetScraperR>

## Examples

``` r
if (FALSE) { # \dontrun{
getTweetsSearchStreaming(search = "#RStats", n_tweets = 200)

# Sin guardar los resultados
getTweetsSearchStreaming(search = "#RStats", n_tweets = 200, save = FALSE)
} # }
```
