# Get Historical Tweets from a Specific Search

[![\[Experimental\]](https://lifecycle.r-lib.org/articles/figures/lifecycle-experimental.svg)](https://lifecycle.r-lib.org/articles/stages.html#experimental)

**Obsoleta**: preférí getTweetsSearchAPI(), basada en la API de X (datos
del JSON, mas robusta).

Esta función permite recuperar tweets históricos de Twitter (ahora X)
que coinciden con una búsqueda específica. Puedes especificar términos
de búsqueda relevantes para tus necesidades de análisis, y la función
recuperará tweets antiguos que coincidan con esos criterios. Esto es
útil para investigaciones históricas, análisis de tendencias a lo largo
del tiempo y cualquier otro análisis que requiera acceso a datos
históricos de Twitter.

La función ahora incluye un proceso de autenticación automático y manejo
de errores mejorado.

## Usage

``` r
getTweetsHistoricalSearch(
  search = "R Project",
  timeout = 10,
  n_tweets = 100,
  since = "2018-10-26",
  until = "2023-10-30",
  live = TRUE,
  xuser = Sys.getenv("TWITTER_USER", Sys.getenv("USER")),
  xpass = Sys.getenv("TWITTER_PASS", Sys.getenv("PASS")),
  dir = getwd(),
  save = TRUE
)
```

## Arguments

- search:

  Término de búsqueda para los tweets deseados. Por defecto es "R
  Project".

- timeout:

  Tiempo de espera entre solicitudes en segundos. Por defecto es 10.

- n_tweets:

  El número máximo de tweets a recuperar. Por defecto es 100.

- since:

  Fecha de inicio para la búsqueda de tweets (en formato "YYYY-MM-DD").
  Por defecto es "2018-10-26".

- until:

  Fecha de fin para la búsqueda de tweets (en formato "YYYY-MM-DD"). Por
  defecto es "2023-10-30".

- live:

  Booleano que indica si se deben buscar tweets más recientes (TRUE) o
  destacados (FALSE). Por defecto es TRUE.

- xuser:

  Nombre de usuarix de Twitter para autenticación. Por defecto es el
  valor de la variable de entorno TWITTER_USER (o, en su defecto, USER).

- xpass:

  Contraseña de Twitter para autenticación. Por defecto es el valor de
  la variable de entorno TWITTER_PASS (o, en su defecto, PASS).

- dir:

  Directorio para guardar el archivo RDS con los tweets recolectados.
  Por defecto es el directorio de trabajo actual.

- save:

  Lógico. Indica si se debe guardar el resultado en un archivo RDS (por
  defecto TRUE).

## Value

Un tibble que contiene los datos de tweets recuperados, incluyendo la
fecha, usuario, contenido del tweet, URL del tweet y fecha de captura.

## Details

La función ahora incluye las siguientes mejoras y características:

1.  Autenticación automática: La función intenta autenticarse
    automáticamente en Twitter (X) usando las credenciales
    proporcionadas.

2.  Manejo de errores mejorado: Se han implementado múltiples bloques
    try-catch para manejar diferentes tipos de errores que pueden
    ocurrir durante la ejecución.

3.  Reintento automático: En caso de errores de tiempo de espera, la
    función reintentará automáticamente la operación.

4.  Opción de búsqueda en vivo: Se ha añadido un parámetro `live` para
    permitir la búsqueda de tweets más recientes (TRUE) o destacados
    (FALSE).

5.  Procesamiento de datos mejorado: Se ha mejorado el proceso de
    extracción y almacenamiento de datos de los tweets.

6.  Límite de intentos: Se ha implementado un límite de intentos para
    evitar bucles infinitos en caso de problemas persistentes.

7.  Feedback en tiempo real: La función ahora proporciona mensajes
    informativos sobre el progreso de la recolección de tweets.

8.  Control de guardado: Se ha añadido un parámetro `save` para
    controlar si los resultados se guardan en un archivo RDS.

Nota: Esta función depende de la estructura actual de la página web de
Twitter (X). Cambios en la estructura del sitio pueden afectar su
funcionamiento.

## References

Puedes encontrar más información sobre el paquete TweetScrapeR en:
<https://github.com/agusnieto77/TweetScraperR>

## Examples

``` r
if (FALSE) { # \dontrun{
getTweetsHistoricalSearch(
  search = "R Project", n_tweets = 50,
  since = "2018-10-26", until = "2023-10-30",
  live = TRUE
)

# Sin guardar los resultados
getTweetsHistoricalSearch(
  search = "R Project", n_tweets = 50,
  since = "2018-10-26", until = "2023-10-30",
  live = TRUE, save = FALSE
)
} # }
```
