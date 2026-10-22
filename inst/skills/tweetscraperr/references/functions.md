# TweetScraperR — referencia de funciones

Firmas exactas de las funciones exportadas. Todas las funciones de
recolección requieren el motor instalado (`installPlaywrightEngine()`) y una
sesión importada (`importSessionX()`). Por defecto no escriben archivos;
con `save = TRUE` guardan un `.rds` con el resultado en `dir`.

## Sesión y motor

```r
installPlaywrightEngine(npm = "npm")
```
Copia el motor Node/Playwright a la caché del usuario y corre `npm install`
(descarga Chromium). Una vez por máquina. Devuelve invisible el código de npm.

```r
checkPlaywrightEngine()
```
Verifica el motor. Devuelve invisible una lista con `ok`, `playwright`, `node`.

```r
importSessionX(auth_token, ct0, account = "default", proxy = NULL, cookies = NULL)
```
Guarda las cookies `auth_token` y `ct0` de x.com como una cuenta del pool.
`cookies` acepta el header `"auth_token=...; ct0=..."` o el JSON de
Cookie-Editor en lugar de los dos argumentos. Reimportar con el mismo
`account` renueva la sesión y reactiva la cuenta. Devuelve invisible el
nombre de la cuenta.

```r
setupAccountsX(validate = TRUE)  # asistente interactivo: pide nombre, auth_token y ct0
                                 # (ocultos; acepta pegar el header de cookies) y proxy;
                                 # importa y valida cada cuenta. Enter vacío termina.
addAccountsX(accounts)        # data frame o CSV: account, auth_token, ct0, proxy
accountsX()                   # tibble: cuenta, usuario_x, activa, pausas, requests,
                              # requests_por_endpoint, ultimo_uso, proxy, error
checkAccountsX(accounts = NULL)  # valida sesiones: cuenta, valida, usuario_x, motivo
setProxyX(accounts, proxy, validate = TRUE)  # asigna/cambia el proxy sin tocar la sesión
                                            # (NULL lo quita) y valida a través de él
reactivateAccountX(accounts)
resetLocksX()
removeAccountX(accounts)
```
Gestión del pool. Opciones: `TweetScraperR.wait_timeout` (segundos de espera
si todas las cuentas están en pausa; por defecto 900), `TweetScraperR.proxy`
(proxy global; la cuenta con proxy propio lo usa primero) y
`TweetScraperR.debug_dir` (vuelca cada respuesta cruda de X).

```r
loginX(xuser = Sys.getenv("TWITTER_USER"), xpass = Sys.getenv("TWITTER_PASS"),
       email = Sys.getenv("TWITTER_EMAIL", ""), headless = TRUE,
       account = "default", proxy = NULL)
```
Login automatizado. X suele bloquearlo; preferir `importSessionX()`.
`proxy`: `"http://host:puerto"`, `"usuario:clave@host:puerto"` o
`list(server =, username =, password =)`.

## Tweets

Todas devuelven el tibble de 31 columnas descrito en `SKILL.md`.

```r
getUserTweetsAPI(username = "NASA", n_tweets = 40, dir = getwd(), save = FALSE)
```
Timeline de una cuenta (tweets originales).

```r
getTweetsTimelinesAPI(usernames, n_tweets = 40, dir = getwd(), save = FALSE)
```
Varias cuentas en una sola sesión de navegador; `n_tweets` es por cuenta.
Resultado combinado, deduplicado y ordenado por fecha descendente.

```r
getTweetsSearchAPI(search = "#RStats", n_tweets = 40,
                   product = c("Latest", "Top", "Media"),
                   since = NULL, until = NULL, dir = getwd(), save = FALSE)
```
Búsqueda con operadores de X. `since`/`until`: un día `"YYYY-MM-DD"` (ambos
días inclusivos) o una hora `"YYYY-MM-DD HH:MM:SS"` en UTC; también aceptan
`Date` y `POSIXct` (respeta su zona horaria).

```r
getTweetsHistoricalAPI(search, since = NULL, until = NULL, n_per_window = 900,
                       db = NULL, dir = getwd(), save = FALSE)
```
Descarga completa de un período: trocea en ventanas `since_time:`/`until_time:`
y, si una se satura, continúa desde la frontera o la subdivide. Usar en lugar de
`getTweetsSearchAPI()` cuando se esperan más de ~500 tweets. El buscador de X
solo tiene completos los últimos ~7 días: el tramo anterior se baja con
Destacados en ventanas de 3 h, que da una muestra (≈10× Latest), no el total.
`since` es obligatorio al empezar; `until = NULL` es "ahora".

```r
getTweetsThreadsAPI(tweets = NULL, n_per_window = 900, db = NULL, dir = getwd(), save = FALSE)
```
Crawler de conversaciones: para cada tweet de entrada (tibble de cualquier
`*API()` o vector de `conversation_id`) trae el árbol completo de respuestas con
una búsqueda `conversation_id:<id>`. Omite raíces sin respuestas y sigue los
retweets en el original. El árbol se reconstruye con `respuesta_a_id`.

```r
getTweetsLiveAPI(search = "#RStats", interval = 300, duration = 3600,
                 n_tweets = 100, max_tweets = Inf, db = NULL, dir = getwd(), save = FALSE)
```
Captura en vivo: repite la búsqueda "Latest" cada `interval` segundos (mínimo
60) durante `duration`, trayendo solo tweets nuevos (`since_id`). Esc / Ctrl+C
devuelve lo acumulado.

