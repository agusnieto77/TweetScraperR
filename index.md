# TweetScraperR![Logo hexagonal de TweetScraperR](reference/figures/hex-twitterscraper.svg)

### Vision general

Este paquete proporciona funciones para extraer datos de X/Twitter,
incluidos tweets, usuarixs y metadatos asociados, permitiendo realizar
la extracción y manejo de estos datos de manera conveniente en R.
Enfocado en facilitar la recolección de datos para análisis y
visualización, el paquete puede obtener tweets desde la búsqueda de
X/Twitter y está construido sobre rvest, sin utilizar las API de
X/Twitter. Aunque los datos rastreados no son tan limpios como los
obtenidos a través de las API, el costo actual de las API hace que esta
sea una alternativa flexible, gratuita y de código abierto.

This package provides functions to extract data from X/Twitter,
including tweets, users, and associated metadata, allowing for
convenient data extraction and handling in R. Focused on facilitating
data collection for analysis and visualization, the package can obtain
tweets from X/Twitter search and is built on rvest, without using the
X/Twitter APIs. Although the scraped data is not as clean as that
obtained through the APIs, the current cost of the APIs makes this a
flexible, free, and open-source alternative.

### Instalacion de la version en desarrollo

Puedes instalar la versión de desarrollo de TweetScraperR desde
[GitHub](https://github.com/) con:

``` r

# install.packages("devtools")
devtools::install_github("agusnieto77/TweetScraperR")
```

### Requisitos

- **Node.js (\>= 18)**: el motor de scraping está basado en Node.js +
  Playwright + stealth. Se instala una sola vez con
  [`installPlaywrightEngine()`](https://agusnieto77.github.io/TweetScraperR/reference/installPlaywrightEngine.md)
  (ver más abajo).
- **Chrome o Chromium**: navegador basado en Chromium requerido por el
  motor de Playwright.
- **Cuenta de X/Twitter**: necesaria para las funciones que requieren
  autenticación.
- **Variables de entorno**:
  - `OPENAI_API_KEY`: opcional, solo para las funciones de análisis
    ([`getTweetsSentiments()`](https://agusnieto77.github.io/TweetScraperR/reference/getTweetsSentiments.md)
    y
    [`getTweetsImagesAnalysis()`](https://agusnieto77.github.io/TweetScraperR/reference/getTweetsImagesAnalysis.md)).
  - `XQUIK_API_KEY`: opcional, solo para
    [`getTweetsXquikSearch()`](https://agusnieto77.github.io/TweetScraperR/reference/getTweetsXquikSearch.md).

> **Nota:** las variables `TWITTER_USER`/`TWITTER_PASS` (y su *fallback*
> legacy `USER`/`PASS`) y el login automatizado quedaron **deprecados**:
> X bloquea el login por automatización. La autenticación ahora se
> realiza importando la sesión real del navegador con
> [`importSessionX()`](https://agusnieto77.github.io/TweetScraperR/reference/importSessionX.md)
> (ver la sección **Autenticación**).

Más detalles en
[Requisitos.md](https://agusnieto77.github.io/TweetScraperR/Requisitos.md).

### Instalación del motor

El scraping ya no usa `chromote`: corre sobre un motor de **Node.js +
Playwright + stealth**.

- Necesitás **Node.js (\>= 18)** instalado en tu sistema.
- Una sola vez, después de instalar el paquete, ejecutá:

``` r

library(TweetScraperR)

# Instala el motor de Node.js/Playwright (una sola vez)
installPlaywrightEngine()

# Verifica que el motor esté instalado y operativo
checkPlaywrightEngine()
```

### Autenticación

X bloquea el **login automatizado**, por lo que ya no es viable iniciar
sesión desde R con usuario y contraseña. En su lugar, se importa la
**sesión real** de tu navegador y se reutiliza para todas las funciones
de scraping. El flujo es:

1.  **Logueate a mano** en X/Twitter desde tu navegador normal (por
    ejemplo, Chrome).
2.  **Copiá las cookies** `auth_token` y `ct0` del dominio `x.com`. Abrí
    las herramientas de desarrollo (DevTools, `F12`) → pestaña
    **Application** (o **Storage**) → **Cookies** → `https://x.com`, y
    copiá los valores de `auth_token` y `ct0`.
3.  **Importá la sesión** en R con
    [`importSessionX()`](https://agusnieto77.github.io/TweetScraperR/reference/importSessionX.md):

``` r

library(TweetScraperR)

importSessionX(
  auth_token = "TU_AUTH_TOKEN",
  ct0        = "TU_CT0"
)
```

A partir de ese momento, **todas las funciones** de scraping reutilizan
esa sesión (persistida como `storageState`) sin necesidad de volver a
loguearte.

> **Las cookies expiran.** Cuando la sesión deje de funcionar, volvé a
> copiar `auth_token` y `ct0` desde el navegador y reimportalas con
> [`importSessionX()`](https://agusnieto77.github.io/TweetScraperR/reference/importSessionX.md).

### Scraping vía API GraphQL/JSON (experimental)

Además del scraping por HTML, el paquete incorpora una familia de
funciones `*API()` que consultan la **API GraphQL interna de X** y
devuelven datos estructurados directamente del JSON (texto completo sin
truncar, fecha exacta y métricas: respuestas, retweets, citas, me gusta
y vistas), sin selectores CSS frágiles. Todas reusan la sesión importada
con
[`importSessionX()`](https://agusnieto77.github.io/TweetScraperR/reference/importSessionX.md).

| Función | Qué recupera |
|----|----|
| [`getUserTweetsAPI()`](https://agusnieto77.github.io/TweetScraperR/reference/getUserTweetsAPI.md) | Timeline de unx usuarix |
| [`getTweetsTimelinesAPI()`](https://agusnieto77.github.io/TweetScraperR/reference/getTweetsTimelinesAPI.md) | Timeline **combinado** de varias cuentas |
| [`getTweetsSearchAPI()`](https://agusnieto77.github.io/TweetScraperR/reference/getTweetsSearchAPI.md) | Búsqueda (`product = "Latest"/"Top"/"Media"`) |
| [`getTweetsRepliesAPI()`](https://agusnieto77.github.io/TweetScraperR/reference/getTweetsRepliesAPI.md) | Tweet y sus respuestas (hilo) |
| [`getTweetsDataAPI()`](https://agusnieto77.github.io/TweetScraperR/reference/getTweetsDataAPI.md) | Datos de tweets a partir de sus URLs |
| [`getUserMediaAPI()`](https://agusnieto77.github.io/TweetScraperR/reference/getUserMediaAPI.md) | Tweets con media (fotos/videos) de unx usuarix |
| [`getTweetsRetweetsAPI()`](https://agusnieto77.github.io/TweetScraperR/reference/getTweetsRetweetsAPI.md) | Usuarixs que repostearon un tweet |
| [`getUserFollowersAPI()`](https://agusnieto77.github.io/TweetScraperR/reference/getUserFollowersAPI.md) | Seguidorxs de unx usuarix |
| [`getUserFollowingAPI()`](https://agusnieto77.github.io/TweetScraperR/reference/getUserFollowingAPI.md) | Cuentas que sigue unx usuarix |
| [`getUsersDataAPI()`](https://agusnieto77.github.io/TweetScraperR/reference/getUsersDataAPI.md) | Datos de perfil de usuarixs |

Las funciones de tweets devuelven un `tibble` rico: texto completo,
fecha, idioma, métricas (respuestas/retweets/citas/me gusta/vistas), y
list-columns `media`, `hashtags`, `menciones`, `urls_externas` y
`emoticones` — listo para analizar con
[`plotTime()`](https://agusnieto77.github.io/TweetScraperR/reference/plotTime.md),
[`plotWords()`](https://agusnieto77.github.io/TweetScraperR/reference/plotWords.md),
[`plotEmojis()`](https://agusnieto77.github.io/TweetScraperR/reference/plotEmojis.md)
o
[`getTweetsSentiments()`](https://agusnieto77.github.io/TweetScraperR/reference/getTweetsSentiments.md).

``` r

library(TweetScraperR)
importSessionX(auth_token = "tu_auth_token", ct0 = "tu_ct0")
tw <- getTweetsSearchAPI("#RStats", n_tweets = 100, product = "Latest")
```

### Uso responsable / Aviso legal

- El scraping autenticado de X/Twitter puede violar sus [Términos de
  Servicio](https://x.com/es/tos) y derivar en la **suspensión de la
  cuenta** utilizada. Usalo bajo tu propia responsabilidad.
- El contenido recolectado está sujeto a los derechos de X/Twitter y de
  lxs autorxs de los tweets; su almacenamiento y redistribución pueden
  estar limitados por esos derechos y por la normativa de protección de
  datos aplicable.
- [`getTweetsSentiments()`](https://agusnieto77.github.io/TweetScraperR/reference/getTweetsSentiments.md)
  y
  [`getTweetsImagesAnalysis()`](https://agusnieto77.github.io/TweetScraperR/reference/getTweetsImagesAnalysis.md)
  **envían los datos recolectados (textos e imágenes de terceros) a la
  API de OpenAI**.
- Se recomienda usar una **cuenta dedicada de investigación** (no tu
  cuenta personal) y respetar los marcos éticos de investigación de tu
  institución.

### Funciones

| Nombre | Ciclo | Descripción |
|:---|:---|:---|
| [`checkPlaywrightEngine()`](https://agusnieto77.github.io/TweetScraperR/reference/checkPlaywrightEngine.md) | ![](https://lifecycle.r-lib.org/articles/figures/lifecycle-experimental.svg) | Verifica que el motor de Node.js/Playwright esté instalado y operativo. |
| [`closeTimeline()`](https://agusnieto77.github.io/TweetScraperR/reference/closeTimeline.md) | ![](https://lifecycle.r-lib.org/articles/figures/lifecycle-superseded.svg) | **Deprecada** (login por pasos). Cierre de Timeline. |
| [`closeTwitter()`](https://agusnieto77.github.io/TweetScraperR/reference/closeTwitter.md) | ![](https://lifecycle.r-lib.org/articles/figures/lifecycle-superseded.svg) | **Deprecada** (login por pasos). Cierre de sesión. |
| [`extractTweetsData()`](https://agusnieto77.github.io/TweetScraperR/reference/extractTweetsData.md) | ![](https://lifecycle.r-lib.org/articles/figures/lifecycle-experimental.svg) | Extrae información relevante de tweets almacenados localmente. |
| [`getScrollExtract()`](https://agusnieto77.github.io/TweetScraperR/reference/getScrollExtract.md) | ![](https://lifecycle.r-lib.org/articles/figures/lifecycle-experimental.svg) | Scrolea y extrae tweets. |
| [`getScrollExtractUrls()`](https://agusnieto77.github.io/TweetScraperR/reference/getScrollExtractUrls.md) | ![](https://lifecycle.r-lib.org/articles/figures/lifecycle-experimental.svg) | Scrolea y extrae URLs de tweets. |
| [`getTweetsCites()`](https://agusnieto77.github.io/TweetScraperR/reference/getTweetsCites.md) | ![](https://lifecycle.r-lib.org/articles/figures/lifecycle-experimental.svg) | Recupera las citas de un tweet a partir de su URL. |
| [`getTweetsData()`](https://agusnieto77.github.io/TweetScraperR/reference/getTweetsData.md) | ![](https://lifecycle.r-lib.org/articles/figures/lifecycle-experimental.svg) | Recupera datos de tweets a partir de URLs. |
| [`getTweetsData2()`](https://agusnieto77.github.io/TweetScraperR/reference/getTweetsData2.md) | ![](https://lifecycle.r-lib.org/articles/figures/lifecycle-experimental.svg) | Recupera datos de tweets a partir de URLs. |
| [`getTweetsFullSearch()`](https://agusnieto77.github.io/TweetScraperR/reference/getTweetsFullSearch.md) | ![](https://lifecycle.r-lib.org/articles/figures/lifecycle-experimental.svg) | Recupera tweets desde la búsqueda avanzada. |
| [`getTweetsHashtags()`](https://agusnieto77.github.io/TweetScraperR/reference/getTweetsHashtags.md) | ![](https://lifecycle.r-lib.org/articles/figures/lifecycle-experimental.svg) | Recupera los hashtags de la columna ‘texto’. |
| [`getTweetsHistoricalHashtag()`](https://agusnieto77.github.io/TweetScraperR/reference/getTweetsHistoricalHashtag.md) | ![](https://lifecycle.r-lib.org/articles/figures/lifecycle-experimental.svg) | Recupera tweets históricos con un hashtag específico. |
| [`getTweetsHistoricalHashtagFor()`](https://agusnieto77.github.io/TweetScraperR/reference/getTweetsHistoricalHashtagFor.md) | ![](https://lifecycle.r-lib.org/articles/figures/lifecycle-experimental.svg) | Recupera tweets históricos con un hashtag específico en un ciclo `for`. |
| [`getTweetsHistoricalSearch()`](https://agusnieto77.github.io/TweetScraperR/reference/getTweetsHistoricalSearch.md) | ![](https://lifecycle.r-lib.org/articles/figures/lifecycle-experimental.svg) | Recupera tweets históricos con un término específico. |
| [`getTweetsHistoricalSearchFor()`](https://agusnieto77.github.io/TweetScraperR/reference/getTweetsHistoricalSearchFor.md) | ![](https://lifecycle.r-lib.org/articles/figures/lifecycle-experimental.svg) | Recupera tweets históricos con un término específico en un ciclo `for`. |
| [`getTweetsHistoricalTimeline()`](https://agusnieto77.github.io/TweetScraperR/reference/getTweetsHistoricalTimeline.md) | ![](https://lifecycle.r-lib.org/articles/figures/lifecycle-experimental.svg) | Recupera tweets históricos de un timeline. |
| [`getTweetsHistoricalTimelineFor()`](https://agusnieto77.github.io/TweetScraperR/reference/getTweetsHistoricalTimelineFor.md) | ![](https://lifecycle.r-lib.org/articles/figures/lifecycle-experimental.svg) | Recupera tweets históricos de un timeline en un ciclo `for`. |
| [`getTweetsImages()`](https://agusnieto77.github.io/TweetScraperR/reference/getTweetsImages.md) | ![](https://lifecycle.r-lib.org/articles/figures/lifecycle-experimental.svg) | Descarga las imágenes posteadas en los tweets. |
| [`getTweetsImagesAnalysis()`](https://agusnieto77.github.io/TweetScraperR/reference/getTweetsImagesAnalysis.md) | ![](https://lifecycle.r-lib.org/articles/figures/lifecycle-experimental.svg) | Analiza las imágenes posteadas en los tweets. |
| [`getTweetsReplies()`](https://agusnieto77.github.io/TweetScraperR/reference/getTweetsReplies.md) | ![](https://lifecycle.r-lib.org/articles/figures/lifecycle-experimental.svg) | Recupera las respuesta a un tweet desde su URL. |
| [`getTweetsRetweets()`](https://agusnieto77.github.io/TweetScraperR/reference/getTweetsRetweets.md) | ![](https://lifecycle.r-lib.org/articles/figures/lifecycle-experimental.svg) | Recupera los usuarios que rt un tweet desde su URL. |
| [`getTweetsSearchStreaming()`](https://agusnieto77.github.io/TweetScraperR/reference/getTweetsSearchStreaming.md) | ![](https://lifecycle.r-lib.org/articles/figures/lifecycle-experimental.svg) | Recupera tweets en tiempo real. |
| [`getTweetsSearchStreaming2()`](https://agusnieto77.github.io/TweetScraperR/reference/getTweetsSearchStreaming2.md) | ![](https://lifecycle.r-lib.org/articles/figures/lifecycle-experimental.svg) | Recupera tweets en tiempo real. |
| [`getTweetsSearchStreamingFor()`](https://agusnieto77.github.io/TweetScraperR/reference/getTweetsSearchStreamingFor.md) | ![](https://lifecycle.r-lib.org/articles/figures/lifecycle-experimental.svg) | Itera la recuperación de tweets en tiempo real. |
| [`getTweetsSearchStreamingFor2()`](https://agusnieto77.github.io/TweetScraperR/reference/getTweetsSearchStreamingFor2.md) | ![](https://lifecycle.r-lib.org/articles/figures/lifecycle-experimental.svg) | Itera la recuperación de tweets en tiempo real. |
| [`getTweetsSentiments()`](https://agusnieto77.github.io/TweetScraperR/reference/getTweetsSentiments.md) | ![](https://lifecycle.r-lib.org/articles/figures/lifecycle-experimental.svg) | Analizador de sentimientos. |
| [`getTweetsTimeline()`](https://agusnieto77.github.io/TweetScraperR/reference/getTweetsTimeline.md) | ![](https://lifecycle.r-lib.org/articles/figures/lifecycle-experimental.svg) | Recupera tweets de un timeline. |
| [`getTweetsTimelineFor()`](https://agusnieto77.github.io/TweetScraperR/reference/getTweetsTimelineFor.md) | ![](https://lifecycle.r-lib.org/articles/figures/lifecycle-experimental.svg) | Recupera tweets de múltiples timelines en un ciclo `for`. |
| [`getTweetsXquikSearch()`](https://agusnieto77.github.io/TweetScraperR/reference/getTweetsXquikSearch.md) | ![](https://lifecycle.r-lib.org/articles/figures/lifecycle-experimental.svg) | Recupera tweets vía la API de Xquik (servicio externo de pago de xquik.com, requiere `XQUIK_API_KEY`). |
| [`getUrlsHistoricalTimeline()`](https://agusnieto77.github.io/TweetScraperR/reference/getUrlsHistoricalTimeline.md) | ![](https://lifecycle.r-lib.org/articles/figures/lifecycle-experimental.svg) | Recupera URLs de tweets históricos de un timeline. |
| [`getUrlsSearchStreaming()`](https://agusnieto77.github.io/TweetScraperR/reference/getUrlsSearchStreaming.md) | ![](https://lifecycle.r-lib.org/articles/figures/lifecycle-experimental.svg) | Recupera URLs de tweets en tiempo real. |
| [`getUrlsTweetsCites()`](https://agusnieto77.github.io/TweetScraperR/reference/getUrlsTweetsCites.md) | ![](https://lifecycle.r-lib.org/articles/figures/lifecycle-experimental.svg) | Recupera las URLs de las citas de un tweet. |
| [`getUrlsTweetsReplies()`](https://agusnieto77.github.io/TweetScraperR/reference/getUrlsTweetsReplies.md) | ![](https://lifecycle.r-lib.org/articles/figures/lifecycle-experimental.svg) | Recupera las URLs de las respuestas a un tweet. |
| [`getUrlsTweetsSearch()`](https://agusnieto77.github.io/TweetScraperR/reference/getUrlsTweetsSearch.md) | ![](https://lifecycle.r-lib.org/articles/figures/lifecycle-experimental.svg) | Recupera URLs de tweets por búsqueda. |
| [`getUrlsTweetsTimeline()`](https://agusnieto77.github.io/TweetScraperR/reference/getUrlsTweetsTimeline.md) | ![](https://lifecycle.r-lib.org/articles/figures/lifecycle-experimental.svg) | Recupera URLs de tweets de un timeline. |
| [`getUsersData()`](https://agusnieto77.github.io/TweetScraperR/reference/getUsersData.md) | ![](https://lifecycle.r-lib.org/articles/figures/lifecycle-experimental.svg) | Recupera datos de users a partir de URLs. |
| [`getUsersFullData()`](https://agusnieto77.github.io/TweetScraperR/reference/getUsersFullData.md) | ![](https://lifecycle.r-lib.org/articles/figures/lifecycle-experimental.svg) | Recupera datos completos de users a partir de URLs. |
| [`HTMLImgReport()`](https://agusnieto77.github.io/TweetScraperR/reference/HTMLImgReport.md) | ![](https://lifecycle.r-lib.org/articles/figures/lifecycle-experimental.svg) | Crea una visualización HTML interactiva de imágenes analizadas. |
| [`importSessionX()`](https://agusnieto77.github.io/TweetScraperR/reference/importSessionX.md) | ![](https://lifecycle.r-lib.org/articles/figures/lifecycle-experimental.svg) | Importa la sesión real del navegador (cookies `auth_token` y `ct0`) y la persiste como `storageState`. |
| [`installPlaywrightEngine()`](https://agusnieto77.github.io/TweetScraperR/reference/installPlaywrightEngine.md) | ![](https://lifecycle.r-lib.org/articles/figures/lifecycle-experimental.svg) | Instala el motor de Node.js/Playwright (se ejecuta una sola vez). |
| [`loginX()`](https://agusnieto77.github.io/TweetScraperR/reference/loginX.md) | ![](https://lifecycle.r-lib.org/articles/figures/lifecycle-experimental.svg) | Flujo de autenticación basado en el nuevo motor Playwright. |
| [`openTimeline()`](https://agusnieto77.github.io/TweetScraperR/reference/openTimeline.md) | ![](https://lifecycle.r-lib.org/articles/figures/lifecycle-superseded.svg) | **Deprecada** (login por pasos). Accede al Timeline de un/a usuario/a. |
| [`openTwitter()`](https://agusnieto77.github.io/TweetScraperR/reference/openTwitter.md) | ![](https://lifecycle.r-lib.org/articles/figures/lifecycle-superseded.svg) | **Deprecada** (login por pasos). Inicio de sesión. |
| [`passTwitter()`](https://agusnieto77.github.io/TweetScraperR/reference/passTwitter.md) | ![](https://lifecycle.r-lib.org/articles/figures/lifecycle-superseded.svg) | **Deprecada** (login por pasos). Función de login, completa el campo pass. |
| [`plotEmojis()`](https://agusnieto77.github.io/TweetScraperR/reference/plotEmojis.md) | ![](https://lifecycle.r-lib.org/articles/figures/lifecycle-experimental.svg) | Hace un gráfico de barras en base a la columna ‘emoticones’. |
| [`plotEmojisPNG()`](https://agusnieto77.github.io/TweetScraperR/reference/plotEmojisPNG.md) | ![](https://lifecycle.r-lib.org/articles/figures/lifecycle-experimental.svg) | Hace un gráfico de barras en base a la columna ‘emoticones’ con los PNG de los emojis. |
| [`plotTime()`](https://agusnieto77.github.io/TweetScraperR/reference/plotTime.md) | ![](https://lifecycle.r-lib.org/articles/figures/lifecycle-experimental.svg) | Hace un gráfico de líneas en base a la columna ‘fecha’. |
| [`plotWords()`](https://agusnieto77.github.io/TweetScraperR/reference/plotWords.md) | ![](https://lifecycle.r-lib.org/articles/figures/lifecycle-experimental.svg) | Hace una nube de palabras en base a la columna ‘texto’. |
| [`userTwitter()`](https://agusnieto77.github.io/TweetScraperR/reference/userTwitter.md) | ![](https://lifecycle.r-lib.org/articles/figures/lifecycle-superseded.svg) | **Deprecada** (login por pasos). Función de login, completa el campo user. |

### Uso de las funciones del paquete {TweetScraperR}

``` r

# Cargamos la librería
require(TweetScraperR)

# Con la función getTweetsSearchStreaming() recolectamos en tiempo real los  
# tweets que mencionan el término de búsqueda, en este ejemplo es un hashtag.
# Esta función guarda un rds con los tweets y algunos metadatos.

urls_hashtagRstats <- getTweetsSearchStreaming(search = "#RStats", n_tweets = 20)
```

``` R
#> Inició la recolección de tweets.
#> Finalizó la recolección de tweets.
#> Datos procesados y guardados.
#> Tweets únicos recolectados: 8
```

``` r

urls_hashtagRstats
```

``` R
#> # A tibble: 8 × 6
#>   art_html  fecha               user             tweet url   fecha_captura      
#>   <list>    <dttm>              <chr>            <chr> <chr> <dttm>             
#> 1 <chr [1]> 2024-10-09 13:39:56 @BiochemistTomas "\nW… http… 2024-10-09 10:53:25
#> 2 <chr [1]> 2024-10-09 13:22:23 @RodgersData     "\nA… http… 2024-10-09 10:53:25
#> 3 <chr [1]> 2024-10-09 12:17:43 @rcityviews      "\nI… http… 2024-10-09 10:53:25
#> 4 <chr [1]> 2024-10-09 12:16:37 @d_mykhailyshyna "\nT… http… 2024-10-09 10:53:25
#> 5 <chr [1]> 2024-10-09 12:04:54 @cyberpuck01     "\nC… http… 2024-10-09 10:53:25
#> 6 <chr [1]> 2024-10-09 11:59:31 @leonardohansa   "\nD… http… 2024-10-09 10:53:25
#> 7 <chr [1]> 2024-10-09 11:58:01 @BjnNowak        "\nT… http… 2024-10-09 10:53:25
#> 8 <chr [1]> 2024-10-09 11:57:34 @HackCyber80     "\nC… http… 2024-10-09 10:53:25
```

``` r

# Con la función getTweetsHistoricalHashtag(), recuperamos tweets históricos 
# que contengan el hashtag #rstats y los imprimimos en pantalla

tweets_historicos <- getTweetsHistoricalHashtag("#rstats", n_tweets = 20)
```

``` R
#> Inició la recolección de tweets.
#> Finalizó la recolección de tweets.
#> Procesando datos...
#> Datos procesados y guardados.
#> Tweets únicos recolectados: 34
```

``` r

tweets_historicos
```

``` R
#> # A tibble: 34 × 6
#>    art_html  fecha               user            tweet url   fecha_captura      
#>    <list>    <dttm>              <chr>           <chr> <chr> <dttm>             
#>  1 <chr [1]> 2018-10-29 23:54:40 @gjmount        "\nC… http… 2024-10-09 10:54:12
#>  2 <chr [1]> 2018-10-29 23:53:10 @ahammami0      "\nP… http… 2024-10-09 10:54:12
#>  3 <chr [1]> 2018-10-29 23:49:06 @ChrisTokita    "\nC… http… 2024-10-09 10:54:12
#>  4 <chr [1]> 2018-10-29 23:35:04 @gp_pulipaka    "\nI… http… 2024-10-09 10:54:12
#>  5 <chr [1]> 2018-10-29 23:30:07 @gp_pulipaka    "\nA… http… 2024-10-09 10:54:12
#>  6 <chr [1]> 2018-10-29 23:28:07 @gp_pulipaka    "\nL… http… 2024-10-09 10:54:12
#>  7 <chr [1]> 2018-10-29 23:26:09 @gp_pulipaka    "\nM… http… 2024-10-09 10:54:12
#>  8 <chr [1]> 2018-10-29 23:00:32 @tidyversetwee… "\nG… http… 2024-10-09 10:54:12
#>  9 <chr [1]> 2018-10-29 23:00:31 @tidyversetwee… "\nW… http… 2024-10-09 10:54:12
#> 10 <chr [1]> 2018-10-29 23:00:26 @ProCogia       "\nW… http… 2024-10-09 10:54:12
#> # ℹ 24 more rows
```

``` r

# Ahora con la getTweetsHistoricalTimeline() recuperamos los datos de tweets originales 
# de la cuenta rstatstweet.

timeline_tweets <- getTweetsHistoricalTimeline(username = "rstatstweet", n_tweets = 10, 
                                               since = "2018-10-26", until = "2020-10-30")
```

``` R
#> Inició la recolección de tweets.
#> Finalizó la recolección de tweets.
#> Procesando datos...
#> Datos procesados y guardados.
#> Tweets únicos recolectados: 13
```

``` r

# Imprimimos en pantalla los datos de los tweets recuperados

timeline_tweets
```

``` R
#> # A tibble: 13 × 6
#>    art_html  fecha               user         tweet    url   fecha_captura      
#>    <list>    <dttm>              <chr>        <chr>    <chr> <dttm>             
#>  1 <chr [1]> 2020-09-25 22:12:32 @rstatstweet "I can’… http… 2024-10-09 10:54:36
#>  2 <chr [1]> 2020-09-24 15:58:14 @rstatstweet "Welcom… http… 2024-10-09 10:54:36
#>  3 <chr [1]> 2020-09-24 15:30:13 @rstatstweet "\nI am… http… 2024-10-09 10:54:36
#>  4 <chr [1]> 2020-09-24 15:10:16 @rstatstweet "This i… http… 2024-10-09 10:54:36
#>  5 <chr [1]> 2020-09-24 15:05:32 @rstatstweet "\nThan… http… 2024-10-09 10:54:36
#>  6 <chr [1]> 2020-09-24 13:07:33 @rstatstweet "\nThan… http… 2024-10-09 10:54:36
#>  7 <chr [1]> 2020-09-24 09:11:22 @rstatstweet "That’s… http… 2024-10-09 10:54:36
#>  8 <chr [1]> 2020-09-24 00:28:46 @rstatstweet "I will… http… 2024-10-09 10:54:36
#>  9 <chr [1]> 2020-09-24 00:25:17 @rstatstweet "\nTher… http… 2024-10-09 10:54:36
#> 10 <chr [1]> 2020-09-24 00:21:15 @rstatstweet "\nSo t… http… 2024-10-09 10:54:36
#> 11 <chr [1]> 2020-09-24 00:16:20 @rstatstweet "I was … http… 2024-10-09 10:54:36
#> 12 <chr [1]> 2020-09-24 00:09:42 @rstatstweet "\nThis… http… 2024-10-09 10:54:36
#> 13 <chr [1]> 2020-02-12 01:36:45 @rstatstweet "Happy … http… 2024-10-09 10:54:36
```

``` r

# Ahora con la función getUsersFullData() recuperamos los datos de usuarixs a 
# partir de las URLs de users recuperadas en el objeto tweets_historicos.

users <- unique(gsub("@", "", tweets_historicos$user))
usuarixs <- getUsersFullData(urls_users = paste0("https://x.com/", users))
```

``` R
#> 
#> Terminando el proceso.
#>       
#> Usuarixs recuperados: 25 
#> Usuarixs no recuperados: 0
```

``` r

# Imprimimos en pantalla los datos de lxs users recuperadxs 

dplyr::glimpse(usuarixs)
```

``` R
#> Rows: 25
#> Columns: 13
#> $ fecha_creacion       <dttm> 2014-05-11 11:32:54, 2017-10-11 08:04:19, 2009-0…
#> $ nombre_adicional     <chr> "gjmount", "ahammami0", "ChrisTokita", "gp_pulipa…
#> $ descripcion          <chr> "I teach analytics in modern Excel 📚 O'Reilly Au…
#> $ nombre               <chr> "George Mount", "Abdessalem Hammami", "Chris Toki…
#> $ ubicacion            <chr> "Cleveland, OH", "Joensuu, Suomi", "Los Angeles, …
#> $ identificador        <chr> "2489702532", "918024449194065925", "41155612", "…
#> $ url_imagen           <chr> "https://pbs.twimg.com/profile_images/16538332253…
#> $ url_miniatura        <chr> "https://pbs.twimg.com/profile_images/16538332253…
#> $ seguidorxs           <int> 4674, 125, 1529, 183257, 12025, 1621, 2351, 396, …
#> $ amigxs               <int> 4273, 120, 1880, 20258, 0, 147, 1919, 310, 2505, …
#> $ tweets               <int> 29713, 883, 5653, 92873, 98491, 1545, 1004, 779, …
#> $ url                  <chr> "https://twitter.com/gjmount", "https://twitter.c…
#> $ enlaces_relacionados <chr> "https://t.co/JcWH7Lwy9r, https://stringfestanaly…
```
