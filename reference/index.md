# Package index

## Sesión y motor

Instalar el motor de Node.js/Playwright e importar tu sesión real de X a
partir de las cookies del navegador.

- [`importSessionX()`](https://agusnieto77.github.io/TweetScraperR/reference/importSessionX.md)
  : Importar una sesion de X/Twitter desde las cookies de tu navegador
- [`installPlaywrightEngine()`](https://agusnieto77.github.io/TweetScraperR/reference/installPlaywrightEngine.md)
  : Instalar el motor Node/Playwright (npm install + browsers)
- [`checkPlaywrightEngine()`](https://agusnieto77.github.io/TweetScraperR/reference/checkPlaywrightEngine.md)
  : Comprobar que el motor Node/Playwright esta instalado y operativo
- [`loginX()`](https://agusnieto77.github.io/TweetScraperR/reference/loginX.md)
  : Iniciar sesion en X/Twitter con Playwright y guardar la sesion

## Scraping de tweets (API — recomendado)

Consultan la API GraphQL interna de X y devuelven datos estructurados
desde JSON (texto completo, métricas, media, hashtags, menciones, etc.).

- [`getUserTweetsAPI()`](https://agusnieto77.github.io/TweetScraperR/reference/getUserTweetsAPI.md)
  : Get Tweets from a User Timeline via the X API (experimental)
- [`getTweetsTimelinesAPI()`](https://agusnieto77.github.io/TweetScraperR/reference/getTweetsTimelinesAPI.md)
  : Get the Combined Timeline of Several Users via the X API
  (experimental)
- [`getTweetsSearchAPI()`](https://agusnieto77.github.io/TweetScraperR/reference/getTweetsSearchAPI.md)
  : Search Tweets via the X API (experimental)
- [`getTweetsRepliesAPI()`](https://agusnieto77.github.io/TweetScraperR/reference/getTweetsRepliesAPI.md)
  : Get Tweet Replies / Thread via the X API (experimental)
- [`getTweetsDataAPI()`](https://agusnieto77.github.io/TweetScraperR/reference/getTweetsDataAPI.md)
  : Get Tweet Data from URLs via the X API (experimental)
- [`getUserMediaAPI()`](https://agusnieto77.github.io/TweetScraperR/reference/getUserMediaAPI.md)
  : Get a User's Media Tweets via the X API (experimental)

## Usuarios y redes (API)

- [`getUsersDataAPI()`](https://agusnieto77.github.io/TweetScraperR/reference/getUsersDataAPI.md)
  : Get a User's Profile Data via the X API (experimental)
- [`getUserFollowersAPI()`](https://agusnieto77.github.io/TweetScraperR/reference/getUserFollowersAPI.md)
  : Get a User's Followers via the X API (experimental)
- [`getUserFollowingAPI()`](https://agusnieto77.github.io/TweetScraperR/reference/getUserFollowingAPI.md)
  : Get the Accounts a User Follows via the X API (experimental)
- [`getTweetsRetweetsAPI()`](https://agusnieto77.github.io/TweetScraperR/reference/getTweetsRetweetsAPI.md)
  : Get the Users Who Retweeted a Tweet via the X API (experimental)

## Visualización

- [`plotTime()`](https://agusnieto77.github.io/TweetScraperR/reference/plotTime.md)
  : Create Line Graph of Tweets by Time
- [`plotWords()`](https://agusnieto77.github.io/TweetScraperR/reference/plotWords.md)
  : Create Word Cloud from Tweets
- [`plotEmojis()`](https://agusnieto77.github.io/TweetScraperR/reference/plotEmojis.md)
  : Create Bar Chart of Emoticons in Tweets
- [`plotEmojisPNG()`](https://agusnieto77.github.io/TweetScraperR/reference/plotEmojisPNG.md)
  : Create Bar Chart of EmoticonsPNG in Tweets

## Análisis y utilidades

- [`getTweetsSentiments()`](https://agusnieto77.github.io/TweetScraperR/reference/getTweetsSentiments.md)
  : Analyze sentiments of tweets
- [`getTweetsImagesAnalysis()`](https://agusnieto77.github.io/TweetScraperR/reference/getTweetsImagesAnalysis.md)
  : Analyze images of tweets
- [`HTMLImgReport()`](https://agusnieto77.github.io/TweetScraperR/reference/HTMLImgReport.md)
  : Generate HTML visualization of analyzed images
- [`getTweetsHashtags()`](https://agusnieto77.github.io/TweetScraperR/reference/getTweetsHashtags.md)
  : Get Hashtags from Tweets
- [`extractTweetsData()`](https://agusnieto77.github.io/TweetScraperR/reference/extractTweetsData.md)
  : Extracts Relevant Information from Locally Stored Tweets
- [`getTweetsXquikSearch()`](https://agusnieto77.github.io/TweetScraperR/reference/getTweetsXquikSearch.md)
  : Get Tweets by Search with Xquik
