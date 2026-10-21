# Get Tweet Replies / Thread via the X API (experimental)

[![\[Experimental\]](https://lifecycle.r-lib.org/articles/figures/lifecycle-experimental.svg)](https://lifecycle.r-lib.org/articles/stages.html#experimental)

Recupera el tweet y sus respuestas (hilo de conversacion) consultando la
**API GraphQL interna de X**. Devuelve datos estructurados del JSON.
Requiere una sesion importada con
[`importSessionX()`](https://agusnieto77.github.io/TweetScraperR/reference/importSessionX.md).

## Usage

``` r
getTweetsRepliesAPI(url, n_tweets = 40, dir = getwd(), save = FALSE)
```

## Arguments

- url:

  URL del tweet del cual obtener las respuestas.

- n_tweets:

  Numero maximo de tweets (tweet + respuestas) a recuperar. Por defecto
  40.

- dir:

  Directorio de destino del RDS. Por defecto el de trabajo.

- save:

  Logico. Si TRUE guarda el resultado en un RDS dentro de `dir`. Por
  defecto FALSE: no se escribe ningun archivo.

## Value

Un tibble con un tweet por fila (mismas columnas que
[`getUserTweetsAPI()`](https://agusnieto77.github.io/TweetScraperR/reference/getUserTweetsAPI.md),
incluyendo media, hashtags, menciones, etc.).

## Examples

``` r
if (FALSE) { # \dontrun{
importSessionX(auth_token = "...", ct0 = "...")
getTweetsRepliesAPI("https://x.com/sanchezcastejon/status/2111426246517072370", n_tweets = 100)
} # }
```
