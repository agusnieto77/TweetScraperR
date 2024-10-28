
<!-- README.md is generated from README.Rmd. Please edit that file -->

# TweetScraperR<img src="man/figures/hex-twitterscraper.svg" align="right" height="320"/>

<!-- badges: start -->

[![Project Status: Active – The project has reached a stable, usable
state and is being actively
developed.](https://www.repostatus.org/badges/latest/active.svg)](https://www.repostatus.org/#active)
[![](https://img.shields.io/badge/devel%20version-0.1.0.12-blue.svg)](https://github.com/agusnieto77/TweetScraperR)
[![License:
MIT](https://img.shields.io/badge/license-MIT-blue.svg)](https://cran.r-project.org/web/licenses/MIT)
[![](https://img.shields.io/github/languages/code-size/agusnieto77/TweetScraperR.svg)](https://github.com/agusnieto77/TweetScraperR)
[![](https://img.shields.io/badge/Lifecycle-Experimental-ff7f2a)](https://lifecycle.r-lib.org/articles/stages.html#experimental)
[![](https://img.shields.io/badge/Build%20with-R%20&%20RStudio-blue?style=plastic=appveyor)](https://github.com/agusnieto77/TweetScraperR)
[![](https://img.shields.io/badge/TweetScraperR-ready%20to%20use-color:%20#39c?style=plastic=appveyor)](https://github.com/agusnieto77/TweetScraperR)
[![](https://camo.githubusercontent.com/0c51a4ac8aeb1237635011c4ee0ce3a74b73d541bc2d75bc8ca1cc301cd2ce20/68747470733a2f2f7777772e722d706b672e6f72672f6261646765732f76657273696f6e2f6372727269)](https://camo.githubusercontent.com/0c51a4ac8aeb1237635011c4ee0ce3a74b73d541bc2d75bc8ca1cc301cd2ce20/68747470733a2f2f7777772e722d706b672e6f72672f6261646765732f76657273696f6e2f6372727269)

<!-- badges: end -->

### Vision general

Este paquete proporciona funciones para extraer datos de X/Twitter,
incluidos tweets, usuarixs y metadatos asociados, permitiendo realizar
la extracción y manejo de estos datos de manera conveniente en R.
Enfocado en facilitar la recolección de datos para análisis y
visualización, el paquete puede obtener tweets desde la búsqueda de
X/Twitter y está construido sobre rvest, sin utilizar las API de
X/Twitter. Aunque los datos rastreados no son tan limpios como los
obtenidos a través de las API, el costo actual de las API hace que esta
sea una alternativa flexible, gratuita y de código abierto.

This package provides functions to extract data from X/Twitter,
including tweets, users, and associated metadata, allowing for
convenient data extraction and handling in R. Focused on facilitating
data collection for analysis and visualization, the package can obtain
tweets from X/Twitter search and is built on rvest, without using the
X/Twitter APIs. Although the scraped data is not as clean as that
obtained through the APIs, the current cost of the APIs makes this a
flexible, free, and open-source alternative.

### Instalacion de la version en desarrollo

Puedes instalar la versión de desarrollo de TweetScraperR desde
[GitHub](https://github.com/) con:

``` r
# install.packages("devtools")
devtools::install_github("agusnieto77/TweetScraperR")
```

### Funciones

| Nombre | Ciclo | Descripción |
|:---|:---|:---|
| `closeTimeline()` | ![](https://lifecycle.r-lib.org/articles/figures/lifecycle-experimental.svg) | Cierre de Timeline. |
| `closeTwitter()` | ![](https://lifecycle.r-lib.org/articles/figures/lifecycle-experimental.svg) | Cierre de sesión. |
| `extractTweetsData()` | ![](https://lifecycle.r-lib.org/articles/figures/lifecycle-experimental.svg) | Extrae información relevante de tweets almacenados localmente. |
| `getScrollExtract()` | ![](https://lifecycle.r-lib.org/articles/figures/lifecycle-experimental.svg) | Scrolea y extrae tweets. |
| `getScrollExtractUrls()` | ![](https://lifecycle.r-lib.org/articles/figures/lifecycle-experimental.svg) | Scrolea y extrae URLs de tweets. |
| `getTweetsData()` | ![](https://lifecycle.r-lib.org/articles/figures/lifecycle-experimental.svg) | Recupera datos de tweets a partir de URLs. |
| `getTweetsFullSearch()` | ![](https://lifecycle.r-lib.org/articles/figures/lifecycle-experimental.svg) | Recupera tweets desde la búsqueda avanzada. |
| `getTweetsHashtags()` | ![](https://lifecycle.r-lib.org/articles/figures/lifecycle-experimental.svg) | Recupera los hashtags de la columna 'texto'. |
| `getTweetsHistoricalHashtag()` | ![](https://lifecycle.r-lib.org/articles/figures/lifecycle-experimental.svg) | Recupera tweets históricos con un hashtag específico. |
| `getTweetsHistoricalHashtagFor()` | ![](https://lifecycle.r-lib.org/articles/figures/lifecycle-experimental.svg) | Recupera tweets históricos con un hashtag específico en un ciclo `for`. |
| `getTweetsHistoricalSearch()` | ![](https://lifecycle.r-lib.org/articles/figures/lifecycle-experimental.svg) | Recupera tweets históricos con un término específico. |
| `getTweetsHistoricalSearchFor()` | ![](https://lifecycle.r-lib.org/articles/figures/lifecycle-experimental.svg) | Recupera tweets históricos con un término específico en un ciclo `for`. |
| `getTweetsHistoricalTimeline()` | ![](https://lifecycle.r-lib.org/articles/figures/lifecycle-experimental.svg) | Recupera tweets históricos de un timeline. |
| `getTweetsHistoricalTimelineFor()` | ![](https://lifecycle.r-lib.org/articles/figures/lifecycle-experimental.svg) | Recupera tweets históricos de un timeline en un ciclo `for`. |
| `getTweetsImages()` | ![](https://lifecycle.r-lib.org/articles/figures/lifecycle-experimental.svg) | Descarga las imágenes posteadas en los tweets. |
| `getTweetsSearchStreaming()` | ![](https://lifecycle.r-lib.org/articles/figures/lifecycle-experimental.svg) | Recupera tweets en tiempo real. |
| `getTweetsSearchStreamingFor()` | ![](https://lifecycle.r-lib.org/articles/figures/lifecycle-experimental.svg) | Itera la recuperación de tweets en tiempo real. |
| `getTweetsTimeline()` | ![](https://lifecycle.r-lib.org/articles/figures/lifecycle-experimental.svg) | Recupera tweets de un timeline. |
| `getUrlsHistoricalTimeline()` | ![](https://lifecycle.r-lib.org/articles/figures/lifecycle-experimental.svg) | Recupera URLs de tweets históricos de un timeline. |
| `getUrlsSearchStreaming()` | ![](https://lifecycle.r-lib.org/articles/figures/lifecycle-experimental.svg) | Recupera URLs de tweets en tiempo real. |
| `getUrlsTweetsReplies()` | ![](https://lifecycle.r-lib.org/articles/figures/lifecycle-experimental.svg) | Recupera las URLs de las respuestas a un tweet. |
| `getUrlsTweetsSearch()` | ![](https://lifecycle.r-lib.org/articles/figures/lifecycle-experimental.svg) | Recupera URLs de tweets por búsqueda. |
| `getUrlsTweetsTimeline()` | ![](https://lifecycle.r-lib.org/articles/figures/lifecycle-experimental.svg) | Recupera URLs de tweets de un timeline. |
| `getUsersData()` | ![](https://lifecycle.r-lib.org/articles/figures/lifecycle-experimental.svg) | Recupera datos de users a partir de URLs. |
| `getUsersFullData()` | ![](https://lifecycle.r-lib.org/articles/figures/lifecycle-experimental.svg) | Recupera datos completos de users a partir de URLs. |
| `openTimeline()` | ![](https://lifecycle.r-lib.org/articles/figures/lifecycle-experimental.svg) | Accede al Timeline de un/a usuario/a. |
| `openTwitter()` | ![](https://lifecycle.r-lib.org/articles/figures/lifecycle-experimental.svg) | Inicio de sesión. |
| `plotEmojis()` | ![](https://lifecycle.r-lib.org/articles/figures/lifecycle-experimental.svg) | Hace un gráfico de barras en base a la columna 'emoticones'. |
| `plotEmojisPNG()` | ![](https://lifecycle.r-lib.org/articles/figures/lifecycle-experimental.svg) | Hace un gráfico de barras en base a la columna 'emoticones' con los PNG de los emojis. |
| `plotTime()` | ![](https://lifecycle.r-lib.org/articles/figures/lifecycle-experimental.svg) | Hace un gráfico de líneas en base a la columna 'texto'. |
| `plotWords()` | ![](https://lifecycle.r-lib.org/articles/figures/lifecycle-experimental.svg) | Hace una nube de palabras en base a la columna 'texto'. |

### Uso de las funciones del paquete {TweetScraperR}

``` r
# Cargamos la librería
require(TweetScraperR)

# Con la función getTweetsSearchStreaming() recolectamos en tiempo real los  
# tweets que mencionan el término de búsqueda, en este ejemplo es un hashtag.
# Esta función guarda un rds con los tweets y algunos metadatos.

urls_hashtagRstats <- getTweetsSearchStreaming(search = "#RStats", n_tweets = 20)
```

    #> Inició la recolección de tweets.
    #> Finalizó la recolección de tweets.
    #> Datos procesados y guardados.
    #> Tweets únicos recolectados: 8

``` r
urls_hashtagRstats
```

    #> # A tibble: 8 × 6
    #>   art_html  fecha               user             tweet url   fecha_captura      
    #>   <list>    <dttm>              <chr>            <chr> <chr> <dttm>             
    #> 1 <chr [1]> 2024-10-09 13:39:56 @BiochemistTomas "\nW… http… 2024-10-09 10:53:25
    #> 2 <chr [1]> 2024-10-09 13:22:23 @RodgersData     "\nA… http… 2024-10-09 10:53:25
    #> 3 <chr [1]> 2024-10-09 12:17:43 @rcityviews      "\nI… http… 2024-10-09 10:53:25
    #> 4 <chr [1]> 2024-10-09 12:16:37 @d_mykhailyshyna "\nT… http… 2024-10-09 10:53:25
    #> 5 <chr [1]> 2024-10-09 12:04:54 @cyberpuck01     "\nC… http… 2024-10-09 10:53:25
    #> 6 <chr [1]> 2024-10-09 11:59:31 @leonardohansa   "\nD… http… 2024-10-09 10:53:25
    #> 7 <chr [1]> 2024-10-09 11:58:01 @BjnNowak        "\nT… http… 2024-10-09 10:53:25
    #> 8 <chr [1]> 2024-10-09 11:57:34 @HackCyber80     "\nC… http… 2024-10-09 10:53:25

``` r
# Con la función getTweetsHistoricalHashtag(), recuperamos tweets históricos 
# que contengan el hashtag #rstats y los imprimimos en pantalla

tweets_historicos <- getTweetsHistoricalHashtag("#rstats", n_tweets = 20)
```

    #> Inició la recolección de tweets.
    #> Finalizó la recolección de tweets.
    #> Procesando datos...
    #> Datos procesados y guardados.
    #> Tweets únicos recolectados: 34

``` r
tweets_historicos
```

    #> # A tibble: 34 × 6
    #>    art_html  fecha               user            tweet url   fecha_captura      
    #>    <list>    <dttm>              <chr>           <chr> <chr> <dttm>             
    #>  1 <chr [1]> 2018-10-29 23:54:40 @gjmount        "\nC… http… 2024-10-09 10:54:12
    #>  2 <chr [1]> 2018-10-29 23:53:10 @ahammami0      "\nP… http… 2024-10-09 10:54:12
    #>  3 <chr [1]> 2018-10-29 23:49:06 @ChrisTokita    "\nC… http… 2024-10-09 10:54:12
    #>  4 <chr [1]> 2018-10-29 23:35:04 @gp_pulipaka    "\nI… http… 2024-10-09 10:54:12
    #>  5 <chr [1]> 2018-10-29 23:30:07 @gp_pulipaka    "\nA… http… 2024-10-09 10:54:12
    #>  6 <chr [1]> 2018-10-29 23:28:07 @gp_pulipaka    "\nL… http… 2024-10-09 10:54:12
    #>  7 <chr [1]> 2018-10-29 23:26:09 @gp_pulipaka    "\nM… http… 2024-10-09 10:54:12
    #>  8 <chr [1]> 2018-10-29 23:00:32 @tidyversetwee… "\nG… http… 2024-10-09 10:54:12
    #>  9 <chr [1]> 2018-10-29 23:00:31 @tidyversetwee… "\nW… http… 2024-10-09 10:54:12
    #> 10 <chr [1]> 2018-10-29 23:00:26 @ProCogia       "\nW… http… 2024-10-09 10:54:12
    #> # ℹ 24 more rows

``` r
# Ahora con la getTweetsHistoricalTimeline() recuperamos los datos de tweets originales 
# de la cuenta rstatstweet.

timeline_tweets <- getTweetsHistoricalTimeline(username = "rstatstweet", n_tweets = 10, 
                                               since = "2018-10-26", until = "2020-10-30")
```

    #> Inició la recolección de tweets.
    #> Finalizó la recolección de tweets.
    #> Procesando datos...
    #> Datos procesados y guardados.
    #> Tweets únicos recolectados: 13

``` r
# Imprimimos en pantalla los datos de los tweets recuperados

timeline_tweets
```

    #> # A tibble: 13 × 6
    #>    art_html  fecha               user         tweet    url   fecha_captura      
    #>    <list>    <dttm>              <chr>        <chr>    <chr> <dttm>             
    #>  1 <chr [1]> 2020-09-25 22:12:32 @rstatstweet "I can’… http… 2024-10-09 10:54:36
    #>  2 <chr [1]> 2020-09-24 15:58:14 @rstatstweet "Welcom… http… 2024-10-09 10:54:36
    #>  3 <chr [1]> 2020-09-24 15:30:13 @rstatstweet "\nI am… http… 2024-10-09 10:54:36
    #>  4 <chr [1]> 2020-09-24 15:10:16 @rstatstweet "This i… http… 2024-10-09 10:54:36
    #>  5 <chr [1]> 2020-09-24 15:05:32 @rstatstweet "\nThan… http… 2024-10-09 10:54:36
    #>  6 <chr [1]> 2020-09-24 13:07:33 @rstatstweet "\nThan… http… 2024-10-09 10:54:36
    #>  7 <chr [1]> 2020-09-24 09:11:22 @rstatstweet "That’s… http… 2024-10-09 10:54:36
    #>  8 <chr [1]> 2020-09-24 00:28:46 @rstatstweet "I will… http… 2024-10-09 10:54:36
    #>  9 <chr [1]> 2020-09-24 00:25:17 @rstatstweet "\nTher… http… 2024-10-09 10:54:36
    #> 10 <chr [1]> 2020-09-24 00:21:15 @rstatstweet "\nSo t… http… 2024-10-09 10:54:36
    #> 11 <chr [1]> 2020-09-24 00:16:20 @rstatstweet "I was … http… 2024-10-09 10:54:36
    #> 12 <chr [1]> 2020-09-24 00:09:42 @rstatstweet "\nThis… http… 2024-10-09 10:54:36
    #> 13 <chr [1]> 2020-02-12 01:36:45 @rstatstweet "Happy … http… 2024-10-09 10:54:36

``` r
# Ahora con la función getUsersFullData() recuperamos los datos de usuarixs a 
# partir de las URLs de users recuperadas en el objeto tweets_historicos.

users <- unique(gsub("@", "", tweets_historicos$user))
usuarixs <- getUsersFullData(urls_users = paste0("https://x.com/", users))
```

    #> 
    #> Terminando el proceso.
    #>       
    #> Usuarixs recuperados: 25 
    #> Usuarixs no recuperados: 0

``` r
# Imprimimos en pantalla los datos de lxs users recuperadxs 

dplyr::glimpse(usuarixs)
```

    #> Rows: 25
    #> Columns: 13
    #> $ fecha_creacion       <dttm> 2014-05-11 11:32:54, 2017-10-11 08:04:19, 2009-0…
    #> $ nombre_adicional     <chr> "gjmount", "ahammami0", "ChrisTokita", "gp_pulipa…
    #> $ descripcion          <chr> "I teach analytics in modern Excel 📚 O'Reilly Au…
    #> $ nombre               <chr> "George Mount", "Abdessalem Hammami", "Chris Toki…
    #> $ ubicacion            <chr> "Cleveland, OH", "Joensuu, Suomi", "Los Angeles, …
    #> $ identificador        <chr> "2489702532", "918024449194065925", "41155612", "…
    #> $ url_imagen           <chr> "https://pbs.twimg.com/profile_images/16538332253…
    #> $ url_miniatura        <chr> "https://pbs.twimg.com/profile_images/16538332253…
    #> $ seguidorxs           <int> 4674, 125, 1529, 183257, 12025, 1621, 2351, 396, …
    #> $ amigxs               <int> 4273, 120, 1880, 20258, 0, 147, 1919, 310, 2505, …
    #> $ tweets               <int> 29713, 883, 5653, 92873, 98491, 1545, 1004, 779, …
    #> $ url                  <chr> "https://twitter.com/gjmount", "https://twitter.c…
    #> $ enlaces_relacionados <chr> "https://t.co/JcWH7Lwy9r, https://stringfestanaly…
