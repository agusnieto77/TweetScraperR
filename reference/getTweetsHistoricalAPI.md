# Historical Search over a Date Range (experimental)

[![\[Experimental\]](https://lifecycle.r-lib.org/articles/figures/lifecycle-experimental.svg)](https://lifecycle.r-lib.org/articles/stages.html#experimental)

Descarga todos los tweets de una busqueda en un periodo. Una sola
consulta de
[`getTweetsSearchAPI()`](https://agusnieto77.github.io/TweetScraperR/reference/getTweetsSearchAPI.md)
devuelve como mucho unos cientos de tweets (X deja de paginar), asi que
en periodos densos se pierde casi todo. Esta funcion trocea el periodo
en ventanas (mes, semana o dia segun su duracion) y, cuando una ventana
se satura, sigue pidiendo desde el tweet mas viejo recibido hacia atras;
si no avanza, la subdivide (6 h, 3 h, 1 h, 30 min). La estrategia esta
adaptada del modo "optimized search" de
[t-hoarder-twscrape](https://github.com/congosto/t-hoarder-twscrape).

**Limite de X:** el buscador solo tiene completo el contenido de los
**ultimos ~7 dias** (desde las 00:00 UTC de hace 7 dias). Mas atras, la
pestania "Latest" devuelve un residuo (en las pruebas, 37 tweets en un
dia con miles). Para ese tramo la funcion usa "Destacados" (`Top`) en
ventanas fijas de 3 horas, que en las pruebas devolvio unas diez veces
mas (410 en el mismo dia). Aun asi es una **muestra** de lo que X
considera relevante, no el total: para eventos en curso, descarga
mientras estan dentro de los 7 dias, o sigue el tema con
[`getTweetsLiveAPI()`](https://agusnieto77.github.io/TweetScraperR/reference/getTweetsLiveAPI.md).

**Guardado y reanudacion:** con `save = TRUE` o `db`, cada consulta se
guarda en una base SQLite apenas llega (un corte no pierde lo
confirmado). Si la descarga se corta (Ctrl+C, error, falta de cuentas),
se reanuda llamando de nuevo con el mismo `search` y
`db = "<ruta>.sqlite"`: solo se piden las ventanas pendientes, con el
periodo y el plan de ventanas guardados al crear la base, y una ventana
saturada sigue desde la frontera a la que habia llegado. Una ventana con
alguna consulta fallida o incompleta queda pendiente. Como X trunca
respuestas al azar, una respuesta corta no cierra la ventana: se sigue
pidiendo lo anterior al tweet mas viejo recibido. Antes de aceptar un
vacio se verifica con una consulta testigo que X no este frenando en
silencio (tras muchas consultas devuelve vacio todo sin avisar); si
frena, la descarga se corta y queda pendiente para reanudar mas tarde.
Cada tweet ocupa unos 2 KB en la base.

## Usage

``` r
getTweetsHistoricalAPI(
  search,
  since = NULL,
  until = NULL,
  n_per_window = 900,
  db = NULL,
  dir = getwd(),
  save = FALSE
)
```

## Arguments

- search:

  Consulta de busqueda (soporta los operadores de X).

- since:

  Comienzo del periodo: un dia `"YYYY-MM-DD"` (00:00 UTC) o un instante
  `"YYYY-MM-DD HH:MM[:SS]"` en UTC; tambien `Date` o `POSIXct`.
  Obligatorio al empezar; al reanudar se puede omitir.

- until:

  Fin del periodo, mismos formatos. Un dia incluye ese dia completo
  (hasta las 24:00 UTC). Por defecto, ahora (al reanudar, el fin
  guardado).

- n_per_window:

  Tope de tweets por consulta. Una ventana que devuelve 500 o mas (o
  `n_per_window`, si es menor) se considera saturada. Minimo 100. Por
  defecto 900.

- db:

  Ruta a una base `.sqlite`. Si no existe se crea; si existe, se reanuda
  la descarga guardada en ella. Por defecto NULL.

- dir:

  Directorio donde se crea la base cuando `save = TRUE` y no se pasa
  `db`. Por defecto el de trabajo.

- save:

  Logico. Si TRUE y no se pasa `db`, crea una base nueva
  `api_historical_<consulta>_<fecha>.sqlite` en `dir`. Por defecto
  FALSE: se usa una base temporal que se borra al terminar.

## Value

Un tibble con un tweet por fila, del mas nuevo al mas viejo, solo con
tweets dentro del periodo (mismas columnas que
[`getTweetsSearchAPI()`](https://agusnieto77.github.io/TweetScraperR/reference/getTweetsSearchAPI.md)).
Al reanudar incluye lo descargado en las corridas anteriores.

## Examples

``` r
if (FALSE) { # \dontrun{
importSessionX(auth_token = "...", ct0 = "...")
tw <- getTweetsHistoricalAPI("milei", since = "2026-10-20", until = "2026-10-21",
                             save = TRUE)
# Si se corto: reanudar con la base que creo
tw <- getTweetsHistoricalAPI("milei", db = "api_historical_milei_2026_10_21_22_43_04.sqlite")
} # }
```
