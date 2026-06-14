# Get Tweets URLs by Search

[![\[Experimental\]](https://lifecycle.r-lib.org/articles/figures/lifecycle-experimental.svg)](https://lifecycle.r-lib.org/articles/stages.html#experimental)

**Obsoleta**: preférí getTweetsSearchAPI(), basada en la API de X (datos
del JSON, mas robusta).

Esta función recupera URLs de tweets basados en una consulta de búsqueda
especifica en Twitter. Utiliza el buscador de Twitter para encontrar
tweets que coincidan con el término de búsqueda proporcionado,
enfocándose en los tweets destacados que aparecen en la plataforma.
Opcionalmente puede iniciar sesión en Twitter usando las credenciales
proporcionadas si open=TRUE, realiza la búsqueda, y recolecta las URLs
de los tweets que corresponden a la consulta.

La recolección se detiene cuando se ha alcanzado el número especificado
de URLs o cuando no se encuentran nuevas URLs después de varios
intentos. Las URLs recolectadas se guardan en un archivo RDS en el
directorio especificado si el parámetro 'save' es TRUE, y también se
devuelven como un vector de cadenas con las urls recolectadas.

## Usage

``` r
getUrlsTweetsSearch(
  search = "#RStats",
  n_urls = 100,
  open = FALSE,
  xuser = Sys.getenv("TWITTER_USER", Sys.getenv("USER")),
  xpass = Sys.getenv("TWITTER_PASS", Sys.getenv("PASS")),
  max_retries = 3,
  dir = getwd(),
  save = TRUE
)
```

## Arguments

- search:

  La consulta de búsqueda para usar en la recuperación de tweets. Por
  defecto es "#RStats".

- n_urls:

  El número máximo de URLs de tweets a recuperar. Por defecto es 100.

- open:

  Indica si se debe realizar el proceso de autenticación (por defecto
  FALSE).

- xuser:

  Nombre de usuarix de Twitter para autenticación. Por defecto es el
  valor de la variable de entorno TWITTER_USER (o, si no está definida,
  USER).

- xpass:

  Contraseña de Twitter para autenticación. Por defecto es el valor de
  la variable de entorno TWITTER_PASS (o, si no está definida, PASS).

- max_retries:

  número máximo de intentos de conexión.

- dir:

  Directorio de destino de los RDS.

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
# Sin autenticación
getUrlsTweetsSearch(search = "#RStats", n_urls = 200)

# Con autenticación
getUrlsTweetsSearch(search = "#RStats", n_urls = 200, open = TRUE)

# Sin guardar los resultados
getUrlsTweetsSearch(search = "#RStats", n_urls = 200, save = FALSE)
} # }
```
