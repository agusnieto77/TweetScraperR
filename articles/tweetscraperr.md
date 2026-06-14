# Scraping de X/Twitter con TweetScraperR

`TweetScraperR` recolecta datos de X/Twitter (tweets, usuarixs y
metadatos) para análisis y visualización. Esta viñeta describe el
**flujo recomendado**, basado en consultas a la API GraphQL interna de X
(datos estructurados, sin selectores HTML frágiles).

## 1. Instalar el motor (una vez por máquina)

El motor de scraping corre sobre **Node.js (\>= 18) + Playwright**. Se
instala una sola vez:

``` r

library(TweetScraperR)

# Descarga Playwright + el navegador Chromium dentro del paquete.
installPlaywrightEngine()

# Verifica que el motor quedó operativo.
checkPlaywrightEngine()
```

## 2. Importar tu sesión

X bloquea el login automatizado (detecta el navegador por
*fingerprint*). Por eso la sesión se importa desde **tu navegador
normal**, donde ya estás logueadx:

1.  Iniciá sesión en <https://x.com> en tu navegador habitual.
2.  Abrí las *DevTools* (F12) → pestaña **Application / Almacenamiento**
    → **Cookies** → `https://x.com`.
3.  Copiá los valores de las cookies **`auth_token`** y **`ct0`**.
4.  Importalos:

``` r

importSessionX(auth_token = "tu_auth_token", ct0 = "tu_ct0")
```

La sesión queda guardada en disco y **todas las funciones la reusan**
sin volver a loguearse. Cuando las cookies expiren, repetí el paso para
reimportarlas.

## 3. Recolectar datos (funciones `*API()`)

Las funciones `*API()` devuelven un `tibble` con datos estructurados:
texto completo, fecha exacta y métricas (respuestas, retweets, citas, me
gusta, vistas).

``` r

# Timeline de unx usuarix
tl <- getUserTweetsAPI("rstatstweet", n_tweets = 200)

# Búsqueda (Latest / Top / Media; soporta operadores como from:, since:, lang:)
busq <- getTweetsSearchAPI("#RStats lang:es", n_tweets = 200, product = "Latest")

# Respuestas / hilo de un tweet
hilo <- getTweetsRepliesAPI("https://x.com/NASA/status/123", n_tweets = 100)

# Datos de tweets a partir de sus URLs
datos <- getTweetsDataAPI(c(
  "https://x.com/NASA/status/123",
  "https://x.com/NASA/status/456"
))

# Media (fotos/videos) de unx usuarix
media <- getUserMediaAPI("NASA", n_tweets = 100)

# Redes de usuarixs
seguidores <- getUserFollowersAPI("rstatstweet", n_users = 200)
siguiendo  <- getUserFollowingAPI("rstatstweet", n_users = 200)
retweeters <- getTweetsRetweetsAPI("https://x.com/NASA/status/123", n_users = 200)

# Datos de perfil
perfiles <- getUsersDataAPI(c("NASA", "rstatstweet"))
```

Por defecto cada función guarda un archivo `.rds` con marca de tiempo en
el directorio de trabajo (`save = TRUE`); pasá `save = FALSE` para no
guardar.

## 4. Visualización y análisis

Sobre los datos recolectados podés usar las funciones de visualización
del paquete
([`plotTime()`](https://agusnieto77.github.io/TweetScraperR/reference/plotTime.md),
[`plotWords()`](https://agusnieto77.github.io/TweetScraperR/reference/plotWords.md),
[`plotEmojis()`](https://agusnieto77.github.io/TweetScraperR/reference/plotEmojis.md))
y de análisis con IA
([`getTweetsSentiments()`](https://agusnieto77.github.io/TweetScraperR/reference/getTweetsSentiments.md),
[`getTweetsImagesAnalysis()`](https://agusnieto77.github.io/TweetScraperR/reference/getTweetsImagesAnalysis.md)).

## Uso responsable

El scraping autenticado de X puede violar sus Términos de Servicio y
derivar en la suspensión de la cuenta. El contenido recolectado está
sujeto a los derechos de X y de sus autores. Usá cuentas dedicadas de
investigación y respetá la normativa de protección de datos aplicable.
