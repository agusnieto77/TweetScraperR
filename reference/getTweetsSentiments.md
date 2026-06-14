# Analyze sentiments of tweets

[![\[Experimental\]](https://lifecycle.r-lib.org/articles/figures/lifecycle-experimental.svg)](https://lifecycle.r-lib.org/articles/stages.html#experimental)

Esta función toma un vector de tweets y utiliza la API de OpenAI para
realizar un análisis de sentimiento detallado de cada tweet. El análisis
incluye el tono, el sentimiento general, la presencia de expresiones de
odio, si el tweet está direccionado a alguien específico y si contiene
un llamado a la acción.

## Usage

``` r
getTweetsSentiments(
  tweets,
  api_key = Sys.getenv("OPENAI_API_KEY"),
  model = "gpt-4o-mini",
  dir = getwd(),
  save = TRUE
)
```

## Arguments

- tweets:

  Un vector de caracteres que contiene los tweets a analizar.

- api_key:

  Una cadena de caracteres con la clave de API de OpenAI. Por defecto,
  se intenta obtener de la variable de entorno OPENAI_API_KEY.

- model:

  Una cadena de caracteres que especifica el modelo de OpenAI a
  utilizar. Por defecto es "gpt-4o-mini".

- dir:

  Una cadena de caracteres que especifica el directorio donde se
  guardarán los archivos RDS con los resultados. Por defecto es el
  directorio de trabajo actual.

- save:

  Lógico. Indica si se deben guardar los resultados (totales y
  parciales) en archivos RDS dentro de `dir`. Por defecto es TRUE.

## Value

Un tibble con los resultados del análisis para cada tweet. Cada fila
contiene el tweet original y los resultados del análisis (tono,
sentimiento, presencia de expresiones de odio, si está direccionado, si
contiene un llamado a la acción y una explicación detallada).

## Details

La función realiza las siguientes operaciones:

1.  Verifica que se haya proporcionado una clave de API válida.

2.  Define un prompt detallado para el análisis de los tweets.

3.  Define una función interna `analyzeTweet` que procesa cada tweet
    individualmente.

4.  Procesa los tweets en lotes de 250 para manejar grandes volúmenes de
    datos.

5.  Guarda resultados parciales cada 50 tweets procesados.

6.  Devuelve los resultados como un tibble.

La función utiliza la API de OpenAI para realizar el análisis de
sentimiento, por lo que requiere una conexión a Internet y una clave de
API válida.

## Note

Esta función transmite el contenido de los tweets analizados a la API de
OpenAI (un servicio de terceros). Tenga en cuenta esta transferencia de
datos al trabajar con contenido de terceros o datos personales.

## Examples

``` r
if (FALSE) { # \dontrun{
tweets <- c(
  "¡Qué día tan maravilloso! \U0001f60a",
  "Odio este producto, nunca lo compren. \U0001f620"
)
resultados <- getTweetsSentiments(tweets)
print(resultados)
} # }
```
