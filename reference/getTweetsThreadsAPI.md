# Crawl Full Reply Trees of Tweets (experimental)

[![\[Experimental\]](https://lifecycle.r-lib.org/articles/figures/lifecycle-experimental.svg)](https://lifecycle.r-lib.org/articles/stages.html#experimental)

A partir de tweets ya descargados (por ejemplo con
[`getTweetsSearchAPI()`](https://agusnieto77.github.io/TweetScraperR/reference/getTweetsSearchAPI.md)
o
[`getTweetsHistoricalAPI()`](https://agusnieto77.github.io/TweetScraperR/reference/getTweetsHistoricalAPI.md)),
recupera la **conversacion completa** de cada uno: respuestas,
respuestas a las respuestas y asi a cualquier profundidad. Todos los
tweets de una conversacion comparten el `conversation_id` del tweet que
la inicio, asi que alcanza una busqueda `conversation_id:<id>` por
conversacion (troceada por ventanas como en
[`getTweetsHistoricalAPI()`](https://agusnieto77.github.io/TweetScraperR/reference/getTweetsHistoricalAPI.md),
para los hilos enormes).

Se omiten las conversaciones sin respuestas y cada conversacion se pide
una sola vez aunque varios tweets de entrada pertenezcan a ella. Un
retweet se sigue en el tweet original. Las conversaciones que empezaron
hace mas de 7 dias quedan fuera del indice completo de X: sus respuestas
son una muestra (ver
[`getTweetsHistoricalAPI()`](https://agusnieto77.github.io/TweetScraperR/reference/getTweetsHistoricalAPI.md)).

Con `respuesta_a_id` (el padre de cada respuesta) y `conversation_id` se
reconstruye el arbol.

**Guardado y reanudacion:** con `save = TRUE` o `db`, cada consulta se
guarda en una base SQLite apenas llega. Una conversacion se da por
terminada solo si todas sus consultas respondieron; las cortadas
(Ctrl+C), fallidas o incompletas quedan pendientes. Para reanudar, llama
de nuevo con `db = "<ruta>.sqlite"` (sin `tweets`, o con los mismos).

## Usage

``` r
getTweetsThreadsAPI(
  tweets = NULL,
  n_per_window = 900,
  db = NULL,
  dir = getwd(),
  save = FALSE
)
```

## Arguments

- tweets:

  Un tibble de tweets (salida de las funciones `*API()`, con la columna
  `conversation_id`) o un vector de IDs de conversacion. Obligatorio al
  empezar; al reanudar se puede omitir.

- n_per_window:

  Tope de tweets por consulta, ver
  [`getTweetsHistoricalAPI()`](https://agusnieto77.github.io/TweetScraperR/reference/getTweetsHistoricalAPI.md).
  Por defecto 900.

- db:

  Ruta a una base `.sqlite`. Si no existe se crea; si existe, se reanuda
  el recorrido guardado en ella. Por defecto NULL.

- dir:

  Directorio donde se crea la base cuando `save = TRUE` y no se pasa
  `db`. Por defecto el de trabajo.

- save:

  Logico. Si TRUE y no se pasa `db`, crea una base nueva
  `api_threads_<fecha>.sqlite` en `dir`. Por defecto FALSE: se usa una
  base temporal que se borra al terminar.

## Value

Un tibble con un tweet por fila (mismas columnas que
[`getTweetsSearchAPI()`](https://agusnieto77.github.io/TweetScraperR/reference/getTweetsSearchAPI.md)),
ordenado por conversacion y fecha. Incluye el tweet raiz de cada
conversacion.

## Examples

``` r
if (FALSE) { # \dontrun{
importSessionX(auth_token = "...", ct0 = "...")
tw <- getTweetsSearchAPI("#RStats", n_tweets = 100)
hilos <- getTweetsThreadsAPI(tw, save = TRUE)
} # }
```
