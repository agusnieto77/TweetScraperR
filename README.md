# TweetScraperR<img src="man/figures/hex-twitterscraper.svg" align="right" height="320" alt="Logo hexagonal de TweetScraperR"/>

<!-- badges: start -->

[![Project Status: Active – The project has reached a stable, usable state and is being actively developed.](https://www.repostatus.org/badges/latest/active.svg)](https://www.repostatus.org/#active)
[![](https://img.shields.io/badge/version-0.7.0-blue.svg)](https://github.com/agusnieto77/TweetScraperR)
[![pkgdown](https://img.shields.io/badge/docs-pkgdown-blue.svg)](https://agusnieto77.github.io/TweetScraperR/)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](https://cran.r-project.org/web/licenses/MIT)
[![](https://img.shields.io/github/languages/code-size/agusnieto77/TweetScraperR.svg)](https://github.com/agusnieto77/TweetScraperR)
[![](https://img.shields.io/badge/Lifecycle-Experimental-ff7f2a)](https://lifecycle.r-lib.org/articles/stages.html#experimental)
[![](https://img.shields.io/badge/Build%20with-R%20%26%20RStudio-blue?style=plastic)](https://github.com/agusnieto77/TweetScraperR)
[![](https://img.shields.io/badge/TweetScraperR-ready%20to%20use-39c?style=plastic)](https://github.com/agusnieto77/TweetScraperR)

<!-- badges: end -->

### Visión general

`TweetScraperR` recolecta datos de X/Twitter —tweets, usuarixs y
metadatos— para análisis y visualización en R, **sin usar la API oficial
de pago**. Desde la versión **0.5.0**, el scraping corre sobre un motor de
**Node.js + Playwright** y consulta la **API GraphQL interna** de X,
devolviendo datos **estructurados** desde JSON: texto completo (sin
truncar), fecha exacta, métricas (respuestas, retweets, citas, me gusta,
vistas), media, hashtags y menciones. La autenticación se hace importando
la **sesión real de tu navegador** (cookies), ya que X bloquea el login
automatizado. Es una alternativa flexible, gratuita y de código abierto.

`TweetScraperR` collects data from X/Twitter —tweets, users and
metadata— for analysis and visualization in R, **without using the paid
official API**. Since version **0.5.0**, scraping runs on a **Node.js +
Playwright** engine and queries X's **internal GraphQL API**, returning
**structured** data from JSON: full text, exact date, metrics, media,
hashtags and mentions. Authentication works by importing your **real
browser session** (cookies), since X blocks automated login. It is a
flexible, free, and open-source alternative.

### Instalacion de la version en desarrollo

Puedes instalar la versión de desarrollo de TweetScraperR desde
[GitHub](https://github.com/) con:

``` r
# install.packages("pak")
pak::pak("agusnieto77/TweetScraperR")
```

### Requisitos

- **Node.js (>= 18)**: el motor de scraping está basado en Node.js +
  Playwright + stealth. Se instala una sola vez con
  `installPlaywrightEngine()` (ver más abajo).
- **Chrome o Chromium**: navegador basado en Chromium requerido por el
  motor de Playwright.
- **Cuenta de X/Twitter**: necesaria para las funciones que requieren
  autenticación.
- **Variables de entorno**:
  - `OPENAI_API_KEY`: opcional, solo para las funciones de análisis
    (`getTweetsSentiments()` y `getTweetsImagesAnalysis()`).

> **Nota:** las variables `TWITTER_USER`/`TWITTER_PASS` (y su *fallback*
> legacy `USER`/`PASS`) y el login automatizado quedaron **deprecados**: X
> bloquea el login por automatización. La autenticación ahora se realiza
> importando la sesión real del navegador con `importSessionX()` (ver la
> sección **Autenticación**).

Más detalles en [Requisitos.md](Requisitos.md).

### Instalación del motor

El scraping ya no usa `chromote`: corre sobre un motor de **Node.js +
Playwright + stealth**.

- Necesitás **Node.js (>= 18)** instalado en tu sistema.
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
**sesión real** de tu navegador y se reutiliza para todas las funciones de
scraping. El flujo es:

1. **Logueate a mano** en X/Twitter desde tu navegador normal (por ejemplo,
   Chrome).
2. **Copiá las cookies** `auth_token` y `ct0` del dominio `x.com`. Abrí las
   herramientas de desarrollo (DevTools, `F12`) → pestaña **Application** (o
   **Storage**) → **Cookies** → `https://x.com`, y copiá los valores de
   `auth_token` y `ct0`.
3. **Importá la sesión** en R con `importSessionX()`:

``` r
library(TweetScraperR)

importSessionX(
  auth_token = "TU_AUTH_TOKEN",
  ct0        = "TU_CT0"
)
```

A partir de ese momento, **todas las funciones** de scraping reutilizan esa
sesión (persistida como `storageState`) sin necesidad de volver a loguearte.

> **Las cookies expiran.** Cuando la sesión deje de funcionar, volvé a copiar
> `auth_token` y `ct0` desde el navegador y reimportalas con
> `importSessionX()`.

### Scraping vía API GraphQL/JSON

Toda la recolección se hace con la familia de funciones `*API()`: consultan la
**API GraphQL interna de X** y devuelven datos estructurados directamente del
JSON (texto completo sin truncar, fecha exacta y métricas: respuestas,
retweets, citas, me gusta y vistas), sin selectores CSS frágiles. Todas reusan
la sesión importada con `importSessionX()`. Las funciones de scraping por HTML
fueron **eliminadas** en la 0.5.0 (ver el mapeo de reemplazos en el
[NEWS.md](NEWS.md)).

| Función | Qué recupera |
|---|---|
| `getUserTweetsAPI()` | Timeline de unx usuarix |
| `getTweetsTimelinesAPI()` | Timeline **combinado** de varias cuentas |
| `getTweetsSearchAPI()` | Búsqueda (`product = "Latest"/"Top"/"Media"`) |
| `getTweetsRepliesAPI()` | Tweet y sus respuestas (hilo) |
| `getTweetsDataAPI()` | Datos de tweets a partir de sus URLs |
| `getUserMediaAPI()` | Tweets con media (fotos/videos) de unx usuarix |
| `getTweetsRetweetsAPI()` | Usuarixs que repostearon un tweet |
| `getUserFollowersAPI()` | Seguidorxs de unx usuarix |
| `getUserFollowingAPI()` | Cuentas que sigue unx usuarix |
| `getUsersDataAPI()` | Datos de perfil de usuarixs |

Las funciones de tweets devuelven un `tibble` rico: texto completo, fecha,
idioma, métricas (respuestas/retweets/citas/me gusta/vistas), y list-columns
`media`, `hashtags`, `menciones`, `urls_externas` y `emoticones` — listo para
analizar con `plotTime()`, `plotWords()`, `plotEmojis()` o `getTweetsSentiments()`.

``` r
library(TweetScraperR)
importSessionX(auth_token = "tu_auth_token", ct0 = "tu_ct0")
tw <- getTweetsSearchAPI("#RStats", n_tweets = 100, product = "Latest")
```

### Uso conversacional con agentes de IA (Posit Assistant)

`installAgentSkill()` instala una *skill* ([Agent
Skills](https://agentskills.io)) que le enseña a un agente de IA a usar
TweetScraperR: puesta a punto, qué función corresponde a cada pedido,
columnas devueltas, recetas y solución de errores. Está pensada para
**Posit Assistant** (RStudio y Positron), que la carga sola cuando hablás
de X/Twitter o la invocás con `/tweetscraperr`.

``` r
# Posit Assistant, para todos tus proyectos
installAgentSkill()

# También para Claude Code y clientes de .agents/skills, solo en este proyecto
installAgentSkill(c("posit", "claude", "agents"), scope = "project")

# Tras actualizar el paquete
installAgentSkill(overwrite = TRUE)
```

Después, en una conversación nueva del asistente: *"traeme los últimos 200
tweets de @NASA y graficá su actividad por día"*.

### Uso responsable / Aviso legal

- El scraping autenticado de X/Twitter puede violar sus [Términos de
  Servicio](https://x.com/es/tos) y derivar en la **suspensión de la
  cuenta** utilizada. Usalo bajo tu propia responsabilidad.
- El contenido recolectado está sujeto a los derechos de X/Twitter y de
  lxs autorxs de los tweets; su almacenamiento y redistribución pueden
  estar limitados por esos derechos y por la normativa de protección de
  datos aplicable.
- `getTweetsSentiments()` y `getTweetsImagesAnalysis()` **envían los
  datos recolectados (textos e imágenes de terceros) a la API de
  OpenAI**.
- Se recomienda usar una **cuenta dedicada de investigación** (no tu
  cuenta personal) y respetar los marcos éticos de investigación de tu
  institución.

### Funciones

El **listado completo de funciones**, organizado por categoría y con su
estado de ciclo de vida, está en la referencia del sitio de documentación:

👉 <https://agusnieto77.github.io/TweetScraperR/reference/>

La recolección se hace con la familia `*API()` (ver la tabla de arriba). Las
funciones de scraping por **HTML** (`getTweetsTimeline()`,
`getTweetsHistoricalSearch()`, `getTweetsData()`, `getUsersData()`, la
familia `getUrls*()`, las variantes `*For()`, la gestión de sesiones
`openTwitter()`/`closeTwitter()`, etc.) fueron **eliminadas** en la 0.5.0
en favor de sus equivalentes `*API()` sobre el motor Node/Playwright; el
mapeo de reemplazos está en el [NEWS.md](NEWS.md).

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
(21 columnas), listo para analizar. Salida real (`getUserTweetsAPI("NASA",
n_tweets = 10)`, capturada el 2026-10-18):

``` r
dplyr::glimpse(timeline)
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

Y los perfiles (`getUsersDataAPI("NASA")`, misma fecha):

``` r
#> # A tibble: 1 × 15
#>   user  nombre user_id  descripcion        seguidores siguiendo tweets
#>   <chr> <chr>  <chr>    <chr>                   <int>     <int>  <int>
#> 1 @NASA NASA   11348282 Making the seemin…  92323271       115  74438
#> # ℹ 8 more variables: favoritos <int>, verificado <lgl>, ubicacion <chr>,
#> #   sitio_web <chr>, imagen_perfil <chr>, banner <chr>,
#> #   fecha_creacion <dttm>, url <chr>
```

Y analizás/visualizás directo, sin renombrar columnas:

``` r
plotTime(tweets)                    # serie temporal (columna fecha)
plotWords(tweets)                   # nube de palabras (columna texto)
plotEmojis(tweets)                  # ranking de emojis (columna emoticones)
getTweetsSentiments(tweets$texto)   # análisis de sentimiento (vía OpenAI)
```
