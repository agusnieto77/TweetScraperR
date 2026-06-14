# Get Tweets Data II

[![\[Experimental\]](https://lifecycle.r-lib.org/articles/figures/lifecycle-experimental.svg)](https://lifecycle.r-lib.org/articles/stages.html#experimental)

**Obsoleta**: preféri getTweetsDataAPI(), basada en la API de X (datos
del JSON, mas robusta).

Esta función permite recuperar y procesar datos de tweets a partir de un
vector de URLs de tweets proporcionadas. Los datos extraídos incluyen la
fecha del tweet, el nombre de usuarix que lo publicó, el texto del
tweet, las respuestas, reposts, me gusta, URLs asociadas, y otra
información relevante. A diferencia de getTweetsData(), esta función no
realiza el proceso de autenticación en Twitter: asume que ya existe una
sesión autenticada en el navegador. La función también maneja tweets
borrados y errores durante el proceso de recolección, y clasifica las
URLs de los tweets en tres categorías: tweets recuperados, tweets
borrados, y tweets que necesitan ser reprocesados. Si el parámetro
'save' es TRUE, los datos recopilados se guardan en un archivo RDS en el
directorio especificado por le usuarix.

## Usage

``` r
getTweetsData2(urls_tweets, dir = getwd(), save = TRUE)
```

## Arguments

- urls_tweets:

  Vector de URLs de tweets de los cuales se desea obtener datos.

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
getTweetsData2(urls_tweets = "https://twitter.com/estacion_erre/status/1788929978811232537")
getTweetsData2(
  urls_tweets = "https://twitter.com/estacion_erre/status/1788929978811232537",
  save = FALSE
)
} # }
```
