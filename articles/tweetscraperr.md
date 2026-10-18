# Scraping de X/Twitter con TweetScraperR

`TweetScraperR` recolecta datos de X/Twitter (tweets, usuarixs y
metadatos) para análisis y visualización. Esta viñeta describe el
**flujo recomendado**, basado en consultas a la API GraphQL interna de X
(datos estructurados, sin selectores HTML frágiles). Las salidas que se
muestran son **capturas reales** obtenidas el 2026-10-18.

> **Nota de versiones:** desde la **0.5.0** el paquete expone una
> superficie única de 24 funciones sobre el motor Node.js/Playwright.
> Las funciones de scraping por HTML (`getTweetsTimeline()`,
> `getTweetsData()`, `getUsersData()`, la familia `getUrls*()`, etc.)
> fueron **eliminadas**; el mapa de reemplazos está en el `NEWS.md`.

## 1. Instalar el motor (una vez por máquina)

El motor de scraping corre sobre **Node.js (\>= 18) + Playwright +
stealth**. Se instala una sola vez en un caché persistente del usuario
(sobrevive a reinstalaciones del paquete):

``` r

library(TweetScraperR)

# Instala el motor de Node.js/Playwright (una sola vez por máquina).
installPlaywrightEngine()

# Verifica que el motor quedó operativo.
checkPlaywrightEngine()
#> Motor Playwright OK — Playwright 1.64.1 | Node v24.20.0
```

## 2. Importar tu sesión

X bloquea el login automatizado (detecta el navegador por
*fingerprint*). Por eso la sesión se importa desde **tu navegador
normal**, donde ya estás logueadx:

1.  Iniciá sesión en <https://x.com> en tu navegador habitual.
2.  Abrí las *DevTools* (F12) → pestaña **Application / Almacenamiento**
    → **Cookies** → `https://x.com`.
3.  Copiá los valores de las cookies **`auth_token`** y **`ct0`**.
4.  Importalos:

``` r

importSessionX(auth_token = "tu_auth_token", ct0 = "tu_ct0")
```

La sesión queda guardada en disco y **todas las funciones la reusan**
sin volver a loguearse. Cuando las cookies expiren, repetí el paso para
reimportarlas.

## 3. Recolectar datos (funciones `*API()`)

### 3.1 Timeline de unx usuarix

``` r

tl <- getUserTweetsAPI("NASA", n_tweets = 10)
#> Recolectando timeline de @NASA...
#> Tweets únicos recolectados: 10
#> Datos procesados y guardados.
```

Cada función de tweets devuelve el mismo `tibble` de **21 columnas**:

``` r

dplyr::glimpse(tl)
#> Rows: 10
#> Columns: 21
#> $ fecha           <dttm> 2026-10-16 19:42:20, 2026-10-16 13:53:53, ...
#> $ user            <chr> "@NASA", "@NASA", "@NASA", "@NASA", ...
#> $ texto           <chr> "The aircraft lineup just keeps getting bigger. ✈️..."
#> $ idioma          <chr> "en", "en", "en", "en", ...
#> $ respuestas      <int> 124, 141, 76, 85, 91, 165, 167, 90, 259, 120
#> $ retweets        <int> 194, 242, 157, 164, 236, 384, 377, 137, 938, 198
#> $ citas           <int> 21, 16, 10, 16, 12, 59, 725, 15, 93, 13
#> $ megustas        <int> 1407, 1867, 1111, 1065, 2105, 2227, 2662, ...
#> $ views           <int> 329251, 958698, 376585, 460454, 375943, ...
#> $ emoticones      <list> "✈", <>, <>, <>, <>, <>, "🛠", <>, <>, "✈"
#> $ hashtags        <list> <>, <>, <>, <>, <>, <>, <>, <>, <>, <>
#> $ menciones       <list> "NASAKennedy", <>, "JAXA_en", <"NASAJohnson"...>
#> $ urls_externas   <list> "https://www.nasa.gov/maxpower/", ...
#> $ media           <list> "https://video.twimg.com/amplify_video/...", ...
#> $ media_tipo      <list> "video", "photo", "photo", <>, "photo", ...
#> $ es_retweet      <lgl> FALSE, FALSE, FALSE, FALSE, ...
#> $ es_cita         <lgl> FALSE, FALSE, FALSE, FALSE, ...
#> $ tweet_citado_id <chr> NA, NA, NA, NA, ...
#> $ conversation_id <chr> "2111180963661435219", "2111093273800356092", ...
#> $ url             <chr> "https://x.com/NASA/status/2111180963661435219", ...
#> $ tweet_id        <chr> "2111180963661435219", "2111093273800356092", ...
```

### 3.2 Timelines combinados (curaduría de investigación)

``` r

combinado <- getTweetsTimelinesAPI(
  c("sanchezcastejon", "agusnieto77"),
  n_tweets = 40
)
#> Recolectando timelines de 2 cuentas...
#>   @sanchezcastejon: 40 tweets
#>   @agusnieto77: 40 tweets
#> Total combinado: 80 tweets de 2 cuentas.
#> Datos procesados y guardados.
```

### 3.3 Búsqueda (`Latest` / `Top` / `Media`) con rango de fechas

La búsqueda soporta los operadores de X (`from:`, `lang:`, …) y los
argumentos `since`/`until` para acotar por fechas (formato
`"YYYY-MM-DD"` o `"YYYY-MM-DD_HH:MM:SS"`):

