# Cargar la biblioteca TweetScraperR
require(TweetScraperR)

# Abrir una sesión de Twitter sin mostrar la ventana del navegador
openTwitter(view = FALSE)

# Mostrar la vista actual de Twitter
twitter$view()

# Cerrar la sesión de Twitter
closeTwitter()

# Abrir la línea de tiempo de Twitter sin mostrar la ventana del navegador
openTimeline(view = FALSE)

# Mostrar la vista actual de la línea de tiempo
timeline$view()

# Cerrar la línea de tiempo
closeTimeline()

# Abrir una nueva sesión de Twitter
openTwitter()
# Abrir la línea de tiempo sin mostrar la ventana del navegador
openTimeline(view = FALSE)

# Obtener y guardar las URLs de los tweets mientras se desplaza por la línea de tiempo
getScrollExtractUrls(save = TRUE)

# Cerrar la línea de tiempo y la sesión de Twitter
closeTimeline()
closeTwitter()

# Combinar las URLs obtenidas de diferentes fuentes
urls_uni <- c(timeline_urls, timeline_rstatstweet_2024_11_19_20_02_22)

# Eliminar URLs duplicadas
urls_uni <- unique(urls_uni)

# Abrir una nueva sesión de Twitter
openTwitter()
# Abrir la línea de tiempo de un usuario específico sin mostrar la ventana del navegador
openTimeline(username = "agusnieto77", view = FALSE)

# Obtener tweets del usuario especificado
tweets_agusnieto77 <- getScrollExtract(username = "agusnieto77")

# Cerrar la línea de tiempo y la sesión de Twitter
closeTimeline()
closeTwitter()

# Seleccionar las primeras 10 URLs únicas
urls <- urls_uni[1:10]

# Abrir una nueva sesión de Twitter
openTwitter()

# Obtener datos completos de los tweets a partir de las URLs seleccionadas
tweets_full <- getTweetsData(
  urls_tweets = urls,
  save = FALSE
)

# Cerrar la sesión de Twitter
closeTwitter()

# Realizar una búsqueda completa de tweets con varios parámetros
getTweetsFullSearch(
  search_all = "Milei",
  search_exact = NULL,
  search_any = NULL,
  no_search = NULL,
  hashtag = NULL,
  lan = NULL,
  from = NULL,
  to = NULL,
  men = NULL,
  rep = 0,
  fav = 2,
  rt = 1,
  timeout = 10,
  n_tweets = 100,
  since = Sys.Date() - 7,
  until = Sys.Date(),
  save = FALSE
)

# Extraer hashtags de los tweets de un usuario específico
hashtags <- getTweetsHashtags(tweets_agusnieto77)

# Obtener tweets históricos con un hashtag específico
rstats_hashtags <- getTweetsHistoricalHashtag(
  hashtag = "#rstats",
  n_tweets = 100,
  since = "2018-10-26",
  until = "2018-10-30",
  save = FALSE
)

# Realizar una búsqueda histórica de tweets
tweets_search_2 <- getTweetsHistoricalSearch(
  search = "Javier Milei",
  timeout = 4,
  n_tweets = 120,
  since = "2018-10-26",
  until = "2023-10-30",
  live = FALSE,
  save = FALSE
)

# Combinar resultados de búsquedas
unificados <- rbind(tweets_search, tweets_search_2)

# Extraer datos de los tweets unificados
unificados_df <- extractTweetsData(unificados)

# Obtener tweets históricos de la línea de tiempo de un usuario
historical_timeline <- getTweetsHistoricalTimeline(
  username = "AAS_Sociologia",
  timeout = 2,
  n_tweets = 80,
  since = "2018-10-26",
  until = "2020-10-30",
  save = FALSE
)

# Obtener tweets actuales de la línea de tiempo de un usuario
timeline_actual <- getTweetsTimeline(
  username = "rstatstweet",
  n_tweets = 160,
  view = TRUE,
  mailx = "agustin.nieto77@gmail.com",
  save = FALSE
)

# Obtener URLs de tweets de la línea de tiempo de un usuario
getUrlsTweetsTimeline(username = "rstatstweet", n_urls = 200, save = FALSE)

# Obtener URLs históricas de la línea de tiempo de un usuario
urls_timeline <- getUrlsHistoricalTimeline(
  username = "AAS_Sociologia",
  timeout = 1,
  n_urls = 150,
  since = "2016-10-26",
  until = "2020-10-30",
  save = FALSE
)

# Obtener URLs de tweets en tiempo real basados en una búsqueda
getUrlsSearchStreaming(
  search = "#MarDelPlata",
  timeout = 1,
  n_urls = 10,
  save = FALSE
)

# Obtener tweets en tiempo real basados en una búsqueda
search_streaming <- getTweetsSearchStreaming(
  search = "Messi",
  timeout = 12,
  n_tweets = 80,
  save = FALSE
)

# Extraer URLs de usuarios de los tweets unificados
urls_users <- unique(gsub("@", "https://x.com/", unificados$user))[1:20]

# Obtener datos básicos de usuarios
user_data <- getUsersData(
  urls_users = urls_users,
  save = FALSE
)

# Obtener datos completos de usuarios
user_data_2 <- getUsersFullData(
  urls_users = urls_users,
  save = FALSE
)

# Obtener URLs de tweets basados en una búsqueda
getUrlsTweetsSearch(search = "#RStats", n_urls = 20, save = FALSE)

# Obtener URLs de respuestas a un tweet específico
respuestas <- getUrlsTweetsReplies(
  url = "https://x.com/LANACION/status/1718779652913696847",
  n_urls = 100,
  save = FALSE
)

# Descargar imágenes de tweets
getTweetsImages(urls = unificados_df$links_img_post, directorio = "img_x")

# Seleccionar tweets únicos para análisis de sentimientos
tweets_sent <- unique(dplyr::filter(dplyr::arrange(unificados_df, desc(megustas)) , !is.na(texto))$texto[1:21])

# Realizar análisis de sentimientos en los tweets seleccionados
tweets_sent_ok <- getTweetsSentiments(
  tweets = tweets_sent,
  api_key = Sys.getenv("OPENAI_API_KEY"),
  model = "gpt-4o-mini",
  dir = getwd()
)

# Preparar URLs de imágenes para análisis
urls_img <- paste0("./img_demo/", list.files("./img_demo"))

# Realizar análisis de imágenes de tweets
tweets_analysis_img <- getTweetsImagesAnalysis(
  img_sources = urls_img,
  modelo = "gpt-4o-mini",
  api_key = Sys.getenv("OPENAI_API_KEY"),
  dir = getwd()
)

# Cambiar el directorio de trabajo
setwd("./img_demo")

# Generar un informe HTML de análisis de imágenes
HTMLImgReport(tweets_analysis_img)

# Generar gráficos de análisis
plotTime(unificados_df)
plotWords(unificados_df, sw = c("Javier", "Milei"))
plotEmojis(unificados_df)
plotEmojisPNG(unificados_df)

# Funciones para descarga masiva 
getTweetsHistoricalTimelineFor()
getTweetsHistoricalHashtagFor()

getTweetsSearchStreamingFor(
  iterations = 5,
  search = "Milei",
  n_tweets = 6,
  dir = "./data/tweets",
  system = "windows",
  sleep_time = 1
)

getTweetsHistoricalSearchFor(
  iterations = 3,
  search = "cambio climático",
  n_tweets = 6,
  since = "2023-01-01_15:55:00_UTC",
  until = 7,
  interval_unit = "days",
  live = FALSE,
  dir = "./data/tweets",
  system = "windows",
  sleep_time = 4
)
