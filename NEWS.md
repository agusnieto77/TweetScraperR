# TweetScraperR (development version)

* Guardado incremental en SQLite con reanudación para las descargas largas
  ([getTweetsHistoricalAPI()], [getTweetsLiveAPI()], [getTweetsThreadsAPI()]).
  Con `save = TRUE` o el nuevo argumento `db`, cada consulta se guarda en una
  base `.sqlite` apenas llega, dentro de una transacción: un corte inesperado
  (Ctrl+C, error, sesión de R caída) no pierde ni corrompe lo confirmado.
  Llamando de nuevo con `db = "<ruta>.sqlite"` se reanuda: la histórica y el
  crawler piden solo las ventanas o conversaciones pendientes (con el período
  y el plan de ventanas fijados al crear la base, aunque se reanude otro día),
  y la captura en vivo continúa desde el tweet más reciente guardado. Una
  ventana o conversación con consultas fallidas o incompletas queda pendiente
  para reintentarse. Como X trunca respuestas al azar (la misma media hora
  densa devolvió 0 y 900 tweets en dos intentos), una respuesta corta ya no
  cierra la ventana: se sigue pidiendo lo anterior al tweet más viejo
  recibido; los reintentos varían el límite de la consulta, y un vacío se
  acepta solo tras confirmar con una consulta testigo que X no está frenando
  en silencio (tras muchas consultas devuelve vacío todo sin avisar del
  límite); si frena, la descarga se corta y queda pendiente. El avance de cada
  ventana se guarda, así que al reanudar se sigue desde donde quedó. Estas tres
  funciones dejan de escribir RDS. Nueva [readTweetsDB()] para leer una base
  sin volver a descargar. Diseño revisado en un juicio dual (dos modelos, a
  ciegas) antes de implementarlo.
* Nueva [getTweetsThreadsAPI()] (experimental): a partir de tweets ya
  descargados, recupera la conversación completa de cada uno (respuestas,
  respuestas a respuestas, a cualquier profundidad) con una búsqueda
  `conversation_id:<id>` por conversación, troceada por ventanas como la
  búsqueda histórica. Omite las conversaciones sin respuestas, pide
  cada una una sola vez y sigue los retweets en el tweet original.
* Nueva [getTweetsHistoricalAPI()] (experimental): descarga completa de una
  búsqueda en un período. Una sola consulta de búsqueda devuelve como mucho
  unos cientos de tweets, así que en períodos densos se perdía casi todo
  (una hora de "milei" tiene más de mil). La función trocea el período en
  ventanas `since_time:`/`until_time:` y, cuando una ventana se satura,
  continúa desde la frontera o la subdivide (hasta 30 min). Estrategia
  adaptada del "optimized search" de t-hoarder-twscrape (Mariluz Congosto).
  El buscador de X solo tiene completos los últimos ~7 días; para el tramo
  anterior la función usa Destacados (`Top`) en ventanas fijas de 3 h, que en
  las pruebas devolvió unas diez veces más que Latest (410 contra 37 tweets en
  un día). Aun así es una muestra, no el total, y la función lo avisa.
* Nueva [getTweetsLiveAPI()] (experimental): captura en vivo de una búsqueda
  "hacia adelante". Repite [getTweetsSearchAPI()] cada `interval` segundos
  (mínimo 60) durante `duration` y, desde la segunda ronda, agrega
  `since_id:<último ID visto>` a la consulta para traer solo lo publicado
  después, sin gastar cupo en lo ya recolectado. Una ronda fallida no corta
  la captura y Esc / Ctrl+C devuelve lo acumulado. Avisa cuando una ronda
  llega al tope `n_tweets` (posibles huecos).
* Nuevo artículo "Parámetros de búsqueda" en el sitio: recorre los operadores
  de X en `getTweetsSearchAPI()` (términos, frase exacta, `OR`, exclusiones,
  hashtags, `from:`/`to:`, menciones, `conversation_id:`, fechas, franjas
  horarias, idioma, métricas mínimas, tipo de contenido, pestañas) con
  ejemplos ejecutados y verificados contra X.
* `getTweetsSearchAPI()`: `since`/`until` con hora vuelven a funcionar. X
  dejó de devolver resultados con `since:YYYY-MM-DD_HH:MM:SS`, así que ahora
  un instante (`"YYYY-MM-DD HH:MM[:SS]"` en UTC, o un `POSIXct` en cualquier
  zona horaria) se traduce a `since_time:`/`until_time:`. Un día
  (`"YYYY-MM-DD"` o `Date`) sigue yendo como `since:`/`until:`, con ambos días
  inclusivos. Una fecha inválida ahora da error en vez de una búsqueda vacía.

# TweetScraperR 0.8.1

Preparación del primer envío a CRAN.

* **Cambio de comportamiento**: las funciones de recolección y de análisis
  (`get*API()`, `getTweetsSentiments()`, `getTweetsImagesAnalysis()`) ya no
  escriben archivos por defecto: `save` pasa a `FALSE`. Para conservar el
  `.rds` hay que pasar `save = TRUE` (se guarda en `dir`, por defecto el
  directorio de trabajo).
* `HTMLImgReport()`: `output_file` pasa a ser obligatorio y la función
  devuelve, de forma invisible, la ruta del HTML generado.
* `DESCRIPTION`: se acredita a vladkens (autor de 'twscrape') como
  contribuidor y titular de copyright del código portado del pool de cuentas;
  el aviso de licencia MIT original está en `inst/COPYRIGHTS`.
