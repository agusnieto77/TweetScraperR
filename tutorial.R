# Carga la biblioteca TweetScraperR para el análisis de tweets
require(TweetScraperR)

# Inicia una sesión de Twitter en modo oculto (sin interfaz gráfica)
openTwitter(view = FALSE)

# Muestra la estructura del objeto Twitter (útil para depuración)
twitter$view()

# Cierra la sesión de Twitter
closeTwitter()

# Inicia una sesión del Timeline de Twitter en modo oculto
openTimeline(view = FALSE)

# Muestra la estructura del objeto Timeline (útil para depuración)
timeline$view()

# Cierra la sesión del Timeline
closeTimeline()

# Abre simultáneamente las interfaces de Twitter y Timeline
openTwitter()
openTimeline(view = FALSE)

# Extrae URLs del Timeline, desplazándose automáticamente, y las guarda en disco
getScrollExtractUrls(save = TRUE)

# Cierra las sesiones de Timeline y Twitter
closeTimeline()
closeTwitter()

# Combina URLs obtenidas de diferentes timelines y elimina duplicados
urls_uni <- c(timeline_urls, timeline_rstatstweet_2024_11_19_20_02_22)
urls_uni <- unique(urls_uni)

# Inicia sesiones de Twitter y Timeline para un usuario específico
openTwitter()
openTimeline(username = "agusnieto77", view = FALSE)

# Extrae tweets desplazándose por el Timeline del usuario especificado
tweets_agusnieto77 <- getScrollExtract(username = "agusnieto77")

# Cierra las sesiones de Timeline y Twitter
closeTimeline()
closeTwitter()

# Selecciona las primeras 10 URLs únicas para análisis
urls <- urls_uni[1:10]

# Inicia una sesión de Twitter y extrae datos detallados de los tweets correspondientes a las URLs seleccionadas
openTwitter()
tweets_full <- getTweetsData(
  urls_tweets = urls,
  save = FALSE
)
closeTwitter()

# Realiza una búsqueda avanzada de tweets usando diversos filtros
getTweetsFullSearch(
  search_all = "Milei",      # Palabra clave para buscar
  rep = 0,                   # Mínimo de respuestas requeridas
  fav = 2,                   # Mínimo de favoritos requeridos
  rt = 1,                    # Mínimo de retweets requeridos
  timeout = 10,              # Tiempo de espera máximo para cada intento (en segundos)
  n_tweets = 100,            # Número de tweets a extraer
  since = Sys.Date() - 7,    # Fecha de inicio del período de búsqueda (7 días atrás)
  until = Sys.Date(),        # Fecha de fin del período de búsqueda (hoy)
  save = FALSE               # No guardar resultados en disco
)

# Extrae hashtags de los tweets recuperados del usuario agusnieto77
hashtags <- getTweetsHashtags(tweets_agusnieto77)

# Obtiene tweets históricos con un hashtag específico (#rstats)
rstats_hashtags <- getTweetsHistoricalHashtag(
  hashtag = "#rstats",
  n_tweets = 100,
  since = "2018-10-26",
  until = "2018-10-30",
  save = FALSE
)

# Realiza una búsqueda histórica de tweets con un término específico
tweets_search_2 <- getTweetsHistoricalSearch(
  search = "Javier Milei",
  timeout = 4,
  n_tweets = 120,
  since = "2018-10-26",
  until = "2023-10-30",
  live = FALSE,
  save = FALSE
)

# Combina resultados de múltiples búsquedas en un único DataFrame
unificados <- rbind(tweets_search, tweets_search_2)
unificados_df <- extractTweetsData(unificados)

# Obtiene el Timeline histórico de un usuario específico
historical_timeline <- getTweetsHistoricalTimeline(
  username = "AAS_Sociologia",
  timeout = 2,
  n_tweets = 80,
  since = "2018-10-26",
  until = "2020-10-30",
  save = FALSE
)

# Obtiene el Timeline actual de un usuario específico
timeline_actual <- getTweetsTimeline(
  username = "rstatstweet",
  n_tweets = 160,
  view = TRUE,
  mailx = "agustin.nieto77@gmail.com",
  save = FALSE
)

# Extrae URLs de tweets desde un Timeline histórico de un usuario
urls_timeline <- getUrlsHistoricalTimeline(
  username = "AAS_Sociologia",
  timeout = 1,
  n_urls = 150,
  since = "2016-10-26",
  until = "2020-10-30",
  save = FALSE
)

# Obtiene datos de tweets de un streaming de búsqueda en tiempo real
search_streaming <- getTweetsSearchStreaming(
  search = "Messi",
  timeout = 12,
  n_tweets = 80,
  save = FALSE
)

# Convierte nombres de usuarios en URLs y extrae datos básicos de perfil
urls_users <- unique(gsub("@", "https://x.com/", unificados$user))[1:20]
user_data <- getUsersData(
  urls_users = urls_users,
  save = FALSE
)

# Extrae datos completos de perfiles de usuarios
user_data_2 <- getUsersFullData(
  urls_users = urls_users,
  save = FALSE
)

# Realiza análisis de imágenes de tweets usando un modelo de IA
tweets_analysis_img <- getTweetsImagesAnalysis(
  img_sources = paste0("./img_demo/", list.files("./img_demo")),
  modelo = "gpt-4o-mini",
  api_key = Sys.getenv("OPENAI_API_KEY"),
  dir = getwd()
)

# Crea un informe HTML con el análisis de imágenes
setwd("./img_demo")
HTMLImgReport(tweets_analysis_img)

# Visualiza la distribución temporal de los tweets
plotTime(unificados_df)

# Visualiza las palabras más frecuentes en los tweets (excluyendo "Javier" y "Milei")
plotWords(unificados_df, sw = c("Javier", "Milei"))

# Visualiza los emojis más utilizados en los tweets
plotEmojis(unificados_df)
plotEmojisPNG(unificados_df)