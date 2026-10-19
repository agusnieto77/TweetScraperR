# TweetScraperR — referencia de funciones

Firmas exactas de las funciones exportadas. Todas las funciones de
recolección requieren el motor instalado (`installPlaywrightEngine()`) y una
sesión importada (`importSessionX()`). `dir = getwd()` y `save = TRUE` guardan
un `.rds` con el resultado.

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
importSessionX(auth_token, ct0, state = <ruta estándar del paquete>)
```
Guarda las cookies `auth_token` y `ct0` de x.com como sesión persistente.
Devuelve invisible la ruta del archivo de sesión.

```r
loginX(xuser = Sys.getenv("TWITTER_USER"), xpass = Sys.getenv("TWITTER_PASS"),
       email = Sys.getenv("TWITTER_EMAIL", ""), headless = TRUE,
       state = <ruta estándar>, proxy = NULL)
```
Login automatizado. X suele bloquearlo; preferir `importSessionX()`.
`proxy`: `"http://host:puerto"`, `"usuario:clave@host:puerto"` o
`list(server =, username =, password =)`.

## Tweets

Todas devuelven el tibble de 21 columnas descrito en `SKILL.md`.

```r
getUserTweetsAPI(username = "NASA", n_tweets = 40, dir = getwd(), save = TRUE)
```
Timeline de una cuenta (tweets originales).

```r
getTweetsTimelinesAPI(usernames, n_tweets = 40, dir = getwd(), save = TRUE)
```
Varias cuentas en una sola sesión de navegador; `n_tweets` es por cuenta.
Resultado combinado, deduplicado y ordenado por fecha descendente.

```r
getTweetsSearchAPI(search = "#RStats", n_tweets = 40,
                   product = c("Latest", "Top", "Media"),
                   since = NULL, until = NULL, dir = getwd(), save = TRUE)
```
Búsqueda con operadores de X. `since`/`until`: `"YYYY-MM-DD"` o
`"YYYY-MM-DD_HH:MM:SS"`.

```r
getTweetsRepliesAPI(url, n_tweets = 40, dir = getwd(), save = TRUE)
```
Tweet original más sus respuestas (hilo de conversación).

```r
getTweetsDataAPI(urls_tweets, dir = getwd(), save = TRUE)
```
Datos de uno o más tweets a partir de sus URLs.

```r
getUserMediaAPI(username = "NASA", n_tweets = 40, dir = getwd(), save = TRUE)
```
Tweets con fotos/videos de una cuenta. Para videos, `media` trae el mp4 de
mayor bitrate.

## Usuarixs

Devuelven una fila por cuenta (15 columnas): `user`, `nombre`, `user_id`,
`descripcion`, `seguidores`, `siguiendo`, `tweets`, `favoritos`,
`verificado`, `ubicacion`, `sitio_web`, `imagen_perfil`, `banner`,
`fecha_creacion`, `url`.

```r
getUsersDataAPI(usernames, dir = getwd(), save = TRUE)
getUserFollowersAPI(username, n_users = 100, dir = getwd(), save = TRUE)
getUserFollowingAPI(username, n_users = 100, dir = getwd(), save = TRUE)
getTweetsRetweetsAPI(url, n_users = 100, dir = getwd(), save = TRUE)
```

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
                    model = "gpt-4o-mini", dir = getwd(), save = TRUE)
```
`tweets` es un vector de textos (p. ej. `df$texto`). Devuelve tono,
sentimiento, odio, direccionamiento, llamado a la acción y explicación.
Envía los textos a OpenAI.

```r
getTweetsImagesAnalysis(img_sources, modelo = "gpt-4o-mini",
                        api_key = Sys.getenv("OPENAI_API_KEY"),
                        dir = getwd(), save = TRUE)
```
`img_sources`: URLs o rutas locales de imágenes (no videos). Devuelve
clasificación, texto en la imagen, descripción, palabras clave y banderas de
contenido. Envía las imágenes a OpenAI.

```r
HTMLImgReport(results, output_file = "visualizacion_imagenes.html")
```
Reporte HTML (carrusel) a partir del resultado de `getTweetsImagesAnalysis()`.

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
