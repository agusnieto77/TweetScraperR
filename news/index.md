# Changelog

## TweetScraperR 0.4.0

### Nueva capa de scraping vía API GraphQL/JSON (experimental)

- Familia de funciones `*API()` que consultan la **API GraphQL interna
  de X** y devuelven datos estructurados desde JSON (texto completo sin
  truncar, fecha exacta y métricas: respuestas, retweets, citas, me
  gusta, vistas), en lugar de parsear HTML con selectores CSS frágiles.
  Todas reusan la sesión importada con
  [`importSessionX()`](https://agusnieto77.github.io/TweetScraperR/reference/importSessionX.md).
  - [`getUserTweetsAPI()`](https://agusnieto77.github.io/TweetScraperR/reference/getUserTweetsAPI.md)
    — timeline de unx usuarix.
  - [`getTweetsSearchAPI()`](https://agusnieto77.github.io/TweetScraperR/reference/getTweetsSearchAPI.md)
    — búsqueda (con `product` Latest/Top/Media).
  - [`getTweetsRepliesAPI()`](https://agusnieto77.github.io/TweetScraperR/reference/getTweetsRepliesAPI.md)
    — tweet y sus respuestas (hilo).
  - [`getTweetsRetweetsAPI()`](https://agusnieto77.github.io/TweetScraperR/reference/getTweetsRetweetsAPI.md)
    — usuarixs que repostearon un tweet.
  - [`getUserFollowersAPI()`](https://agusnieto77.github.io/TweetScraperR/reference/getUserFollowersAPI.md)
    /
    [`getUserFollowingAPI()`](https://agusnieto77.github.io/TweetScraperR/reference/getUserFollowingAPI.md)
    — redes de usuarixs.
  - [`getUsersDataAPI()`](https://agusnieto77.github.io/TweetScraperR/reference/getUsersDataAPI.md)
    — datos de perfil.
  - [`getUserMediaAPI()`](https://agusnieto77.github.io/TweetScraperR/reference/getUserMediaAPI.md)
    — tweets con media de unx usuarix.
  - [`getTweetsDataAPI()`](https://agusnieto77.github.io/TweetScraperR/reference/getTweetsDataAPI.md)
    — datos de tweets a partir de sus URLs (reemplazo de
    [`getTweetsData()`](https://agusnieto77.github.io/TweetScraperR/reference/getTweetsData.md)).
  - [`getTweetsTimelinesAPI()`](https://agusnieto77.github.io/TweetScraperR/reference/getTweetsTimelinesAPI.md)
    — timeline combinado de varias cuentas (sin necesitar una Lista de
    X).
- Internamente, los endpoints que exigen el header anti-bot
  `x-client-transaction-id` (p.ej. búsqueda, replies, followers) se
  resuelven “cosechando” las respuestas JSON que dispara la propia app
  de X al navegar la página (la app genera ese header de forma nativa),
  evitando reproducirlo.

### Deprecaciones y documentación

- Las funciones de scraping por **HTML**
  ([`getTweetsTimeline()`](https://agusnieto77.github.io/TweetScraperR/reference/getTweetsTimeline.md),
  [`getTweetsHistoricalSearch()`](https://agusnieto77.github.io/TweetScraperR/reference/getTweetsHistoricalSearch.md),
  [`getTweetsData()`](https://agusnieto77.github.io/TweetScraperR/reference/getTweetsData.md),
  [`getUsersData()`](https://agusnieto77.github.io/TweetScraperR/reference/getUsersData.md),
  la familia `getUrls*()`, las variantes `*For()`, etc.) quedan
  **deprecadas** en favor de sus equivalentes `*API()`, más robustas.
  Siguen funcionando pero emiten una advertencia de ciclo de vida.
- Nueva **viñeta** “Scraping de X/Twitter con TweetScraperR” con el
  flujo completo recomendado (instalar el motor, importar la sesión,
  usar las funciones `*API()`).

## TweetScraperR 0.3.0

### Cambio mayor: nuevo motor de scraping (Node.js + Playwright + stealth)

- El scraping ya no se realiza con `chromote`. Se incorporó un nuevo
  motor basado en **Node.js + Playwright + stealth** que reemplaza a
  `chromote` para **todo** el scraping del paquete. `chromote` se
  mantiene en `Imports` porque todavía lo usan las funciones de login
  por pasos
  ([`openTwitter()`](https://agusnieto77.github.io/TweetScraperR/reference/openTwitter.md)
  /
  [`closeTwitter()`](https://agusnieto77.github.io/TweetScraperR/reference/closeTwitter.md)).
- El motor de Node.js/Playwright se instala una sola vez con
  [`installPlaywrightEngine()`](https://agusnieto77.github.io/TweetScraperR/reference/installPlaywrightEngine.md)
  y su estado se verifica con
  [`checkPlaywrightEngine()`](https://agusnieto77.github.io/TweetScraperR/reference/checkPlaywrightEngine.md).
  Requiere **Node.js (\>= 18)** y un navegador basado en Chromium.

### Cambio mayor: modelo de sesión por cookies

- El **login automatizado ya no es viable**: X bloquea activamente el
  inicio de sesión vía automatización del navegador. El paquete adopta
  un modelo de **sesión por cookies**.
- Ahora se importa la **sesión real del navegador** con
  `importSessionX(auth_token, ct0)`. La sesión se persiste como
  `storageState` y se **reutiliza para todas** las funciones de
  scraping, sin necesidad de volver a loguearse.
- Las cookies de X expiran; cuando eso ocurre, hay que volver a
  copiarlas desde el navegador y reimportarlas con
  [`importSessionX()`](https://agusnieto77.github.io/TweetScraperR/reference/importSessionX.md).

### Nuevas funciones exportadas

- [`loginX()`](https://agusnieto77.github.io/TweetScraperR/reference/loginX.md):
  flujo de autenticación basado en el nuevo motor.
- `importSessionX(auth_token, ct0)`: importa la sesión real del
  navegador a partir de las cookies `auth_token` y `ct0`, y la persiste
  como `storageState`.
- [`checkPlaywrightEngine()`](https://agusnieto77.github.io/TweetScraperR/reference/checkPlaywrightEngine.md):
  verifica que el motor de Node.js/Playwright esté instalado y
  operativo.
- [`installPlaywrightEngine()`](https://agusnieto77.github.io/TweetScraperR/reference/installPlaywrightEngine.md):
  instala el motor de Node.js/Playwright (se ejecuta una sola vez).

### Migración de funciones al motor Playwright

- Las **14** funciones `get*`/`scroll*` de scraping se migraron al motor
  Playwright.
- [`getTweetsRetweets()`](https://agusnieto77.github.io/TweetScraperR/reference/getTweetsRetweets.md)
  se migró al motor Playwright (modo `users`).
- Las funciones de **login por pasos** quedaron **deprecadas**:
  [`openTwitter()`](https://agusnieto77.github.io/TweetScraperR/reference/openTwitter.md),
  [`userTwitter()`](https://agusnieto77.github.io/TweetScraperR/reference/userTwitter.md),
  [`passTwitter()`](https://agusnieto77.github.io/TweetScraperR/reference/passTwitter.md),
  [`closeTwitter()`](https://agusnieto77.github.io/TweetScraperR/reference/closeTwitter.md),
  [`openTimeline()`](https://agusnieto77.github.io/TweetScraperR/reference/openTimeline.md)
  y
  [`closeTimeline()`](https://agusnieto77.github.io/TweetScraperR/reference/closeTimeline.md).
  El flujo recomendado es
  [`importSessionX()`](https://agusnieto77.github.io/TweetScraperR/reference/importSessionX.md) +
  el motor Playwright.

### Correcciones

- Se corrigieron loops infinitos en
  [`getTweetsData()`](https://agusnieto77.github.io/TweetScraperR/reference/getTweetsData.md)
  y
  [`getTweetsData2()`](https://agusnieto77.github.io/TweetScraperR/reference/getTweetsData2.md)
  y los contadores de reintento que nunca se incrementaban (código
  muerto).
- Las sesiones de Chrome ahora se cierran correctamente con
  [`on.exit()`](https://rdrr.io/r/base/on.exit.html), incluso cuando una
  función falla a mitad de ejecución.
- Se corrigió la extracción del nombre de usuario para URLs con dominio
  `twitter.com` (antes solo funcionaba con `x.com`).
- [`plotTime()`](https://agusnieto77.github.io/TweetScraperR/reference/plotTime.md)
  ahora funciona correctamente con `group_by = "week"`, `"month"` y
  `"year"`.
- [`getUsersData()`](https://agusnieto77.github.io/TweetScraperR/reference/getUsersData.md)
  interpreta correctamente las métricas abreviadas con sufijos `K`/`M`
  cuando la interfaz de X está en inglés.

### Cambios internos

- Se incorporaron helpers internos compartidos y se centralizaron los
  selectores CSS/XPath para reducir duplicación entre funciones.
- Se agregó integración continua (GitHub Actions, `R CMD check`) y una
  suite de tests con `testthat`.
- `DESCRIPTION` quedó listo para CRAN.

## TweetScraperR 0.2.5

### Correcciones

- Se corrigieron loops infinitos en
  [`getTweetsData()`](https://agusnieto77.github.io/TweetScraperR/reference/getTweetsData.md)
  y
  [`getTweetsData2()`](https://agusnieto77.github.io/TweetScraperR/reference/getTweetsData2.md)
  y los contadores de reintento que nunca se incrementaban (código
  muerto).
- Las sesiones de Chrome ahora se cierran correctamente con
  [`on.exit()`](https://rdrr.io/r/base/on.exit.html), incluso cuando una
  función falla a mitad de ejecución.
- Se corrigió la extracción del nombre de usuario para URLs con dominio
  `twitter.com` (antes solo funcionaba con `x.com`).
- [`plotTime()`](https://agusnieto77.github.io/TweetScraperR/reference/plotTime.md)
  ahora funciona correctamente con `group_by = "week"`, `"month"` y
  `"year"`.
- [`getUsersData()`](https://agusnieto77.github.io/TweetScraperR/reference/getUsersData.md)
  interpreta correctamente las métricas abreviadas con sufijos `K`/`M`
  cuando la interfaz de X está en inglés.
- `kill_system` ahora cierra únicamente el navegador iniciado por el
  paquete, en lugar de matar todos los procesos de Chrome del sistema.
- [`getTweetsHashtags()`](https://agusnieto77.github.io/TweetScraperR/reference/getTweetsHashtags.md)
  ahora devuelve en la columna `hashtags` un vector de caracteres plano
  por tweet (`character(0)` si no hay hashtags). Antes los hashtags
  llegaban anidados en una lista adicional y los tweets sin hashtags
  devolvían `NA`.

### Cambios internos

- Se incorporaron helpers internos compartidos y se centralizaron los
  selectores CSS/XPath para reducir duplicación entre funciones.
- Se regeneró la documentación eliminando los escapes Unicode corruptos
  (`\uXXXX`) introducidos en una versión anterior.
- Se agregó integración continua (GitHub Actions, `R CMD check`) y una
  suite inicial de tests con `testthat`.
- `chromote` pasa de `Suggests` a `Imports`: es el motor de scraping del
  paquete y se usa de forma incondicional.
- Nuevas variables de entorno `TWITTER_USER` y `TWITTER_PASS` para las
  credenciales, con fallback a las variables `USER` y `PASS` por
  compatibilidad. La adopción es parcial:
  [`getTweetsSearchStreamingFor2()`](https://agusnieto77.github.io/TweetScraperR/reference/getTweetsSearchStreamingFor2.md),
  [`getTweetsHistoricalSearchFor()`](https://agusnieto77.github.io/TweetScraperR/reference/getTweetsHistoricalSearchFor.md),
  [`getTweetsHistoricalHashtagFor()`](https://agusnieto77.github.io/TweetScraperR/reference/getTweetsHistoricalHashtagFor.md)
  y
  [`getTweetsHistoricalTimelineFor()`](https://agusnieto77.github.io/TweetScraperR/reference/getTweetsHistoricalTimelineFor.md)
  siguen leyendo únicamente `USER` y `PASS`; si usás esas funciones,
  configurá también esas variables.
- La columna `art_html` de los tibbles devueltos por
  [`getTweetsCites()`](https://agusnieto77.github.io/TweetScraperR/reference/getTweetsCites.md),
  [`getTweetsReplies()`](https://agusnieto77.github.io/TweetScraperR/reference/getTweetsReplies.md)
  y
  [`getTweetsRetweets()`](https://agusnieto77.github.io/TweetScraperR/reference/getTweetsRetweets.md)
  ahora es de tipo `character` (antes era una list-column). Para
  combinar datos guardados con versiones anteriores, convertí primero la
  columna vieja con `mutate(art_html = as.character(art_html))` antes de
  `bind_rows()`.

## TweetScraperR 0.2.4

- Nueva función
  [`getTweetsXquikSearch()`](https://agusnieto77.github.io/TweetScraperR/reference/getTweetsXquikSearch.md):
  cliente de búsqueda vía la API de Xquik (servicio externo, requiere
  `XQUIK_API_KEY`).
