# Parámetros de búsqueda: operadores de X con getTweetsSearchAPI()

[`getTweetsSearchAPI()`](https://agusnieto77.github.io/TweetScraperR/reference/getTweetsSearchAPI.md)
le pasa el argumento `search` tal cual al buscador de X, así que acepta
los mismos **operadores** que la búsqueda avanzada de la web: varios
términos, frases exactas, `OR`, exclusiones, hashtags, cuentas de origen
y destino, fechas, idioma, métricas mínimas y tipo de contenido. Este
artículo recorre esos operadores con un ejemplo por cada uno.

**Todos los ejemplos se ejecutaron contra X el 21 de octubre de 2026** y
cada uno incluye una verificación sobre las columnas devueltas (por
ejemplo, que con `from:JMilei` todas las filas tengan
`user == "@JMilei"`). Las salidas son las reales de esa fecha; si los
ejecutás otro día vas a obtener otros tweets. Para no repetir ruido, se
omiten los mensajes de consola de cada búsqueda (`Buscando: ...`,
`Tweets únicos recolectados: ...`).

Antes de empezar hace falta una sesión importada (ver la viñeta
[Primeros
pasos](https://agusnieto77.github.io/TweetScraperR/articles/tweetscraperr.md)):

``` r

library(TweetScraperR)
importSessionX(auth_token = "tu_auth_token", ct0 = "tu_ct0")
```

> **Si una búsqueda devuelve 0 tweets, reintentala.** En las pruebas, la
> misma consulta devolvió de forma intermitente un resultado vacío y, al
> repetirla, los tweets esperados. Un vacío aislado no significa que el
> operador no funcione.

## 1. Términos

### Varias palabras (todas deben aparecer)

Separadas por espacios, X busca tweets que contengan **todas** las
palabras, en cualquier orden:

``` r

tw <- getTweetsSearchAPI("inteligencia artificial", n_tweets = 15)
head(tw[, c("fecha", "user", "texto")], 3)
#> # A tibble: 3 × 3
#>   fecha               user             texto
#>   <dttm>              <chr>            <chr>
#> 1 2026-10-21 22:23:30 @RoraimaC        "¿Alguien más ya se había dado cuenta qu…
#> 2 2026-10-21 22:22:33 @labitconf       "HOY! En un ratito nada más @RodolfoBits…
#> 3 2026-10-21 22:22:21 @CursosCarbonell "Centro Carbonell y el uso académico de …

mean(grepl("inteligencia", tolower(tw$texto)) & grepl("artificial", tolower(tw$texto)))
#> [1] 0.8666667
```

13 de 15 contienen las dos palabras en el texto. Los otros 2 muestran
cómo busca X: uno está en portugués (“inteligência Artificial”: **X
ignora los tildes**) y el otro coincide por el contenido del enlace que
comparte, no por el texto del tweet.

### Frase exacta

Entre comillas dobles, las palabras tienen que aparecer juntas y en ese
orden. En R conviene encerrar la consulta entre comillas simples:

``` r

tw <- getTweetsSearchAPI('"inteligencia artificial"', n_tweets = 15)
sum(grepl("inteligencia artificial", tolower(tw$texto)))
#> [1] 13
```

Los 2 restantes son los mismos casos de arriba (tildes y enlace).

### Una u otra palabra: `OR`

`OR` va en mayúsculas. Con paréntesis se puede agrupar y combinar con
otros operadores (ver la [sección 8](#combinar-operadores)):

``` r

tw <- getTweetsSearchAPI("inflación OR dólar", n_tweets = 15)
head(tw[, c("user", "texto")], 3)
#> # A tibble: 3 × 2
#>   user          texto
#>   <chr>         <chr>
#> 1 @N0me1mp0rta2 "@hayquedolarizar Sigue perdiendo contra la inflación de bienes…
#> 2 @cr7reygod    "@Maria_DB2023 Si la diferencia puto argenmono que es Corea tie…
#> 3 @fmarches10   "@PatoBullrich Toda de Toto y su politica monetaria de escasez …

sum(grepl("inflaci[oó]n|d[oó]lar", tolower(tw$texto)))
#> [1] 14
tw$texto[!grepl("inflaci[oó]n|d[oó]lar", tolower(tw$texto))]
#> [1] "https://t.co/sYivT99j49"
```

El único que no menciona ninguna de las dos palabras en el texto es un
tweet que solo trae un enlace: la coincidencia está en la página
enlazada.

### Excluir una palabra: `-`

Un guion pegado a la palabra la excluye:

``` r

tw <- getTweetsSearchAPI('"inteligencia artificial" -chatgpt', n_tweets = 15)
any(grepl("chatgpt", tolower(tw$texto)))
#> [1] FALSE
```

## 2. Hashtags

### Un hashtag

``` r

tw <- getTweetsSearchAPI("#ismanosetoca", n_tweets = 15)
head(tw[, c("fecha", "user", "hashtags")], 3)
#> # A tibble: 3 × 3
#>   fecha               user            hashtags
#>   <dttm>              <chr>           <list>
#> 1 2026-10-21 21:28:25 @aliziacomunica <chr [1]>
#> 2 2026-10-21 20:31:47 @El_Intermedio  <chr [1]>
#> 3 2026-10-21 20:00:41 @jmposnolose    <chr [1]>

all(sapply(tw$hashtags, function(h) "ismanosetoca" %in% tolower(h)))
#> [1] TRUE
```

La búsqueda no distingue mayúsculas: en `hashtags` aparecen
`ismanosetoca`, `Ismanosetoca` e `ISMANOSETOCA`.

### Varios hashtags a la vez

Igual que con las palabras, separados por espacios tienen que estar
**todos**:

``` r

tw <- getTweetsSearchAPI("#RStats #DataScience", n_tweets = 15)
nrow(tw)
#> [1] 5
tw$hashtags[1:3]
#> [[1]]
#> [1] "RStats"      "DataScience"
#>
#> [[2]]
#> [1] "DataScience" "stats"       "rstats"      "ML"          "formacion"
#>
#> [[3]]
#> [1] "DataScience"     "Python"          "RStats"          "MachineLearning"
#> [5] "TimeSeries"
```

Se pidieron 15 pero X devolvió 5: la combinación es más restrictiva y no
hay más tweets recientes con ambos hashtags.

### Uno u otro hashtag

``` r

tw <- getTweetsSearchAPI("#RStats OR #Python", n_tweets = 20)
h <- lapply(tw$hashtags, tolower)
c(rstats = sum(sapply(h, function(x) "rstats" %in% x)),
  python = sum(sapply(h, function(x) "python" %in% x)))
#> rstats python
#>      2     18
```

Los 20 tweets tienen al menos uno de los dos hashtags.

## 3. Usuarios

### Tweets de una cuenta: `from:`

``` r

tw <- getTweetsSearchAPI("from:JMilei", n_tweets = 15)
head(tw[, c("fecha", "user", "texto")], 3)
#> # A tibble: 3 × 3
#>   fecha               user    texto
#>   <dttm>              <chr>   <chr>
#> 1 2026-10-21 19:28:44 @JMilei "100 AÑOS DE PERDÓN..."
#> 2 2026-10-21 19:08:15 @JMilei "UN NIÑO PRODIGIO\nEl día que la Banda Presidennc…
#> 3 2026-10-21 17:05:09 @JMilei "FENÓMENO BARRIAL"

all(tw$user == "@JMilei")
#> [1] TRUE
```

La cuenta va **sin** `@`. A diferencia de
[`getUserTweetsAPI()`](https://agusnieto77.github.io/TweetScraperR/reference/getUserTweetsAPI.md),
con `from:` se pueden sumar otros operadores (fechas, palabras,
`filter:`, etc.).

### Respuestas dirigidas a una cuenta: `to:`

``` r

tw <- getTweetsSearchAPI("to:JMilei", n_tweets = 15)
head(tw[, c("user", "respuesta_a_user", "texto")], 3)
#> # A tibble: 3 × 3
#>   user             respuesta_a_user texto
#>   <chr>            <chr>            <chr>
#> 1 @sandracosta1052 @JMilei          "@JMilei Lava a tua boca podre pra falar do…
#> 2 @Santiago_Doval  @JMilei          "@JMilei No llegar a fin de mes no implica …
#> 3 @RebeccaaminAmin @JMilei          "@JMilei La historia se repite dos veces, p…

unique(tw$respuesta_a_user)
#> [1] "@JMilei"
```

### De una cuenta hacia otra: `from:` + `to:`

Combinados, devuelven las respuestas de una cuenta a otra en particular:

``` r

tw <- getTweetsSearchAPI("from:JMilei to:slcaputo", n_tweets = 15)
tw[, c("fecha", "user", "respuesta_a_user", "texto")]
#> # A tibble: 1 × 4
#>   fecha               user    respuesta_a_user texto
#>   <dttm>              <chr>   <chr>            <chr>
#> 1 2026-10-05 19:04:10 @JMilei @slcaputo        @slcaputo Comparar a Doña Rosa c…
```

Para encontrar con quién conversa una cuenta, primero se pueden buscar
sus respuestas (`from:JMilei filter:replies`, ver la [sección
6](#tipo-de-contenido)) y mirar la columna `respuesta_a_user`.

### Menciones de una cuenta, salvo las propias: `@` y `-from:`

``` r

tw <- getTweetsSearchAPI("@JMilei -from:JMilei", n_tweets = 15)
all(sapply(tw$menciones, function(m) "JMilei" %in% m))
#> [1] TRUE
any(tw$user == "@JMilei")
#> [1] FALSE
```

### Una conversación completa: `conversation_id:`

Todos los tweets de un hilo comparten el `conversation_id` del tweet que
lo inició. Sirve para traer las respuestas a un tweet, incluidas las
respuestas a otras respuestas:

``` r

tw <- getTweetsSearchAPI("conversation_id:2112586702854459901", n_tweets = 20)
all(tw$conversation_id == "2112586702854459901")
#> [1] TRUE
head(tw[, c("user", "respuesta_a_user")], 3)
#> # A tibble: 3 × 2
#>   user            respuesta_a_user
#>   <chr>           <chr>
#> 1 @cuervoloco16   @GonAcademico
#> 2 @Marronazos     @GordoDan_
#> 3 @Arturo_FloresC @JMilei
```

## 4. Fechas

### Por día: `since` y `until`

[`getTweetsSearchAPI()`](https://agusnieto77.github.io/TweetScraperR/reference/getTweetsSearchAPI.md)
tiene los argumentos `since` y `until`. Con un día (`"YYYY-MM-DD"` o un
objeto `Date`), **los dos extremos son inclusivos**:
`until = "2026-10-13"` incluye los tweets del 13.

``` r

tw <- getTweetsSearchAPI("from:NASA", n_tweets = 20,
                         since = "2026-10-10", until = "2026-10-13")
table(as.Date(tw$fecha))
#>
#> 2026-10-11 2026-10-13
#>          1          3
```

(@NASA no publicó el 10 ni el 12). Con el mismo día en los dos extremos
se obtiene un solo día:

``` r

tw <- getTweetsSearchAPI("from:NASA", n_tweets = 40,
                         since = "2026-10-09", until = "2026-10-09")
table(as.Date(tw$fecha))
#>
#> 2026-10-09
#>          5
```

Los argumentos son un atajo: escribir `since:` y `until:` dentro de
`search` da exactamente el mismo resultado:

``` r

tw <- getTweetsSearchAPI("from:NASA since:2026-10-10 until:2026-10-13", n_tweets = 20)
table(as.Date(tw$fecha))
#>
#> 2026-10-11 2026-10-13
#>          1          3
```

### Por hora exacta

Si `since`/`until` llevan hora (`"YYYY-MM-DD HH:MM"` o
`"YYYY-MM-DD HH:MM:SS"`), se interpretan en **UTC**, como la columna
`fecha`, y
[`getTweetsSearchAPI()`](https://agusnieto77.github.io/TweetScraperR/reference/getTweetsSearchAPI.md)
las traduce a los operadores `since_time:` y `until_time:` de X. En este
caso se muestra el mensaje `Buscando:` para que se vea la traducción:

``` r

tw <- getTweetsSearchAPI("argentina", n_tweets = 15,
                         since = "2026-10-20 12:00:00", until = "2026-10-20 12:10:00")
#> Buscando: argentina since_time:1792497600 until_time:1792498200 (Latest)
range(tw$fecha)
#> [1] "2026-10-20 12:09:30 UTC" "2026-10-20 12:09:58 UTC"
```

Todos los tweets caen en la franja (son los 15 más recientes de esos 10
minutos). Para trabajar en otra zona horaria, pasá objetos `POSIXct`,
que conservan su zona:

``` r

a <- as.POSIXct("2026-10-20 13:00", tz = "America/Argentina/Buenos_Aires")
tw <- getTweetsSearchAPI("argentina", n_tweets = 15, since = a, until = a + 600)
#> Buscando: argentina since_time:1792512000 until_time:1792512600 (Latest)
format(range(tw$fecha), tz = "America/Argentina/Buenos_Aires")
#> [1] "2026-10-20 13:09:31" "2026-10-20 13:09:59"
```

Los operadores también se pueden escribir a mano dentro de `search`, con
la hora en segundos Unix:

``` r

as.integer(as.POSIXct(c("2026-10-20 12:00:00", "2026-10-20 12:10:00"), tz = "UTC"))
#> [1] 1792497600 1792498200
tw <- getTweetsSearchAPI("argentina since_time:1792497600 until_time:1792498200",
                         n_tweets = 15)
range(tw$fecha)
#> [1] "2026-10-20 12:09:30 UTC" "2026-10-20 12:09:58 UTC"
```

Ojo: escribir la hora con el operador de días
(`since:2026-10-20_12:00:00`) **no devuelve resultados**; X solo acepta
horas con `since_time:`/`until_time:`.

### Por ID de tweet: `since_id:` y `max_id:`

`since_id:` trae lo **posterior** a un tweet (sin incluirlo) y `max_id:`
lo anterior. Es lo que usa
[`getTweetsLiveAPI()`](https://agusnieto77.github.io/TweetScraperR/reference/getTweetsLiveAPI.md)
para pedir solo tweets nuevos en cada ronda. Como los IDs de X codifican
el instante de publicación, también sirven como franja horaria: la
ventana `since_id:2112514164126646272 max_id:2112516680709046272`
corresponde a 12:00–12:10 UTC del 20/10/2026 y devolvió los mismos 15
tweets que el ejemplo anterior.

## 5. Idioma: `lang:`

``` r

tw <- getTweetsSearchAPI("messi lang:en", n_tweets = 15)
table(tw$idioma)
#>
#> en
#> 15
```

El código es el mismo que devuelve la columna `idioma` (`es`, `en`,
`pt`, …).

## 6. Métricas mínimas: `min_faves:`, `min_retweets:`, `min_replies:`

``` r

tw <- getTweetsSearchAPI("milei min_faves:1000", n_tweets = 15)
head(tw[, c("user", "megustas", "retweets")], 3)
#> # A tibble: 3 × 3
#>   user             megustas retweets
#>   <chr>               <int>    <int>
#> 1 @ArrepentidosLLA     1409      137
#> 2 @laderechadiario     1586      267
#> 3 @OPRArgentina        1683      243
min(tw$megustas)
#> [1] 1018
```

Se pueden combinar:

``` r

tw <- getTweetsSearchAPI("milei min_retweets:500 min_replies:100", n_tweets = 15)
c(retweets = min(tw$retweets), respuestas = min(tw$respuestas))
#>   retweets respuestas
#>        506        102
```

## 7. Tipo de contenido

### Con imágenes, videos o GIFs: `filter:media`

``` r

tw <- getTweetsSearchAPI("milei filter:media", n_tweets = 15)
table(unlist(tw$media_tipo))
#>
#> animated_gif        photo        video
#>            1           14            3
```

`filter:images` **no devolvió resultados** en las pruebas. Para quedarte
solo con los tweets que tienen fotos, filtrá en R por `media_tipo`:

``` r

fotos <- tw[sapply(tw$media_tipo, function(t) "photo" %in% t), ]
nrow(fotos)
#> [1] 10
```

### Con video: `filter:videos`

``` r

tw <- getTweetsSearchAPI("milei filter:videos", n_tweets = 15)
table(unlist(tw$media_tipo))
#>
#> video
#>    15
```

### Con enlaces: `filter:links` y `url:`

`filter:links` trae tweets con algún enlace; `url:` exige un dominio (o
parte de una URL) en particular:

``` r

tw <- getTweetsSearchAPI("inteligencia artificial filter:links", n_tweets = 15)
all(lengths(tw$urls_externas) > 0)
#> [1] TRUE

tw <- getTweetsSearchAPI("url:youtube.com milei", n_tweets = 15)
sum(sapply(tw$urls_externas, function(u) any(grepl("youtu", u, ignore.case = TRUE))))
#> [1] 15
```

### Respuestas sí o no: `filter:replies` y `-filter:replies`

``` r

tw <- getTweetsSearchAPI("milei filter:replies", n_tweets = 15)
any(is.na(tw$respuesta_a_id))
#> [1] FALSE
head(tw$respuesta_a_user)
#> [1] "@eldestapeweb"  "@alferdez"      "@RCachanosky"   "@OPRArgentina"
#> [5] "@BenedettiTano" "@cayetanaAT"

tw <- getTweetsSearchAPI("milei -filter:replies", n_tweets = 15)
all(is.na(tw$respuesta_a_id))
#> [1] TRUE
```

### Citas: `filter:quote`

``` r

tw <- getTweetsSearchAPI("milei filter:quote", n_tweets = 15)
all(tw$es_cita)
#> [1] TRUE
```

El ID del tweet citado queda en la columna `tweet_citado_id`.

## 8. Pestañas de resultados: `product`

El argumento `product` elige la pestaña del buscador: `"Latest"` (por
defecto, orden cronológico), `"Top"` (destacados, mezcla fechas) o
`"Media"` (solo tweets con fotos o videos):

``` r

tw <- getTweetsSearchAPI("milei", n_tweets = 10, product = "Top")
head(tw[, c("fecha", "user", "megustas")], 3)
#> # A tibble: 3 × 3
#>   fecha               user        megustas
#>   <dttm>              <chr>          <int>
#> 1 2026-10-21 14:12:47 @LucaRomero     6835
#> 2 2026-10-20 23:07:41 @winazkifan     1409
#> 3 2026-10-21 17:41:43 @alferdez       3603

tw <- getTweetsSearchAPI("milei", n_tweets = 10, product = "Media")
all(lengths(tw$media) > 0)
#> [1] TRUE
```

## 9. Combinar operadores

Los operadores se suman en la misma consulta. Este ejemplo pide tweets
que digan “inflación” **o** “dólar”, en español, con al menos 100 me
gusta, que no sean respuestas y publicados desde el 1 de octubre:

``` r

tw <- getTweetsSearchAPI(
  "(inflación OR dólar) lang:es min_faves:100 -filter:replies",
  n_tweets = 15, since = "2026-10-01"
)
head(tw[, c("fecha", "user", "megustas", "texto")], 3)
#> # A tibble: 3 × 4
#>   fecha               user            megustas texto
#>   <dttm>              <chr>              <int> <chr>
#> 1 2026-10-21 21:17:40 @Felii_N             108 "El indice de inflación (IPC) co…
#> 2 2026-10-21 20:54:23 @SantiagoVelezP      238 "Los números de Milei hablan por…
#> 3 2026-10-21 20:40:31 @GordaMar_           441 "Si \"salvar el país\" implica v…

c(idioma_es = all(tw$idioma == "es"),
  megustas_100 = all(tw$megustas >= 100),
  sin_respuestas = all(is.na(tw$respuesta_a_id)),
  desde_oct = all(tw$fecha >= as.POSIXct("2026-10-01", tz = "UTC")))
#>      idioma_es   megustas_100 sin_respuestas      desde_oct
#>           TRUE           TRUE           TRUE           TRUE
```

## 10. Los mismos operadores en vivo

[`getTweetsLiveAPI()`](https://agusnieto77.github.io/TweetScraperR/reference/getTweetsLiveAPI.md)
acepta la misma consulta y la repite cada `interval` segundos trayendo
solo tweets nuevos:

``` r

vivo <- getTweetsLiveAPI("milei lang:es -filter:replies",
                         interval = 60, duration = 60, n_tweets = 20)
#> Captura en vivo de: milei lang:es -filter:replies (cada 60 s hasta las 19:41:20)
#> 19:40:27 | ronda 1: 20 nuevos | total: 20
#> 19:41:38 | ronda 2: 9 nuevos | total: 29
#> Captura terminada: 29 tweets en 2 rondas.

c(idioma_es = all(vivo$idioma == "es"),
  sin_respuestas = all(is.na(vivo$respuesta_a_id)),
  sin_duplicados = !anyDuplicated(vivo$tweet_id))
#>      idioma_es sin_respuestas sin_duplicados
#>           TRUE           TRUE           TRUE
```

## Resumen

| Quiero… | Consulta |
|----|----|
| Todas las palabras | `inteligencia artificial` |
| Frase exacta | `"inteligencia artificial"` |
| Una u otra | `inflación OR dólar` |
| Excluir una palabra | `"inteligencia artificial" -chatgpt` |
| Un hashtag / varios / uno u otro | `#ismanosetoca` / `#RStats #DataScience` / `#RStats OR #Python` |
| Tweets de una cuenta | `from:JMilei` |
| Respuestas a una cuenta | `to:JMilei` |
| Respuestas de una cuenta a otra | `from:JMilei to:slcaputo` |
| Menciones, sin las propias | `@JMilei -from:JMilei` |
| Un hilo completo | `conversation_id:<id>` |
| Rango de días (inclusivo) | `since = "2026-10-10", until = "2026-10-13"` |
| Franja horaria (UTC) | `since = "2026-10-20 12:00", until = "2026-10-20 12:10"` |
| Posteriores / anteriores a un tweet | `since_id:<id>` / `max_id:<id>` |
| Idioma | `lang:es` |
| Métricas mínimas | `min_faves:1000`, `min_retweets:500`, `min_replies:100` |
| Con media / video / enlaces | `filter:media` / `filter:videos` / `filter:links` |
| Enlaces a un dominio | `url:youtube.com` |
| Solo respuestas / sin respuestas | `filter:replies` / `-filter:replies` |
| Citas | `filter:quote` |
| Destacados / solo media | `product = "Top"` / `product = "Media"` |

No funcionó en las pruebas: `filter:images` (usar `filter:media` y
filtrar por `media_tipo`).
