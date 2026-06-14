# Get Tweets Data

[![\[Experimental\]](https://lifecycle.r-lib.org/articles/figures/lifecycle-experimental.svg)](https://lifecycle.r-lib.org/articles/stages.html#experimental)

**Obsoleta**: preféri getTweetsDataAPI(), basada en la API de X (datos
del JSON, mas robusta).

Esta función permite recuperar y procesar datos de tweets a partir de un
vector de URLs de tweets proporcionadas. Utilizando las credenciales de
unx usuarix de Twitter, la función realiza la autenticación en Twitter y
extrae información detallada de cada tweet. Los datos extraídos incluyen
la fecha del tweet, el nombre de usuarix que lo publicó, el texto del
tweet, las respuestas, reposts, me gusta, URLs asociadas, y otra
información relevante. La función también maneja tweets borrados y
errores durante el proceso de recolección, y clasifica las URLs de los
tweets en tres categorías: tweets recuperados, tweets borrados, y tweets
que necesitan ser reprocesados. Si el parámetro 'save' es TRUE, los
datos recopilados se guardan en un archivo RDS en el directorio
especificado por le usuarix.

## Usage

``` r
getTweetsData(
  urls_tweets,
  xuser = Sys.getenv("TWITTER_USER", Sys.getenv("USER")),
  xpass = Sys.getenv("TWITTER_PASS", Sys.getenv("PASS")),
  dir = getwd(),
  save = TRUE
)
```

## Arguments

- urls_tweets:

  Vector de URLs de tweets de los cuales se desea obtener datos.

- xuser:

  Nombre de usuarix de Twitter para autenticación. Por defecto es el
  valor de la variable de entorno TWITTER_USER y, si esta no está
  definida, el de la variable de entorno del sistema USER.

- xpass:

  Contraseña de Twitter para autenticación. Por defecto es el valor de
  la variable de entorno TWITTER_PASS y, si esta no está definida, el de
  la variable de entorno del sistema PASS.

- dir:

  directorio para guardar el RDS con las URLs recolectadas

- save:

  Logical. Indica si se debe guardar el resultado en un archivo RDS. Por
  defecto es TRUE.

## Value

Un tibble que contiene los datos de los tweets recuperados.

## Details

Cuando save = TRUE, se guarda un archivo RDS con una lista que contiene:

- `tweets_recuperados`: Un tibble con los datos de los tweets
  recuperados, incluyendo la fecha, nombre de usuario, texto,
  respuestas, reposts, me gusta, URLs asociadas y otras informaciones
  recopiladas.

- `tweets_borrados`: Un vector con las URLs de los tweets que fueron
  detectados como borrados.

- `tweets_a_reprocesar`: Un vector con las URLs de los tweets que no
  pudieron ser procesados exitosamente y necesitan ser reprocesados.

- `errores`: Un vector con los mensajes de error recopilados durante el
  proceso de recolección de datos.

## Examples

``` r
if (FALSE) { # \dontrun{
getTweetsData(urls_tweets = "https://twitter.com/estacion_erre/status/1788929978811232537")
getTweetsData(
  urls_tweets = "https://twitter.com/estacion_erre/status/1788929978811232537",
  save = FALSE
)
} # }
```
