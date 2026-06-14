# Get Tweets from a Full Search

[![\[Experimental\]](https://lifecycle.r-lib.org/articles/figures/lifecycle-experimental.svg)](https://lifecycle.r-lib.org/articles/stages.html#experimental)

**Obsoleta**: preférí getTweetsSearchAPI(), basada en la API de X (datos
del JSON, mas robusta).

Esta función realiza una búsqueda avanzada de tweets en Twitter (X)
utilizando varios criterios de búsqueda y recolecta los tweets que
coinciden con estos criterios.

## Usage

``` r
getTweetsFullSearch(
  search_all = "R Project",
  search_exact = NULL,
  search_any = NULL,
  no_search = NULL,
  hashtag = NULL,
  lan = NULL,
  from = NULL,
  to = NULL,
  men = NULL,
  rep = 0,
  fav = 0,
  rt = 0,
  timeout = 10,
  n_tweets = 100,
  since = Sys.Date() - 7,
  until = Sys.Date(),
  xuser = Sys.getenv("TWITTER_USER", Sys.getenv("USER")),
  xpass = Sys.getenv("TWITTER_PASS", Sys.getenv("PASS")),
  dir = getwd(),
  save = TRUE
)
```

## Arguments

- search_all:

  Cadena de texto. Busca tweets que contengan todas estas palabras (por
  defecto "R Project").

- search_exact:

  Cadena de texto. Busca tweets que contengan esta frase exacta (por
  defecto NULL).

- search_any:

  Cadena de texto. Busca tweets que contengan cualquiera de estas
  palabras (por defecto NULL).

- no_search:

  Cadena de texto. Excluye tweets que contengan estas palabras (por
  defecto NULL).

- hashtag:

  Cadena de texto. Busca tweets con estos hashtags (por defecto NULL).

- lan:

  Cadena de texto. Filtra tweets por idioma (por defecto NULL).

- from:

  Cadena de texto. Busca tweets de estos usuarios (por defecto NULL).

- to:

  Cadena de texto. Busca tweets dirigidos a estos usuarios (por defecto
  NULL).

- men:

  Cadena de texto. Busca tweets que mencionan a estos usuarios (por
  defecto NULL).

- rep:

  Número entero. Número mínimo de respuestas que debe tener un tweet
  (por defecto 0).

- fav:

  Número entero. Número mínimo de favoritos que debe tener un tweet (por
  defecto 0).

- rt:

  Número entero. Número mínimo de retweets que debe tener un tweet (por
  defecto 0).

- timeout:

  Número entero. Tiempo de espera en segundos entre solicitudes (por
  defecto 10).

- n_tweets:

  Número entero. Número máximo de tweets a recolectar (por defecto 100).

- since:

  Fecha. Fecha de inicio para la búsqueda (por defecto 7 días antes de
  la fecha actual).

- until:

  Fecha. Fecha de fin para la búsqueda (por defecto la fecha actual).

- xuser:

  Cadena de texto. Nombre de usuario para la autenticación en Twitter
  (por defecto se toma de la variable de entorno TWITTER_USER o, en su
  defecto, USER).

- xpass:

  Cadena de texto. Contraseña para la autenticación en Twitter (por
  defecto se toma de la variable de entorno TWITTER_PASS o, en su
  defecto, PASS).

- dir:

  Cadena de texto. Directorio donde se guardarán los resultados (por
  defecto el directorio de trabajo actual).

- save:

  Lógico. Indica si se debe guardar el resultado en un archivo RDS (por
  defecto TRUE).

## Value

Un tibble con los tweets recolectados, incluyendo las columnas:

- art_html:

  HTML del artículo del tweet

- fecha:

  Fecha y hora del tweet

- user:

  Nombre de usuario del autor del tweet

- tweet:

  Texto del tweet

- url:

  URL del tweet

- fecha_captura:

  Fecha y hora de la captura del tweet

## Details

La función primero intenta autenticarse en Twitter utilizando las
credenciales proporcionadas. Luego, construye una URL de búsqueda basada
en los parámetros proporcionados y realiza la búsqueda. Los tweets se
recolectan iterativamente, scrolleando la página hasta que se alcance el
número deseado de tweets o se agoten los intentos. Los tweets
recolectados se procesan para extraer la información relevante y, si
save es TRUE, se guardan en un archivo RDS.

## Note

Esta función requiere una conexión a Internet y credenciales válidas de
Twitter.

## Examples

``` r
if (FALSE) { # \dontrun{
tweets <- getTweetsFullSearch(
  search_all = "clima cambio",
  hashtag = "#medioambiente",
  lan = "es",
  n_tweets = 100,
  since = Sys.Date() - 30,
  save = TRUE
)

# Sin guardar los resultados
tweets <- getTweetsFullSearch(
  search_all = "clima cambio",
  hashtag = "#medioambiente",
  lan = "es",
  n_tweets = 100,
  since = Sys.Date() - 30,
  save = FALSE
)
} # }
```
