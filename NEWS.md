# TweetScraperR 0.7.0

## Progreso en vivo durante la recolección

* Las funciones de recolección (`getTweetsSearchAPI()`, `getUserTweetsAPI()`,
  `getTweetsTimelinesAPI()`, perfiles, seguidorxs, etc.) muestran ahora un
  spinner de una sola línea que se actualiza en el lugar con la cantidad de
  tweets/usuarixs capturados, el tiempo transcurrido y el último tweet
  recibido. Solo aparece en consolas interactivas (RStudio, terminal); en
  Rscript/knitr no se imprime nada extra.
* El motor Node corre como proceso asíncrono (`processx`): un Ctrl+C corta la
  recolección sin dejar Chromium abierto. Nuevas dependencias: `cli` y
  `processx`.
* El `tsr-engine.js` del cache del motor se actualiza solo cuando cambia el
  del paquete. Si también cambiaron sus dependencias de npm (o la copia
  falla), se sigue usando el motor anterior y se avisa que hay que correr
  `installPlaywrightEngine()`.

# TweetScraperR 0.6.1

* Las instrucciones de instalación (README y `Requisitos.md`) pasan de
  `devtools::install_github()`, deprecada en devtools 2.5.0, a
  `pak::pak("agusnieto77/TweetScraperR")`. Con `pak` tampoco aparecen los
  avisos `skipping pax global extended headers` del `untar()` interno de R,
  que eran inofensivos.

# TweetScraperR 0.6.0

## Skill conversacional para agentes de IA

* Nueva [installAgentSkill()]: instala una skill (formato Agent Skills) para
  usar TweetScraperR de forma conversacional desde agentes de IA, en
  particular Posit Assistant (RStudio/Positron), además de Claude Code y
  clientes de `.agents/skills`. En Windows instala en `%USERPROFILE%`, que es
  donde los agentes buscan sus skills (R usa Documentos como `~`).

# TweetScraperR 0.5.0

## Paquete unificado sobre el motor Node/Playwright (BREAKING)

* Se **eliminan** las funciones de scraping por HTML con sesión chromote,
  todas deprecadas en 0.3/0.4 y rotas tras los rediseños de X (bloqueo de
  login automatizado y cambios de DOM): familia de sesion
  (`openTwitter()`, `closeTwitter()`, `openTimeline()`, `closeTimeline()`,
  `passTwitter()`, `userTwitter()`), la familia de scroll
  (`getScrollExtract()`, `getScrollExtractUrls()`), la familia `*API` de
  reemplazo ya cubre:
  - `getTweetsData()`, `getTweetsData2()` → [getTweetsDataAPI()]
  - `getTweetsFullSearch()`, los streaming, los históricos y la familia
    `getUrls*()` → [getTweetsSearchAPI()]
  - `getTweetsTimeline()`, `getTweetsTimelineFor()` → [getUserTweetsAPI()]
    / [getTweetsTimelinesAPI()]
  - `getTweetsCites()`, `getTweetsReplies()` → [getTweetsRepliesAPI()]
  - `getTweetsRetweets()` → [getTweetsRetweetsAPI()]
  - `getTweetsImages()` → [getUserMediaAPI()]
  - `getUsersData()`, `getUsersFullData()` → [getUsersDataAPI()]
* [getTweetsSearchAPI()] incorpora los argumentos `since` y `until`
  (paridad con los históricos eliminados: filtrar por rango de fechas
  nativo de la búsqueda de X).
* Paquete: 20 archivos R, 23 exportaciones, un solo contrato de columnas
  para toda la familia `*API()`.
* `ggimage` pasa a `Suggests` (solo lo usa `plotEmojisPNG()`): su cadena
  de dependencias (`ggiraph` → `gdtools`) exige XQuartz en macOS y rompía
  la instalación en sistemas sin X11.
* Todas las capacidades post-procesamiento siguen intactas:
  `extractTweetsData()` (procesa RDS legacy con `art_html` ya guardados),
  `getTweetsHashtags()`, `getTweetsSentiments()`, `getTweetsImagesAnalysis()`,
  `HTMLImgReport()`, `plot*()`.

# TweetScraperR 0.4.0.9000 (desarrollo)

## Mejoras del motor Node/Playwright en Windows

* El motor (tsr-engine.js + dependencias de npm) ahora se instala en un cache
  persistente (`tools::R_user_dir("TweetScraperR", "cache")`) en lugar de la
  carpeta del paquete, de modo que reinstalar TweetScraperR ya no borra
  `node_modules` ni obliga a correr `installPlaywrightEngine()` otra vez.
