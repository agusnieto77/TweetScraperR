# Read Tweets Saved by a Long Download

Lee los tweets guardados en la base SQLite de
[`getTweetsHistoricalAPI()`](https://agusnieto77.github.io/TweetScraperR/reference/getTweetsHistoricalAPI.md),
[`getTweetsLiveAPI()`](https://agusnieto77.github.io/TweetScraperR/reference/getTweetsLiveAPI.md)
o
[`getTweetsThreadsAPI()`](https://agusnieto77.github.io/TweetScraperR/reference/getTweetsThreadsAPI.md)
(con `save = TRUE` o `db`), sin volver a descargar nada. Sirve tambien
para revisar lo recolectado por una descarga cortada antes de
reanudarla.

## Usage

``` r
readTweetsDB(db)
```

## Arguments

- db:

  Ruta al archivo `.sqlite`.

## Value

Un tibble con un tweet por fila, del mas nuevo al mas viejo (mismas
columnas que
[`getTweetsSearchAPI()`](https://agusnieto77.github.io/TweetScraperR/reference/getTweetsSearchAPI.md)).

## Examples

``` r
if (FALSE) { # \dontrun{
tw <- readTweetsDB("api_historical_milei_2026_10_21_22_43_04.sqlite")
} # }
```
