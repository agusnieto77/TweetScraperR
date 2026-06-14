# TweetScraperR![Logo hexagonal de TweetScraperR](reference/figures/hex-twitterscraper.svg)

### Visión general

`TweetScraperR` recolecta datos de X/Twitter —tweets, usuarixs y
metadatos— para análisis y visualización en R, **sin usar la API oficial
de pago**. Desde la versión **0.4.0**, el scraping corre sobre un motor
de **Node.js + Playwright** y consulta la **API GraphQL interna** de X,
devolviendo datos **estructurados** desde JSON: texto completo (sin
truncar), fecha exacta, métricas (respuestas, retweets, citas, me gusta,
vistas), media, hashtags y menciones. La autenticación se hace
importando la **sesión real de tu navegador** (cookies), ya que X
bloquea el login automatizado. Es una alternativa flexible, gratuita y
de código abierto.

`TweetScraperR` collects data from X/Twitter —tweets, users and
metadata— for analysis and visualization in R, **without using the paid
official API**. Since version **0.4.0**, scraping runs on a **Node.js +
Playwright** engine and queries X’s **internal GraphQL API**, returning
**structured** data from JSON: full text, exact date, metrics, media,
hashtags and mentions. Authentication works by importing your **real
browser session** (cookies), since X blocks automated login. It is a
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

### Scraping vía API GraphQL/JSON (recomendado)

La vía **recomendada** es la familia de funciones `*API()`: consultan la
**API GraphQL interna de X** y devuelven datos estructurados
directamente del JSON (texto completo sin truncar, fecha exacta y
métricas: respuestas, retweets, citas, me gusta y vistas), sin
selectores CSS frágiles. Todas reusan la sesión importada con
[`importSessionX()`](https://agusnieto77.github.io/TweetScraperR/reference/importSessionX.md).
Las funciones de scraping por HTML siguen disponibles pero quedaron
**deprecadas** en favor de estas.

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

El **listado completo de funciones**, organizado por categoría y con su
estado de ciclo de vida, está en la referencia del sitio de
documentación:

👉 <https://agusnieto77.github.io/TweetScraperR/reference/>

Las recomendadas son la familia `*API()` (ver la tabla de arriba). Las
funciones de scraping por **HTML**
([`getTweetsTimeline()`](https://agusnieto77.github.io/TweetScraperR/reference/getTweetsTimeline.md),
[`getTweetsHistoricalSearch()`](https://agusnieto77.github.io/TweetScraperR/reference/getTweetsHistoricalSearch.md),
[`getTweetsData()`](https://agusnieto77.github.io/TweetScraperR/reference/getTweetsData.md),
[`getUsersData()`](https://agusnieto77.github.io/TweetScraperR/reference/getUsersData.md),
la familia `getUrls*()`, las variantes `*For()`, etc.) quedaron
**deprecadas** en favor de sus equivalentes `*API()`; siguen funcionando
con una advertencia de ciclo de vida.

### Uso del paquete

``` r

require(TweetScraperR)

# 1) Importás tu sesión UNA vez (cookies auth_token y ct0 del navegador)
importSessionX(auth_token = "TU_AUTH_TOKEN", ct0 = "TU_CT0")

# 2) Búsqueda: tweets recientes que mencionan un hashtag
tweets <- getTweetsSearchAPI("#RStats", n_tweets = 100, product = "Latest")

# 3) Timeline de una cuenta
timeline <- getUserTweetsAPI("rstatstweet", n_tweets = 200)

# 4) Timeline COMBINADO de varias cuentas (curaduría de investigación)
combinado <- getTweetsTimelinesAPI(
  c("elravignani", "NucleoIdaes", "BNMMArgentina"),
  n_tweets = 100
)

# 5) Datos de perfil de usuarixs
perfiles <- getUsersDataAPI(c("NASA", "rstatstweet"))
```

Cada función de tweets devuelve un `tibble` con datos **estructurados**
(21 columnas), listo para analizar:

``` r

dplyr::glimpse(tweets)
#> Rows: 100
#> Columns: 21
#> $ fecha           <dttm> 2026-06-13 21:42:13, 2026-06-13 12:10:47, ...
#> $ user            <chr> "@RosanaFerrero", "@aRtsy_package", ...
#> $ texto           <chr> "...texto completo, sin truncar..."
#> $ idioma          <chr> "es", "en", ...
#> $ megustas        <int> 7203, 0, 8221, ...
#> $ retweets        <int> 1194, 323, 1465, ...
#> $ views           <int> 470857, 34, 378665, ...
#> $ media           <list> ["https://pbs.twimg.com/media/...jpg"], [], ...
#> $ hashtags        <list> ["RStats"], [], ...
#> $ menciones       <list> ["Space_Station", "SpaceX"], [], ...
#> $ urls_externas   <list> ["https://go.nasa.gov/..."], [], ...
#> $ emoticones      <list> ["✈"], [], ...
#> # ... respuestas, citas, es_retweet, es_cita, tweet_citado_id,
#> #     media_tipo, conversation_id, url, tweet_id
```

Y analizás/visualizás directo, sin renombrar columnas:

``` r

plotTime(tweets)                    # serie temporal (columna fecha)
plotWords(tweets)                   # nube de palabras (columna texto)
plotEmojis(tweets)                  # ranking de emojis (columna emoticones)
getTweetsSentiments(tweets$texto)   # análisis de sentimiento (vía OpenAI)
```
