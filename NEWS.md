# TweetScraperR 0.3.0

## Cambio mayor: nuevo motor de scraping (Node.js + Playwright + stealth)

* El scraping ya no se realiza con `chromote`. Se incorporó un nuevo motor
  basado en **Node.js + Playwright + stealth** que reemplaza a `chromote`
  para **todo** el scraping del paquete. `chromote` se mantiene en `Imports`
  porque todavía lo usan las funciones de login por pasos (`openTwitter()` /
  `closeTwitter()`).
* El motor de Node.js/Playwright se instala una sola vez con
  `installPlaywrightEngine()` y su estado se verifica con
  `checkPlaywrightEngine()`. Requiere **Node.js (>= 18)** y un navegador
  basado en Chromium.

## Cambio mayor: modelo de sesión por cookies

* El **login automatizado ya no es viable**: X bloquea activamente el inicio
  de sesión vía automatización del navegador. El paquete adopta un modelo de
  **sesión por cookies**.
* Ahora se importa la **sesión real del navegador** con
  `importSessionX(auth_token, ct0)`. La sesión se persiste como
  `storageState` y se **reutiliza para todas** las funciones de scraping, sin
  necesidad de volver a loguearse.
* Las cookies de X expiran; cuando eso ocurre, hay que volver a copiarlas
  desde el navegador y reimportarlas con `importSessionX()`.

## Nuevas funciones exportadas

* `loginX()`: flujo de autenticación basado en el nuevo motor.
* `importSessionX(auth_token, ct0)`: importa la sesión real del navegador a
  partir de las cookies `auth_token` y `ct0`, y la persiste como
  `storageState`.
* `checkPlaywrightEngine()`: verifica que el motor de Node.js/Playwright esté
  instalado y operativo.
* `installPlaywrightEngine()`: instala el motor de Node.js/Playwright (se
  ejecuta una sola vez).

## Migración de funciones al motor Playwright

* Las **14** funciones `get*`/`scroll*` de scraping se migraron al motor
  Playwright.
* `getTweetsRetweets()` se migró al motor Playwright (modo `users`).
* Las funciones de **login por pasos** quedaron **deprecadas**:
  `openTwitter()`, `userTwitter()`, `passTwitter()`, `closeTwitter()`,
  `openTimeline()` y `closeTimeline()`. El flujo recomendado es
  `importSessionX()` + el motor Playwright.

## Correcciones

* Se corrigieron loops infinitos en `getTweetsData()` y `getTweetsData2()` y
  los contadores de reintento que nunca se incrementaban (código muerto).
* Las sesiones de Chrome ahora se cierran correctamente con `on.exit()`,
  incluso cuando una función falla a mitad de ejecución.
* Se corrigió la extracción del nombre de usuario para URLs con dominio
  `twitter.com` (antes solo funcionaba con `x.com`).
* `plotTime()` ahora funciona correctamente con `group_by = "week"`,
  `"month"` y `"year"`.
* `getUsersData()` interpreta correctamente las métricas abreviadas con
  sufijos `K`/`M` cuando la interfaz de X está en inglés.

## Cambios internos

* Se incorporaron helpers internos compartidos y se centralizaron los
  selectores CSS/XPath para reducir duplicación entre funciones.
* Se agregó integración continua (GitHub Actions, `R CMD check`) y una
  suite de tests con `testthat`.
* `DESCRIPTION` quedó listo para CRAN.

# TweetScraperR 0.2.5

## Correcciones

* Se corrigieron loops infinitos en `getTweetsData()` y `getTweetsData2()` y
  los contadores de reintento que nunca se incrementaban (código muerto).
* Las sesiones de Chrome ahora se cierran correctamente con `on.exit()`,
  incluso cuando una función falla a mitad de ejecución.
* Se corrigió la extracción del nombre de usuario para URLs con dominio
  `twitter.com` (antes solo funcionaba con `x.com`).
* `plotTime()` ahora funciona correctamente con `group_by = "week"`,
  `"month"` y `"year"`.
* `getUsersData()` interpreta correctamente las métricas abreviadas con
  sufijos `K`/`M` cuando la interfaz de X está en inglés.
* `kill_system` ahora cierra únicamente el navegador iniciado por el paquete,
  en lugar de matar todos los procesos de Chrome del sistema.
* `getTweetsHashtags()` ahora devuelve en la columna `hashtags` un vector de
  caracteres plano por tweet (`character(0)` si no hay hashtags). Antes los
  hashtags llegaban anidados en una lista adicional y los tweets sin hashtags
  devolvían `NA`.

## Cambios internos

* Se incorporaron helpers internos compartidos y se centralizaron los
  selectores CSS/XPath para reducir duplicación entre funciones.
* Se regeneró la documentación eliminando los escapes Unicode corruptos
  (`\uXXXX`) introducidos en una versión anterior.
* Se agregó integración continua (GitHub Actions, `R CMD check`) y una
  suite inicial de tests con `testthat`.
* `chromote` pasa de `Suggests` a `Imports`: es el motor de scraping del
  paquete y se usa de forma incondicional.
* Nuevas variables de entorno `TWITTER_USER` y `TWITTER_PASS` para las
  credenciales, con fallback a las variables `USER` y `PASS` por
  compatibilidad. La adopción es parcial: `getTweetsSearchStreamingFor2()`,
  `getTweetsHistoricalSearchFor()`, `getTweetsHistoricalHashtagFor()` y
  `getTweetsHistoricalTimelineFor()` siguen leyendo únicamente `USER` y
  `PASS`; si usás esas funciones, configurá también esas variables.
* La columna `art_html` de los tibbles devueltos por `getTweetsCites()`,
  `getTweetsReplies()` y `getTweetsRetweets()` ahora es de tipo `character`
  (antes era una list-column). Para combinar datos guardados con versiones
  anteriores, convertí primero la columna vieja con
  `mutate(art_html = as.character(art_html))` antes de `bind_rows()`.

# TweetScraperR 0.2.4

* Nueva función `getTweetsXquikSearch()`: cliente de búsqueda vía la API de
  Xquik (servicio externo, requiere `XQUIK_API_KEY`).