**Guardado y reanudación (las tres anteriores):** con `save = TRUE` crean una
base nueva `api_<funcion>_..._<fecha>.sqlite` en `dir` y guardan cada consulta
apenas llega. Si la descarga se corta, se reanuda llamando de nuevo con la
misma consulta y `db = "<ruta>.sqlite"` (en el crawler alcanza con `db`): solo
se pide lo pendiente. `readTweetsDB(db)` lee una base sin descargar nada. Para
descargas grandes, recomendar siempre `save = TRUE`.

```r
getTweetsRepliesAPI(url, n_tweets = 40, dir = getwd(), save = FALSE)
```
Tweet original más sus respuestas (hilo de conversación).

```r
getTweetsDataAPI(urls_tweets, dir = getwd(), save = FALSE)
```
Datos de uno o más tweets a partir de sus URLs.

```r
getUserMediaAPI(username = "NASA", n_tweets = 40, dir = getwd(), save = FALSE)
```
Tweets con fotos/videos de una cuenta. Para videos, `media` trae el mp4 de
mayor bitrate.

```r
getListTweetsAPI(list_id, n_tweets = 40, dir = getwd(), save = FALSE)
```
Tweets recientes de una Lista de X. `list_id`: id numérico o URL
`https://x.com/i/lists/<id>`.

## Usuarixs

Devuelven una fila por cuenta (18 columnas): `user`, `nombre`, `user_id`,
`descripcion`, `seguidores`, `siguiendo`, `tweets`, `favoritos`,
`verificado`, `ubicacion`, `sitio_web`, `imagen_perfil`, `banner`,
`fecha_creacion`, `url`, `tweets_media`, `protegida`, `tipo_verificacion`.

```r
getUsersDataAPI(usernames, dir = getwd(), save = FALSE)
getUsersSearchAPI(search, n_users = 40, dir = getwd(), save = FALSE)
getUserFollowersAPI(username, n_users = 100, dir = getwd(), save = FALSE)
getUserFollowingAPI(username, n_users = 100, dir = getwd(), save = FALSE)
getTweetsRetweetsAPI(url, n_users = 100, dir = getwd(), save = FALSE)
getListMembersAPI(list_id, n_users = 100, dir = getwd(), save = FALSE)
```

```r
getUsersAboutAPI(usernames, dir = getwd(), save = FALSE)
```
Ficha "Acerca de esta cuenta": `pais_cuenta`, `ubicacion_precisa`,
`cambios_usuario`, `ultimo_cambio_usuario`, `afiliada_a`, `origen_cuenta`,
`identidad_verificada`, `verificada_desde` (más `user`, `nombre`, `user_id`,
`fecha_creacion`, `url`).

## Visualización

```r
plotTime(df, group_by = "hour", color = "blue")
```
Línea de frecuencia de tweets. Necesita la columna `fecha`. `group_by`:
`"hour"`, `"day"`, `"week"`, `"month"`, `"year"`. Devuelve un ggplot.

```r
plotWords(df, min_freq = 3, max_words = 100, random_order = FALSE,
          colors = "random-dark", size = 0.3, lang = "es", sw = NULL)
```
Nube de palabras (wordcloud2) de la columna `texto` o `tweet`. `lang`:
idioma de stopwords (`"es"`, `"en"`, `"pt"`...); `sw`: stopwords extra.

```r
plotEmojis(df, top_n = 10, fill = "skyblue", color = "grey30")
plotEmojisPNG(df, top_n = 10, fill = "skyblue", color = "grey30")
```
Barras de emojis más frecuentes (columna `emoticones`). `plotEmojisPNG()`
dibuja los emojis en color y requiere el paquete `ggimage` (en macOS además
XQuartz).

## Análisis

```r
getTweetsHashtags(df)
```
Agrega la columna `hashtags` (vector por tweet) extraída de `texto`/`tweet`.

```r
getTweetsSentiments(tweets, api_key = Sys.getenv("OPENAI_API_KEY"),
                    model = "gpt-4o-mini", dir = getwd(), save = FALSE)
```
`tweets` es un vector de textos (p. ej. `df$texto`). Devuelve tono,
sentimiento, odio, direccionamiento, llamado a la acción y explicación.
Envía los textos a OpenAI.

```r
getTweetsImagesAnalysis(img_sources, modelo = "gpt-4o-mini",
                        api_key = Sys.getenv("OPENAI_API_KEY"),
                        dir = getwd(), save = FALSE)
```
`img_sources`: URLs o rutas locales de imágenes (no videos). Devuelve
clasificación, texto en la imagen, descripción, palabras clave y banderas de
contenido. Envía las imágenes a OpenAI.

```r
HTMLImgReport(results, output_file)
```
Reporte HTML (carrusel) a partir del resultado de `getTweetsImagesAnalysis()`.
`output_file` es obligatorio.

```r
extractTweetsData(data)
```
Legacy: procesa RDS antiguos con HTML de tweets (`art_html`, `url`,
`fecha_captura`). No sirve para la salida de las funciones `*API()`, que ya
viene estructurada.

## Skill para agentes

```r
installAgentSkill(agent = "posit", scope = c("user", "project"),
                  path = NULL, overwrite = FALSE)
```
Instala esta skill para Posit Assistant (`"posit"`), clientes del estándar
Agent Skills (`"agents"`) o Claude Code (`"claude"`).
