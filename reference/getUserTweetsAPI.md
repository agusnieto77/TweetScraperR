# Get Tweets from a User Timeline via the X API (experimental)

[![\[Experimental\]](https://lifecycle.r-lib.org/articles/figures/lifecycle-experimental.svg)](https://lifecycle.r-lib.org/articles/stages.html#experimental)

Recupera los tweets del timeline de unx usuarix consultando la **API
GraphQL interna de X** (en lugar de scrapear HTML). Devuelve datos
estructurados directamente del JSON: texto completo (sin truncar), fecha
exacta, y metricas (respuestas, retweets, citas, me gusta, vistas).
Requiere una sesion importada con
[`importSessionX()`](https://agusnieto77.github.io/TweetScraperR/reference/importSessionX.md).

## Usage

``` r
getUserTweetsAPI(username = "NASA", n_tweets = 40, dir = getwd(), save = FALSE)
```

## Arguments

- username:

  Nombre de usuarix (sin @). Por defecto "NASA".

- n_tweets:

  Numero maximo de tweets a recuperar. Por defecto 40.

- dir:

  Directorio de destino del RDS. Por defecto el de trabajo.

- save:

  Logico. Si TRUE guarda el resultado en un RDS dentro de `dir`. Por
  defecto FALSE: no se escribe ningun archivo.

## Value

Un tibble con un tweet por fila y columnas: fecha, user, texto
(completo, tambien en tweets largos), idioma, respuestas, retweets,
citas, megustas, views, emoticones (lista), hashtags (lista), menciones
(lista), urls_externas (lista), media (lista de URLs), media_tipo
(lista: photo/video/animated_gif), es_retweet, es_cita, tweet_citado_id,
conversation_id, url, tweet_id, user_id (autorx), respuesta_a_id,
respuesta_a_user, retweet_id (tweet original de un retweet), guardados,
fuente (app de publicacion), sensible, editado, lugar y pais
(geoetiqueta, si la hay).

## Examples

``` r
if (FALSE) { # \dontrun{
importSessionX(auth_token = "...", ct0 = "...")
tw <- getUserTweetsAPI("NASA", n_tweets = 100)
} # }
```