``` r

top <- getTweetsSearchAPI("Milei", n_tweets = 10, product = "Top")
#> Buscando: Milei (Top)
#> Tweets únicos recolectados: 10
#> Datos procesados y guardados.
#> # A tibble: 10 × 21
#>   user           fecha               megustas retweets
#>   <chr>          <dttm>                 <int>    <int>
#> 1 @JMilei        2026-10-15 17:54:43    11639     1558
#> 2 @JMilei        2026-10-07 13:04:03    32757     4481
#> 3 @Gianferreyra_ 2026-10-17 03:26:10    17298     1028
#> 4 @PinkuDraw     2026-10-16 04:49:39       64        9
#> 5 @JMilei        2026-10-16 21:08:15     5639      778

rango <- getTweetsSearchAPI(
  "Feijoo", n_tweets = 20,
  since = "2026-10-17", until = "2026-10-18"
)
#> Buscando: Feijoo since:2026-10-17 until:2026-10-18 (Latest)
#> Tweets únicos recolectados: 20
```

### 3.4 Respuestas / hilo de un tweet

``` r

hilo <- getTweetsRepliesAPI(
  "https://x.com/sanchezcastejon/status/2111426246517072370",
  n_tweets = 8
)
#> Recolectando respuestas de: https://x.com/sanchezcastejon/status/2111426246517072370
#> Tweets únicos recolectados: 8
#> Datos procesados y guardados.
#> # A tibble: 8 × 21 (primeras 3 filas)
#>   user             fecha               texto
#>   <chr>            <dttm>              <chr>
#> 1 @sanchezcastejon 2026-10-17 11:57:00 "Feijóo es todo un personaje.\n\nDice que va..."
#> 2 @Komainu_Ronin   2026-10-17 14:22:43 "@sanchezcastejon Habló, el galgo de Paiporta..."
#> 3 @romanocisneros  2026-10-17 12:44:36 "@sanchezcastejon Si,sigue así chaval..."
```

La primera fila es siempre el tweet focal; el resto son sus respuestas.

### 3.5 Datos de tweets a partir de sus URLs

``` r

datos <- getTweetsDataAPI(c(
  "https://x.com/sanchezcastejon/status/2111426246517072370"
))
#> Procesado: https://x.com/sanchezcastejon/status/2111426246517072370
#> Datos procesados y guardados.
```

### 3.6 Media (fotos/videos) de unx usuarix

``` r

media <- getUserMediaAPI("sanchezcastejon", n_tweets = 15)
#> Recolectando media de @sanchezcastejon...
#> Tweets de media recolectados: 15
#> Datos procesados y guardados.
```

Las columnas `media` (URLs) y `media_tipo` (`"photo"` / `"video"`)
describen cada adjunto.

### 3.7 Redes de usuarixs

``` r

seguidores <- getUserFollowersAPI("agusnieto77", n_users = 10)
siguiendo  <- getUserFollowingAPI("sanchezcastejon", n_users = 10)
retweeters <- getTweetsRetweetsAPI(
  "https://x.com/sanchezcastejon/status/2111426246517072370",
  n_users = 10
)
```

### 3.8 Datos de perfil

``` r

perfiles <- getUsersDataAPI("NASA")
#> Datos procesados y guardados.
#> # A tibble: 1 × 15
#>   user  nombre user_id  descripcion        seguidores siguiendo tweets
#>   <chr> <chr>  <chr>    <chr>                   <int>     <int>  <int>
#> 1 @NASA NASA   11348282 Making the seemin…  92323271       115  74438
#> # ℹ 8 more variables: favoritos <int>, verificado <lgl>, ubicacion <chr>,
#> #   sitio_web <chr>, imagen_perfil <chr>, banner <chr>,
#> #   fecha_creacion <dttm>, url <chr>
```

Por defecto cada función guarda un archivo `.rds` con marca de tiempo en
el directorio de trabajo (`save = TRUE`); pasá `save = FALSE` para no
guardar.

## 4. Visualización y análisis

Las columnas tienen nombres estables, así que el post-procesamiento va
directo, sin renombrar nada:

``` r

plotTime(tl)                  # serie temporal (columna fecha)
plotWords(tl, max_words = 50) # nube de palabras (columna texto)
plotEmojis(tl)                # ranking de emojis (columna emoticones)
getTweetsHashtags(tl)         # hashtags detectados (columna hashtags)
```

Para análisis con IA (requieren `OPENAI_API_KEY`):

``` r

getTweetsSentiments(tl$texto)      # sentimiento de cada texto
getTweetsImagesAnalysis(tl$media)  # qué muestran las imágenes
```

## 5. Datos legacy ya guardados

Si tenés `.rds` viejos con HTML crudo (columna `art_html`),
[`extractTweetsData()`](https://agusnieto77.github.io/TweetScraperR/reference/extractTweetsData.md)
los sigue procesando sin necesidad de volver a scrapear:

``` r

viejos <- readRDS("tweets_2024.rds")
procesados <- extractTweetsData(viejos)
```

## Uso responsable

El scraping autenticado de X puede violar sus Términos de Servicio y
derivar en la suspensión de la cuenta. El contenido recolectado está
sujeto a los derechos de X y de sus autores. Usá cuentas dedicadas de
investigación y respetá la normativa de protección de datos aplicable.
