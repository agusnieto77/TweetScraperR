---
name: tweetscraperr
description: Collect and analyze X/Twitter data in R with the TweetScraperR package. Use when the user wants to scrape, download, search or monitor tweets/posts, timelines, replies, threads, retweeters, followers, following, profiles or media from X/Twitter, or to plot/analyze collected tweets (time series, word clouds, emojis, hashtags, sentiment, image analysis). Also use for TweetScraperR setup problems (Node/Playwright engine, X session cookies, expired session, rate limits). Usar cuando la persona pide recolectar, buscar o analizar tweets o usuarixs de X/Twitter desde R.
license: MIT
compatibility: Requires R (>= 4.1), the TweetScraperR package, Node.js (>= 18) and a Chromium-based browser. Designed for agents with a live R session (Posit Assistant in RStudio/Positron) but works with any Agent Skills client.
metadata:
  package: TweetScraperR
  author: Agustín Nieto
  url: https://agusnieto77.github.io/TweetScraperR/
---

# TweetScraperR — uso conversacional

Guiás a la persona para recolectar y analizar datos de X/Twitter con el paquete
de R `TweetScraperR`. Traducís pedidos en lenguaje natural ("traeme los últimos
200 tweets de la NASA y graficá su actividad por día") a llamadas concretas,
las ejecutás en la sesión de R cuando tu entorno lo permite y explicás el
resultado.

Referencia completa de argumentos y columnas: `references/functions.md`
(leela cuando necesites un argumento o una columna que no figura acá).

## Reglas de conversación

1. **Respondé en el idioma de la persona.** El paquete y sus mensajes están en
   español; las columnas también (`fecha`, `texto`, `megustas`...).
2. **Antes de recolectar, confirmá lo que falte**: cuenta/consulta/URL y
   cantidad (`n_tweets`/`n_users`). Si la persona no da cantidad, usá el
   default de la función y decilo. No hagas más de una pregunta por turno.
3. **Ejecutá código en la sesión de R** cuando tengas una sesión viva (Posit
   Assistant la tiene). Mostrá siempre el código que corriste para que la
   persona pueda reproducirlo.
4. **Guardado**: por defecto las funciones de recolección no escriben archivos
   (`save = FALSE`). Si la persona quiere conservar datos, usá `save = TRUE`
   (guarda un `.rds` en `dir`, por defecto el directorio de trabajo) y decí
   dónde quedó el archivo.
5. **Asigná siempre el resultado** a un objeto con nombre descriptivo
   (`tw_nasa`, `seg_rstats`) y mostrá un resumen corto
   (`nrow()`, rango de `fecha`, `dplyr::glimpse()`), no el tibble entero.
6. **Pedidos grandes**: X limita cada endpoint por cuenta en ventanas de 15
   minutos (la búsqueda, ~50 consultas). Con una sola cuenta, al agotarse el
   cupo el paquete espera a que X lo renueve; para más de ~500 tweets o ~1000
   usuarixs proponé sumar cuentas al pool (`importSessionX(..., account =)`)
   o partir en tramos (por ejemplo con `since`/`until` en búsquedas).
7. **Secretos**: nunca pidas que peguen cookies ni claves en el chat. Para
   cargar cuentas, que la persona corra `setupAccountsX()` en su consola
   (entrada oculta), o que las guarde en `~/.Renviron` y las lea con
   `Sys.getenv()`.
8. **Uso responsable**: recordá, cuando aplique, que los datos son de personas
   reales; sugerí no redistribuir datos personales y respetar los términos de
   X. Las funciones con OpenAI envían contenido a un tercero: avisalo antes de
   correrlas.

## Puesta a punto (una vez por máquina)

Antes de la primera recolección verificá el entorno en este orden y frená en
el primer paso que falle:

```r
library(TweetScraperR)
checkPlaywrightEngine()      # ¿motor Node/Playwright instalado y operativo?
```

- Error "falta node_modules" o "No se encontró Node.js" → instalar Node.js
  (>= 18) desde https://nodejs.org y luego `installPlaywrightEngine()`.
- El motor queda en una caché persistente del usuario: sobrevive a las
  reinstalaciones del paquete.

### Sesión de X (obligatoria para recolectar)

X bloquea el login automatizado, así que la vía robusta es importar las cookies
de una sesión real del navegador:

1. La persona inicia sesión en x.com en su navegador habitual.
2. DevTools (F12) → Application/Almacenamiento → Cookies → `https://x.com` →
   copiar `auth_token` y `ct0`.
3. Guardarlas en `~/.Renviron` (`usethis::edit_r_environ()`):
   `X_AUTH_TOKEN=...` y `X_CT0=...`; reiniciar R.
4. Importar:

```r
importSessionX(Sys.getenv("X_AUTH_TOKEN"), Sys.getenv("X_CT0"))
```

La sesión se guarda en disco y todas las funciones la reusan. Solo hay que
repetirlo cuando expira. `loginX()` existe pero X suele bloquearlo: proponelo
solo si la persona lo pide explícitamente.

### Pool de cuentas (opcional)

Con varias cuentas la recolección rota sola: la que agota el cupo de un
endpoint queda en pausa y se sigue con otra; la que X rechaza se desactiva.

```r
setupAccountsX()              # asistente de consola: la persona carga cada cuenta (entrada oculta)
importSessionX(Sys.getenv("X2_AUTH_TOKEN"), Sys.getenv("X2_CT0"), account = "cuenta2")
addAccountsX("cuentas.csv")   # columnas account, auth_token, ct0, proxy (opcional)
accountsX()                   # activas, pausas por endpoint, requests, errores
checkAccountsX()              # valida cada sesión y muestra su @usuario real
setProxyX("cuenta2", "http://usuario:clave@host:puerto")  # proxy por cuenta (NULL lo quita)
reactivateAccountX("cuenta2"); resetLocksX(); removeAccountX("cuenta2")
```

`options(TweetScraperR.wait_timeout = 0)` hace que, si todas las cuentas están
en pausa, se devuelva lo recolectado en vez de esperar (por defecto espera
hasta 900 s). Proxy global: `options(TweetScraperR.proxy = "http://...")` o
`TWEETSCRAPERR_PROXY` en `~/.Renviron`. Usar la dirección HTTP del proveedor:
Chromium no admite SOCKS5 con usuario y clave.

## De la intención a la función

| La persona quiere... | Función |
|---|---|
| Tweets de una cuenta | `getUserTweetsAPI(username, n_tweets = 40)` |
| Timeline combinado de varias cuentas | `getTweetsTimelinesAPI(usernames, n_tweets = 40)` (n por cuenta) |
| Buscar por palabra, hashtag, cuenta, idioma o fechas | `getTweetsSearchAPI(search, n_tweets = 40, product = "Latest", since, until)` |
| Respuestas / hilo de un tweet | `getTweetsRepliesAPI(url, n_tweets = 40)` |
| Datos de tweets puntuales a partir de URLs | `getTweetsDataAPI(urls_tweets)` |
| Tweets con fotos/videos de una cuenta | `getUserMediaAPI(username, n_tweets = 40)` |
| Perfil(es): seguidores, bio, fecha de creación | `getUsersDataAPI(usernames)` |
| País de la cuenta, cambios de nombre, verificación | `getUsersAboutAPI(usernames)` |
| Buscar cuentas por tema o nombre | `getUsersSearchAPI(search, n_users = 40)` |
| Seguidorxs de una cuenta | `getUserFollowersAPI(username, n_users = 100)` |
| Cuentas que sigue una cuenta | `getUserFollowingAPI(username, n_users = 100)` |
| Quién retuiteó un tweet | `getTweetsRetweetsAPI(url, n_users = 100)` |
| Tweets de una Lista de X | `getListTweetsAPI(list_id, n_tweets = 40)` |
| Miembros de una Lista de X | `getListMembersAPI(list_id, n_users = 100)` |
| Actividad en el tiempo | `plotTime(df, group_by = "hour"/"day"/"week"/"month"/"year")` |
| Nube de palabras | `plotWords(df, lang = "es", sw = NULL)` |
| Emojis más usados | `plotEmojis(df, top_n = 10)` / `plotEmojisPNG(df)` (necesita `ggimage`) |
| Hashtags por tweet | `getTweetsHashtags(df)` |
| Sentimiento / discurso de odio (OpenAI) | `getTweetsSentiments(df$texto)` |
| Clasificar imágenes (OpenAI) | `getTweetsImagesAnalysis(urls)` → `HTMLImgReport(res, "reporte.html")` |

Notas de argumentos:

- `username` va sin `@`. `getTweetsTimelinesAPI()` acepta `"NASA"`, `"@NASA"`
  o la URL del perfil.
- `getTweetsSearchAPI()` acepta los operadores de búsqueda de X dentro de
  `search`: `from:cuenta`, `to:cuenta`, `#hashtag`, `lang:es`, `"frase exacta"`,
  `-palabra`, `min_faves:100`, `filter:media`, `OR`. `product`: `"Latest"`
  (recientes), `"Top"` (destacados) o `"Media"`. `since`/`until` en
  `"YYYY-MM-DD"`.
- Las URLs de tweets tienen la forma `https://x.com/<cuenta>/status/<id>`.

## Qué devuelven

**Tweets** (`getUserTweetsAPI`, `getTweetsTimelinesAPI`, `getTweetsSearchAPI`,
`getTweetsRepliesAPI`, `getTweetsDataAPI`, `getUserMediaAPI`,
`getListTweetsAPI`): un tibble, una fila por tweet, 31 columnas:

`fecha` (POSIXct UTC), `user` (con `@`), `texto` (completo, también en tweets
largos), `idioma`, `respuestas`, `retweets`, `citas`, `megustas`, `views`,
`emoticones` (lista), `hashtags` (lista), `menciones` (lista), `urls_externas`
(lista), `media` (lista de URLs), `media_tipo` (lista: photo/video/animated_gif),
`es_retweet`, `es_cita`, `tweet_citado_id`, `conversation_id`, `url`,
`tweet_id`, `user_id`, `respuesta_a_id`, `respuesta_a_user`, `retweet_id`,
`guardados`, `fuente` (app de publicación), `sensible`, `editado`, `lugar`,
`pais`.

**Usuarixs** (`getUsersDataAPI`, `getUsersSearchAPI`, `getUserFollowersAPI`,
`getUserFollowingAPI`, `getTweetsRetweetsAPI`, `getListMembersAPI`): una fila
por cuenta, 18 columnas: `user`, `nombre`, `user_id`, `descripcion`,
`seguidores`, `siguiendo`, `tweets`, `favoritos`, `verificado`, `ubicacion`,
`sitio_web`, `imagen_perfil`, `banner`, `fecha_creacion` (POSIXct UTC), `url`,
`tweets_media`, `protegida`, `tipo_verificacion`.

**Acerca de la cuenta** (`getUsersAboutAPI`): `user`, `nombre`, `user_id`,
`pais_cuenta`, `ubicacion_precisa`, `cambios_usuario`,
`ultimo_cambio_usuario`, `afiliada_a`, `origen_cuenta`,
`identidad_verificada`, `verificada_desde`, `fecha_creacion`, `url`. X no
publica todos los campos para todas las cuentas (quedan en NA).

Las columnas lista se exploran con `tidyr::unnest()` o `unlist()`.

## Recetas

Actividad de una cuenta por día:

```r
tw_nasa <- getUserTweetsAPI("NASA", n_tweets = 200, save = FALSE)
plotTime(tw_nasa, group_by = "day")
```

Tweets más difundidos de una búsqueda:

```r
rstats <- getTweetsSearchAPI("#RStats lang:es", n_tweets = 300,
                             since = "2026-01-01", save = FALSE)
rstats |>
  dplyr::arrange(dplyr::desc(retweets)) |>
  dplyr::select(fecha, user, texto, retweets, megustas, url) |>
  head(10)
```

Hashtags más frecuentes:

```r
rstats |>
  tidyr::unnest(hashtags) |>
  dplyr::count(hashtags, sort = TRUE)
```

Analizar solo fotos (excluí videos, la API de imágenes no los procesa):

```r
media <- tidyr::unnest(tw_nasa, c(media, media_tipo))
fotos <- media$media[media$media_tipo == "photo"]
res <- getTweetsImagesAnalysis(head(fotos, 10))
HTMLImgReport(res, output_file = "reporte_imagenes.html")
```

Red de seguidorxs con perfil completo:

```r
seg <- getUserFollowersAPI("rstatstweet", n_users = 200, save = FALSE)
dplyr::arrange(seg, dplyr::desc(seguidores))
```

## Errores frecuentes

| Mensaje | Qué hacer |
|---|---|
| "No hay una sesión activa de X" | Correr `importSessionX()` con cookies frescas. |
| "Tu sesión de X parece haber expirado" | Volver a copiar `auth_token` y `ct0` del navegador y reimportar. |
| "Cuenta ... desactivada: ..." (mensaje) | X rechazó esa sesión; se sigue con otra cuenta del pool. Reimportarla con cookies frescas o `reactivateAccountX()`. |
| "Todas las cuentas están en pausa para ..." | Se agotó el cupo de X en todas las cuentas; el resultado es parcial. Esperar a la hora indicada o sumar cuentas. |
| "Respuesta no-JSON del motor salteada" | X cortó a mitad de camino; el resultado es parcial. |
| "El motor Node/Playwright no está instalado" | `installPlaywrightEngine()`. |
| "No se encontró Node.js" | Instalar Node.js >= 18 o `options(TweetScraperR.node = "ruta/a/node")`. |
| "salida no-JSON del motor" con `stderr` | Mostrar el `stderr` a la persona; suele ser Chromium faltante → reinstalar el motor. |
| "Se requiere una clave de API de OpenAI" | Definir `OPENAI_API_KEY` en `~/.Renviron`. |
| `lazy-load database ... is corrupt` | Se reinstaló el paquete con la sesión abierta: reiniciar R. |
| 0 filas sin error | La cuenta es privada, no existe o no tiene tweets en ese rango; verificar el nombre. |

Cuando una función devuelve menos tweets que `n_tweets`, no es un error: X
entrega lo que tiene disponible para esa consulta.
