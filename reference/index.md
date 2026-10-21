# Package index

## Sesión, pool de cuentas y motor

Instalar el motor de Node.js/Playwright e importar tus sesiones reales
de X a partir de las cookies del navegador. Con varias cuentas, la
recolección rota sola cuando una agota el cupo de X.

- [`importSessionX()`](https://agusnieto77.github.io/TweetScraperR/reference/importSessionX.md)
  : Importar una sesion de X/Twitter desde las cookies de tu navegador
- [`setupAccountsX()`](https://agusnieto77.github.io/TweetScraperR/reference/setupAccountsX.md)
  : Cargar y validar cuentas de X desde la consola
- [`addAccountsX()`](https://agusnieto77.github.io/TweetScraperR/reference/addAccountsX.md)
  : Agregar varias cuentas al pool de una vez
- [`accountsX()`](https://agusnieto77.github.io/TweetScraperR/reference/accountsX.md)
  : Estado del pool de cuentas de X
- [`setProxyX()`](https://agusnieto77.github.io/TweetScraperR/reference/setProxyX.md)
  : Asignar, cambiar o quitar el proxy de cuentas del pool
- [`checkAccountsX()`](https://agusnieto77.github.io/TweetScraperR/reference/checkAccountsX.md)
  : Validar las sesiones del pool de cuentas
- [`reactivateAccountX()`](https://agusnieto77.github.io/TweetScraperR/reference/reactivateAccountX.md)
  : Reactivar cuentas desactivadas del pool
- [`resetLocksX()`](https://agusnieto77.github.io/TweetScraperR/reference/resetLocksX.md)
  : Quitar las pausas de rate-limit de todas las cuentas
- [`removeAccountX()`](https://agusnieto77.github.io/TweetScraperR/reference/removeAccountX.md)
  : Eliminar cuentas del pool
- [`installPlaywrightEngine()`](https://agusnieto77.github.io/TweetScraperR/reference/installPlaywrightEngine.md)
  : Instalar el motor Node/Playwright (npm install + navegador)
- [`checkPlaywrightEngine()`](https://agusnieto77.github.io/TweetScraperR/reference/checkPlaywrightEngine.md)
  : Comprobar que el motor Node/Playwright esta instalado y operativo
- [`loginX()`](https://agusnieto77.github.io/TweetScraperR/reference/loginX.md)
  : Iniciar sesion en X/Twitter con Playwright y guardar la sesion

## Scraping de tweets (API)

Consultan la API GraphQL interna de X y devuelven datos estructurados
desde JSON (texto completo, métricas, media, hashtags, menciones, etc.).

- [`getUserTweetsAPI()`](https://agusnieto77.github.io/TweetScraperR/reference/getUserTweetsAPI.md)
  : Get Tweets from a User Timeline via the X API (experimental)
- [`getTweetsTimelinesAPI()`](https://agusnieto77.github.io/TweetScraperR/reference/getTweetsTimelinesAPI.md)
  : Get the Combined Timeline of Several Users via the X API
  (experimental)
- [`getTweetsSearchAPI()`](https://agusnieto77.github.io/TweetScraperR/reference/getTweetsSearchAPI.md)
  : Search Tweets via the X API (experimental)
- [`getTweetsLiveAPI()`](https://agusnieto77.github.io/TweetScraperR/reference/getTweetsLiveAPI.md)
  : Capture Tweets from a Search as They Are Published (experimental)
- [`getTweetsRepliesAPI()`](https://agusnieto77.github.io/TweetScraperR/reference/getTweetsRepliesAPI.md)
  : Get Tweet Replies / Thread via the X API (experimental)
- [`getTweetsDataAPI()`](https://agusnieto77.github.io/TweetScraperR/reference/getTweetsDataAPI.md)
  : Get Tweet Data from URLs via the X API (experimental)
- [`getUserMediaAPI()`](https://agusnieto77.github.io/TweetScraperR/reference/getUserMediaAPI.md)
  : Get a User's Media Tweets via the X API (experimental)
- [`getListTweetsAPI()`](https://agusnieto77.github.io/TweetScraperR/reference/getListTweetsAPI.md)
  : Get the Tweets of an X List via the X API (experimental)

## Usuarios y redes (API)

- [`getUsersDataAPI()`](https://agusnieto77.github.io/TweetScraperR/reference/getUsersDataAPI.md)
  : Get a User's Profile Data via the X API (experimental)
- [`getUsersAboutAPI()`](https://agusnieto77.github.io/TweetScraperR/reference/getUsersAboutAPI.md)
  : Get the "About this account" Data of Users via the X API
  (experimental)
- [`getUsersSearchAPI()`](https://agusnieto77.github.io/TweetScraperR/reference/getUsersSearchAPI.md)
  : Search Users via the X API (experimental)
- [`getUserFollowersAPI()`](https://agusnieto77.github.io/TweetScraperR/reference/getUserFollowersAPI.md)
  : Get a User's Followers via the X API (experimental)
- [`getUserFollowingAPI()`](https://agusnieto77.github.io/TweetScraperR/reference/getUserFollowingAPI.md)
  : Get the Accounts a User Follows via the X API (experimental)
- [`getTweetsRetweetsAPI()`](https://agusnieto77.github.io/TweetScraperR/reference/getTweetsRetweetsAPI.md)
  : Get the Users Who Retweeted a Tweet via the X API (experimental)
- [`getListMembersAPI()`](https://agusnieto77.github.io/TweetScraperR/reference/getListMembersAPI.md)
  : Get the Members of an X List via the X API (experimental)

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

## Agentes de IA

- [`installAgentSkill()`](https://agusnieto77.github.io/TweetScraperR/reference/installAgentSkill.md)
  : Install the TweetScraperR Skill for AI Agents
