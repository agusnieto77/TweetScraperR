# Extracts Relevant Information from Locally Stored Tweets

[![\[Experimental\]](https://lifecycle.r-lib.org/articles/figures/lifecycle-experimental.svg)](https://lifecycle.r-lib.org/articles/stages.html#experimental)

Esta función procesa un conjunto de tweets almacenados localmente y
extrae información relevante de cada uno. Puede manejar tanto un
dataframe como una lista que contenga el HTML de los tweets, sus URLs
correspondientes y las fechas de captura.

## Usage

``` r
extractTweetsData(data)
```

## Arguments

- data:

  Un dataframe o una lista que contiene tres elementos: 'art_html' (el
  contenido HTML de los tweets), 'url' (las URLs de los tweets) y
  'fecha_captura' (la fecha y hora de captura de cada tweet).

## Value

Un tibble con las siguientes columnas:

- fecha: La fecha y hora del tweet.

- username: El nombre de usuario del autor del tweet.

- texto: El texto principal del tweet.

- tweet_citado: El texto del tweet citado, si existe.

- user_citado: El nombre de usuario del autor del tweet citado, si
  existe.

- emoticones: Una lista de emoticones utilizados en el tweet.

- links_img_user: El enlace a la imagen de perfil del usuario.

- links_img_post: Una lista de enlaces a las imágenes incluidas en el
  tweet.

- links_youtube: Una lista de enlaces a videos de YouTube mencionados en
  el tweet.

- respuestas: El número de respuestas al tweet.

- reposteos: El número de reposteos del tweet.

- megustas: El número de "me gusta" del tweet.

- metricas: Información adicional sobre las métricas del tweet.

- urls: Una lista de URLs mencionadas en el tweet.

- hilo: Indica si el tweet es parte de un hilo (basado en el número de
  respuestas).

- url: La URL original del tweet.

- fecha_captura: La fecha y hora en que se capturó la información del
  tweet (heredada de los datos de entrada).

## Details

La función utiliza expresiones XPath y selectores CSS para extraer
información específica de cada tweet. Procesa cada tweet individualmente
y maneja posibles errores, permitiendo continuar con el procesamiento
incluso si algunos tweets fallan. La función ahora puede manejar tanto
URLs de Twitter como de X.com. Se han añadido nuevas extracciones, como
enlaces a videos de YouTube y se ha mejorado la extracción de
emoticones.

## Examples

``` r
if (FALSE) { # \dontrun{
# Usando un dataframe
tweets_data <- data.frame(
  art_html = c("<html>...</html>", "<html>...</html>"),
  url = c("https://twitter.com/user1/status/123", "https://x.com/user2/status/456"),
  fecha_captura = c("2023-01-01 12:00:00", "2023-01-02 13:00:00")
)
resultados <- extractTweetsData(tweets_data)

# Usando una lista
tweets_list <- list(
  art_html = c("<html>...</html>", "<html>...</html>"),
  url = c("https://twitter.com/user1/status/123", "https://x.com/user2/status/456"),
  fecha_captura = c("2023-01-01 12:00:00", "2023-01-02 13:00:00")
)
resultados <- extractTweetsData(tweets_list)
} # }
```