* `installPlaywrightEngine()` instala en ese cache; `.pw_engine_dir()` lo usa
  con preferencia y cae a `inst/node` solo si el cache no tiene dependencias.
* El timeline de perfil ya no usa la operacion GraphQL `UserTweets` (X la
  elimino); ahora cosecha `UserOriginalsTimeline`, el nombre nuevo que la app
  dispara en las paginas de perfil. Afecta a `getUserTweetsAPI()` y
  `getTweetsTimelinesAPI()`.
* Las paginas de media de perfil ya no disparan la operacion GraphQL
  `UserMedia`; ahora cosechan `UserVideoTimeline`. Afecta a `getUserMediaAPI()`
  (probado sobre @sanchezcastejon). `getTweetsRepliesAPI()` sigue OK con
  `TweetDetail` (no cambio).
* X elimino el bloque `legacy` de los payloads de usuario: los counts migraron
  a `relationship_counts` (seguidores/siguiendo), `tweet_counts` (tweets) y
  `action_counts` (favoritos); la bio a `profile_bio`; avatar y banner a
  `avatar`/`banner`. La fila de usuarix (`.user_row`) se reescribio con la
  estructura nueva y fallbacks a `legacy`. Eso llenaba con NA `seguidores`,
  `siguiendo`, `tweets` y `favoritos` en `getUsersDataAPI()`,
  `getTweetsRetweetsAPI()`, `getUserFollowersAPI()` y `getUserFollowingAPI()`.
* Cuando la respuesta del motor no es JSON, el error ahora incluye el código
  de salida, la salida cruda y el final de stderr (antes quedaba vacío y no
  se podía diagnosticar, como el `Cannot find module 'playwright-extra'`).

## Correcciones en Windows

* `.pw_call()` ya redirige el stdout del motor Node.js a un archivo temporal en
  lugar de capturarlo con `system2(stdout = TRUE)`. En Windows, capturar stdout
  en memoria trunca las líneas mayores a ~8KB (límite del pipe de MSVCRT) y
  corrompe el JSON de respuesta. Ya no hace falta aplicar el parche manual con
  `assignInNamespace()` en cada sesión.

# TweetScraperR 0.4.0

## Nueva capa de scraping vía API GraphQL/JSON (experimental)

* Familia de funciones `*API()` que consultan la **API GraphQL interna de X** y
  devuelven datos estructurados desde JSON (texto completo sin truncar, fecha
  exacta y métricas: respuestas, retweets, citas, me gusta, vistas), en lugar
  de parsear HTML con selectores CSS frágiles. Todas reusan la sesión importada
  con `importSessionX()`.
  - `getUserTweetsAPI()` — timeline de unx usuarix.
  - `getTweetsSearchAPI()` — búsqueda (con `product` Latest/Top/Media).
  - `getTweetsRepliesAPI()` — tweet y sus respuestas (hilo).
  - `getTweetsRetweetsAPI()` — usuarixs que repostearon un tweet.
  - `getUserFollowersAPI()` / `getUserFollowingAPI()` — redes de usuarixs.
  - `getUsersDataAPI()` — datos de perfil.
  - `getUserMediaAPI()` — tweets con media de unx usuarix.
  - `getTweetsDataAPI()` — datos de tweets a partir de sus URLs (reemplazo de
    `getTweetsData()`).
  - `getTweetsTimelinesAPI()` — timeline combinado de varias cuentas (sin
    necesitar una Lista de X).
* Internamente, los endpoints que exigen el header anti-bot
  `x-client-transaction-id` (p.ej. búsqueda, replies, followers) se resuelven
  "cosechando" las respuestas JSON que dispara la propia app de X al navegar la
  página (la app genera ese header de forma nativa), evitando reproducirlo.

## Deprecaciones y documentación

* Las funciones de scraping por **HTML** (`getTweetsTimeline()`,
  `getTweetsHistoricalSearch()`, `getTweetsData()`, `getUsersData()`, la familia
  `getUrls*()`, las variantes `*For()`, etc.) quedan **deprecadas** en favor de
  sus equivalentes `*API()`, más robustas. Siguen funcionando pero emiten una
  advertencia de ciclo de vida.
* Nueva **viñeta** "Scraping de X/Twitter con TweetScraperR" con el flujo
  completo recomendado (instalar el motor, importar la sesión, usar las
  funciones `*API()`).

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
