# Extract Tweet URLs from a Timeline by Scrolling

[![\[Experimental\]](https://lifecycle.r-lib.org/articles/figures/lifecycle-experimental.svg)](https://lifecycle.r-lib.org/articles/stages.html#experimental)

**Obsoleta**: preférí getUserTweetsAPI(), basada en la API de X (datos
del JSON, mas robusta).

Esta función extrae las urls de los tweets de una línea de tiempo de
Twitter previamente abierta, desplazándose por la página para recopilar
la información deseada.

## Usage

``` r
getScrollExtractUrls(
  objeto = timeline,
  username = "rstatstweet",
  n_tweets = 100,
  dir = getwd(),
  save = TRUE
)
```

## Arguments

- objeto:

  Un objeto de sesión de navegador web, por defecto 'timeline'.

- username:

  Character. El nombre de usuario de Twitter cuya línea de tiempo se
  está extrayendo.

- n_tweets:

  Numeric. El número máximo de tweets a extraer. Por defecto es 100.

- dir:

  Character. El directorio donde se guardará el archivo RDS con los
  tweets extraídos. Por defecto es el directorio de trabajo actual.

- save:

  Logical. Indica si se debe guardar el resultado en un archivo RDS. Por
  defecto es TRUE.

## Value

Un vector con las urls extraídas

## Details

La función realiza las siguientes acciones:

1.  Inicia la extracción de tweets de la línea de tiempo.

2.  Desplaza la página hacia abajo para cargar más tweets.

3.  Extrae las urls de los tweets visibles.

4.  Continúa el proceso hasta alcanzar el número deseado de urls o hasta
    que no se carguen más tweets nuevos.

5.  Si save es TRUE, guarda las urls extraídas en un archivo RDS en el
    directorio especificado.

La función utiliza selectores CSS específicos para extraer la url de los
tweets. Si la extracción se detiene antes de alcanzar el número deseado
de tweets, puede ser debido a limitaciones en la carga de tweets por
parte de Twitter o problemas de conexión.

## Note

Esta función asume que ya se ha abierto una sesión de navegador con la
línea de tiempo de Twitter utilizando la función
[`openTimeline()`](https://agusnieto77.github.io/TweetScraperR/reference/openTimeline.md)
u otra función similar.

## See also

[`openTimeline`](https://agusnieto77.github.io/TweetScraperR/reference/openTimeline.md)
para abrir una línea de tiempo de Twitter.
[`closeTimeline`](https://agusnieto77.github.io/TweetScraperR/reference/closeTimeline.md)
para cerrar la sesión del navegador después de la extracción.

## Examples

``` r
if (FALSE) { # \dontrun{
# Primero, abrir una línea de tiempo
openTimeline("rstatstweet")

# Luego, extraer tweets y guardar el resultado
urls_extraidas <- getScrollExtractUrls(timeline, "rstatstweet", n_tweets = 200, save = TRUE)

# Extraer tweets sin guardar el resultado
urls_extraidas <- getScrollExtractUrls(timeline, "rstatstweet", n_tweets = 200, save = FALSE)

# Cerrar la línea de tiempo después de la extracción
closeTimeline()
} # }
```
