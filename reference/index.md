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

## Funciones deprecadas (scraping por HTML)

Reemplazadas por las funciones `*API()`, más robustas. Siguen
funcionando pero emiten una advertencia de ciclo de vida.

- [`getTweetsTimeline()`](https://agusnieto77.github.io/TweetScraperR/reference/getTweetsTimeline.md)
  : Get Tweets from User Timeline
- [`getTweetsTimelineFor()`](https://agusnieto77.github.io/TweetScraperR/reference/getTweetsTimelineFor.md)
  : Get Tweets from Multiple Users Iteratively
- [`getTweetsHistoricalSearch()`](https://agusnieto77.github.io/TweetScraperR/reference/getTweetsHistoricalSearch.md)
  : Get Historical Tweets from a Specific Search
- [`getTweetsHistoricalSearchFor()`](https://agusnieto77.github.io/TweetScraperR/reference/getTweetsHistoricalSearchFor.md)
  : Get Historical Tweets Iteratively
- [`getTweetsHistoricalHashtag()`](https://agusnieto77.github.io/TweetScraperR/reference/getTweetsHistoricalHashtag.md)
  : Get Historical Tweets with a Specific Hashtag
- [`getTweetsHistoricalHashtagFor()`](https://agusnieto77.github.io/TweetScraperR/reference/getTweetsHistoricalHashtagFor.md)
  : Get Historical Tweets with Hashtags Iteratively
- [`getTweetsHistoricalTimeline()`](https://agusnieto77.github.io/TweetScraperR/reference/getTweetsHistoricalTimeline.md)
  : Get Historical Tweets from a User Timeline
- [`getTweetsHistoricalTimelineFor()`](https://agusnieto77.github.io/TweetScraperR/reference/getTweetsHistoricalTimelineFor.md)
  : Get Historical Tweets from User Timeline Iteratively
- [`getTweetsFullSearch()`](https://agusnieto77.github.io/TweetScraperR/reference/getTweetsFullSearch.md)
  : Get Tweets from a Full Search
- [`getTweetsSearchStreaming()`](https://agusnieto77.github.io/TweetScraperR/reference/getTweetsSearchStreaming.md)
  : Get Live Tweet by Search
- [`getTweetsSearchStreaming2()`](https://agusnieto77.github.io/TweetScraperR/reference/getTweetsSearchStreaming2.md)
  : Get Live Tweet by Search II
- [`getTweetsSearchStreamingFor()`](https://agusnieto77.github.io/TweetScraperR/reference/getTweetsSearchStreamingFor.md)
  : Get Iterative Tweets in Streaming
- [`getTweetsSearchStreamingFor2()`](https://agusnieto77.github.io/TweetScraperR/reference/getTweetsSearchStreamingFor2.md)
  : Get Iterative Tweets in Streaming II
- [`getTweetsCites()`](https://agusnieto77.github.io/TweetScraperR/reference/getTweetsCites.md)
  : Get Tweets Cites with Data
- [`getTweetsReplies()`](https://agusnieto77.github.io/TweetScraperR/reference/getTweetsReplies.md)
  : Get Tweets Replies with Data
- [`getTweetsRetweets()`](https://agusnieto77.github.io/TweetScraperR/reference/getTweetsRetweets.md)
  : Get Users Retweets with Data
- [`getTweetsData()`](https://agusnieto77.github.io/TweetScraperR/reference/getTweetsData.md)
  : Get Tweets Data
- [`getTweetsData2()`](https://agusnieto77.github.io/TweetScraperR/reference/getTweetsData2.md)
  : Get Tweets Data II
- [`getTweetsImages()`](https://agusnieto77.github.io/TweetScraperR/reference/getTweetsImages.md)
  : Get Tweets Images
- [`getUsersData()`](https://agusnieto77.github.io/TweetScraperR/reference/getUsersData.md)
  : Get Users Data
- [`getUsersFullData()`](https://agusnieto77.github.io/TweetScraperR/reference/getUsersFullData.md)
  : Get Users Full Data
- [`getScrollExtract()`](https://agusnieto77.github.io/TweetScraperR/reference/getScrollExtract.md)
  : Extract Tweets from a Timeline by Scrolling
- [`getScrollExtractUrls()`](https://agusnieto77.github.io/TweetScraperR/reference/getScrollExtractUrls.md)
  : Extract Tweet URLs from a Timeline by Scrolling
- [`getUrlsTweetsSearch()`](https://agusnieto77.github.io/TweetScraperR/reference/getUrlsTweetsSearch.md)
  : Get Tweets URLs by Search
- [`getUrlsTweetsTimeline()`](https://agusnieto77.github.io/TweetScraperR/reference/getUrlsTweetsTimeline.md)
  : Get URLs of User Timeline Tweets
- [`getUrlsTweetsCites()`](https://agusnieto77.github.io/TweetScraperR/reference/getUrlsTweetsCites.md)
  : Get Tweets URLs Cites
- [`getUrlsTweetsReplies()`](https://agusnieto77.github.io/TweetScraperR/reference/getUrlsTweetsReplies.md)
  : Get Tweets URLs Replies
- [`getUrlsHistoricalTimeline()`](https://agusnieto77.github.io/TweetScraperR/reference/getUrlsHistoricalTimeline.md)
  : Get Historical Tweet URLs from a User Timeline
- [`getUrlsSearchStreaming()`](https://agusnieto77.github.io/TweetScraperR/reference/getUrlsSearchStreaming.md)
  : Get Live Tweet URLs by Search
- [`openTwitter()`](https://agusnieto77.github.io/TweetScraperR/reference/openTwitter.md)
  : Open Twitter Login Page
- [`closeTwitter()`](https://agusnieto77.github.io/TweetScraperR/reference/closeTwitter.md)
  : Close Twitter Session
- [`openTimeline()`](https://agusnieto77.github.io/TweetScraperR/reference/openTimeline.md)
  : Open Timeline User
- [`closeTimeline()`](https://agusnieto77.github.io/TweetScraperR/reference/closeTimeline.md)
  : Close Timeline Session
- [`userTwitter()`](https://agusnieto77.github.io/TweetScraperR/reference/userTwitter.md)
  : Input Twitter Username for Authentication
- [`passTwitter()`](https://agusnieto77.github.io/TweetScraperR/reference/passTwitter.md)
  : Input Twitter Password for Authentication