* Documentación: ejemplos en todas las funciones exportadas y descripción
  revisada del motor y del pool de cuentas.

# TweetScraperR 0.8.0

## Pool de cuentas con rotación automática

Modelo portado de [twscrape](https://github.com/vladkens/twscrape) (MIT).

* `importSessionX()` gana `account`: importando varias cuentas se arma un
  pool (SQLite en `tools::R_user_dir("TweetScraperR", "data")`). X limita cada
  endpoint **por cuenta** en ventanas de 15 minutos (la búsqueda, ~50
  consultas); cuando una cuenta agota el cupo queda en pausa hasta el reset
  de X y la recolección sigue con la siguiente, retomando desde la URL
  cortada. El bloqueo es por (cuenta, endpoint) y la cuenta se toma de forma
  atómica, así que varias sesiones de R pueden compartir el pool.
* Lo cortado se retoma **desde donde quedó**, sin volver a gastar cupo en lo
  ya traído: el motor guarda el último cursor de paginación de cada URL y la
  cuenta siguiente lo inyecta en la primera request que arma la app de X (el
  `x-client-transaction-id` firma solo método y path, no la query, así que la
  request sigue siendo válida). Verificado entre cuentas distintas.
* El motor deja de scrollear apenas junta los `n_tweets`/`n_users` pedidos
  (antes scrolleaba un número fijo de veces): menos cupo gastado y
  recolecciones más rápidas.
* Corregido: el conteo de usuarixs del progreso (y del corte por `n_users`)
  dependía del bloque `legacy` que X eliminó, y quedaba siempre en 0.
* Si X rechaza una sesión (vencida o revocada, suspendida o bloqueada: errores
  32, 88 con cupo disponible, 326, 401/403) la cuenta se desactiva con el
  motivo y se sigue con otra. Una página de bloqueo HTML (Cloudflare) pausa la
  cuenta 15 minutos.
* Si todas las cuentas están en pausa, se espera hasta
  `getOption("TweetScraperR.wait_timeout", 900)` segundos; pasado ese plazo
  (o con `0`) se devuelve lo recolectado hasta el corte con un aviso.
* Nuevas funciones: `setupAccountsX()` (asistente de consola que pide cada
  cuenta, con `auth_token`/`ct0` ocultos, y la valida en el momento),
  `accountsX()` (estado del pool), `checkAccountsX()`
  (valida cada sesión, registra el @usuario real, desactiva las vencidas o
  bloqueadas y, si la misma cuenta de X está cargada dos veces, deja solo la
  sesión más nueva con las pausas y estadísticas de ambas), `setProxyX()`
  (asigna, cambia o quita el proxy de una cuenta sin volver a cargar sus
  cookies, y la valida a través del proxy nuevo), `addAccountsX()` (alta
  masiva desde CSV o data frame; detecta solo el separador `,` o `;` de los
  CSV de Excel), `reactivateAccountX()`, `resetLocksX()` y
  `removeAccountX()`.
* `importSessionX(cookies = ...)` acepta el header `"auth_token=...; ct0=..."`
  o el JSON de extensiones como Cookie-Editor, y `proxy` por cuenta.
* **BREAKING**: `importSessionX()` y `loginX()` reemplazan `state` (ruta del
  archivo de sesión, que el resto de las funciones nunca leía) por `account`.
  La sesión única existente se incorpora sola al pool como la cuenta
  `"default"`: no hace falta reimportarla.

## Motor

* Corregido: con una sesión inválida X no redirige al login sino que borra la
  cookie `auth_token` y sirve la página en modo invitado, así que las
  funciones `*API()` devolvían 0 filas sin ningún error. El motor ahora lo
  detecta y la cuenta se desactiva como sesión expirada.
* Corregido: el proxy nunca llegaba al motor en las funciones `*API()`. Ahora
  se usa el proxy de la cuenta o, si no tiene, el global
  (`options(TweetScraperR.proxy = ...)` o la variable de entorno
  `TWEETSCRAPERR_PROXY`).
* El navegador ya no declara un User-Agent fijo (`Linux Chrome/131`), que no
  coincidía con el sistema operativo ni con la versión real de Chromium: usa
  el suyo propio, coherente con el resto de la huella.
* El rate-limit se registra por endpoint (antes se pisaba con la última
  respuesta) y se elimina el aviso "Rate-limit de X bajo": el pool pausa la
  cuenta cuando el cupo llega a cero.
* `options(TweetScraperR.debug_dir = "carpeta")` guarda cada respuesta cruda
  de X para depurar cambios de formato.

## Datos

* Corregido: los tweets largos (más de 280 caracteres) salían truncados; ahora
  `texto`, `hashtags`, `menciones` y `urls_externas` salen del texto completo.
* Nuevas columnas en los tweets: `user_id`, `respuesta_a_id`,
  `respuesta_a_user`, `retweet_id`, `guardados`, `fuente` (app de
  publicación), `sensible`, `editado`, `lugar` y `pais`.
* Nuevas columnas en usuarixs: `tweets_media`, `protegida` y
  `tipo_verificacion`.
* Nuevas funciones: `getUsersAboutAPI()` (ficha "Acerca de esta cuenta": país
  de la cuenta, cambios de nombre de usuarix, verificación),
  `getUsersSearchAPI()` (búsqueda de cuentas), `getListTweetsAPI()` y
  `getListMembersAPI()` (Listas de X).
* Nuevas dependencias: `DBI` y `RSQLite`.

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
