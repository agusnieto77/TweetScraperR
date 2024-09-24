
<!-- README.md is generated from README.Rmd. Please edit that file -->

# TweetScraperR<img src="man/figures/hex-twitterscraper.svg" align="right" height="320"/>

<!-- badges: start -->

[![Project Status: Active – The project has reached a stable, usable
state and is being actively
developed.](https://www.repostatus.org/badges/latest/active.svg)](https://www.repostatus.org/#active)
[![](https://img.shields.io/badge/devel%20version-0.1.0.02-blue.svg)](https://github.com/agusnieto77/TweetScraperR)
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

| Nombre                          | Ciclo                                                                        | Descripción                                           |
|:--------------------------------|:-----------------------------------------------------------------------------|:------------------------------------------------------|
| `closeTwitter()`                | ![](https://lifecycle.r-lib.org/articles/figures/lifecycle-experimental.svg) | Cierre de sesión.                                     |
| `getTweetsData()`               | ![](https://lifecycle.r-lib.org/articles/figures/lifecycle-experimental.svg) | Recupera datos de tweets a partir de URLs.            |
| `getTweetsHistoricalHashtag()`  | ![](https://lifecycle.r-lib.org/articles/figures/lifecycle-experimental.svg) | Recupera tweets históricos con un hashtag específico. |
| `getTweetsHistoricalSearch()`   | ![](https://lifecycle.r-lib.org/articles/figures/lifecycle-experimental.svg) | Recupera tweets históricos con un término específico. |
| `getTweetsHistoricalTimeline()` | ![](https://lifecycle.r-lib.org/articles/figures/lifecycle-experimental.svg) | Recupera tweets históricos de un timeline.            |
| `getTweetsSearchStreaming()`    | ![](https://lifecycle.r-lib.org/articles/figures/lifecycle-experimental.svg) | Recupera tweets en tiempo real.                       |
| `getTweetsTimeline()`           | ![](https://lifecycle.r-lib.org/articles/figures/lifecycle-experimental.svg) | Recupera tweets de un timeline.                       |
| `getUrlsHistoricalTimeline()`   | ![](https://lifecycle.r-lib.org/articles/figures/lifecycle-experimental.svg) | Recupera URLs de tweets históricos de un timeline.    |
| `getUrlsSearchStreaming()`      | ![](https://lifecycle.r-lib.org/articles/figures/lifecycle-experimental.svg) | Recupera URLs de tweets en tiempo real.               |
| `getUrlsTweetsSearch()`         | ![](https://lifecycle.r-lib.org/articles/figures/lifecycle-experimental.svg) | Recupera URLs de tweets por búsqueda.                 |
| `getUrlsTweetsTimeline()`       | ![](https://lifecycle.r-lib.org/articles/figures/lifecycle-experimental.svg) | Recupera URLs de tweets de un timeline.               |
| `getUsersData()`                | ![](https://lifecycle.r-lib.org/articles/figures/lifecycle-experimental.svg) | Recupera datos de users a partir de URLs.             |
| `getUsersFullData()`            | ![](https://lifecycle.r-lib.org/articles/figures/lifecycle-experimental.svg) | Recupera datos completos de users a partir de URLs.   |
| `openTwitter()`                 | ![](https://lifecycle.r-lib.org/articles/figures/lifecycle-experimental.svg) | Inicio de sesión.                                     |

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
    #> 1 <chr [1]> 2024-09-24 20:09:37 @moriah_taylor58 "\nI… http… 2024-09-24 17:25:10
    #> 2 <chr [1]> 2024-09-24 19:15:27 @bastimapache    "\nM… http… 2024-09-24 17:25:10
    #> 3 <chr [1]> 2024-09-24 19:00:06 @ChaoLiu77600168 "\nE… http… 2024-09-24 17:25:11
    #> 4 <chr [1]> 2024-09-24 18:59:33 @JosiahParry     "\nP… http… 2024-09-24 17:25:11
    #> 5 <chr [1]> 2024-09-24 18:47:12 @rstatsai        "\nD… http… 2024-09-24 17:25:11
    #> 6 <chr [1]> 2024-09-24 18:19:10 @RConsortium     "\n … http… 2024-09-24 17:25:11
    #> 7 <chr [1]> 2024-09-24 17:15:50 @eddelbuettel    "\nR… http… 2024-09-24 17:25:11
    #> 8 <chr [1]> 2024-09-24 17:14:37 @LieberInstitute "\nH… http… 2024-09-24 17:25:11

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
    #>  1 <chr [1]> 2018-10-29 23:54:40 @gjmount        "\nC… http… 2024-09-24 17:25:58
    #>  2 <chr [1]> 2018-10-29 23:53:10 @ahammami0      "\nP… http… 2024-09-24 17:25:58
    #>  3 <chr [1]> 2018-10-29 23:49:06 @ChrisTokita    "\nC… http… 2024-09-24 17:25:58
    #>  4 <chr [1]> 2018-10-29 23:35:04 @gp_pulipaka    "\nI… http… 2024-09-24 17:25:58
    #>  5 <chr [1]> 2018-10-29 23:30:07 @gp_pulipaka    "\nA… http… 2024-09-24 17:25:58
    #>  6 <chr [1]> 2018-10-29 23:28:07 @gp_pulipaka    "\nL… http… 2024-09-24 17:25:58
    #>  7 <chr [1]> 2018-10-29 23:26:09 @gp_pulipaka    "\nM… http… 2024-09-24 17:25:58
    #>  8 <chr [1]> 2018-10-29 23:00:32 @tidyversetwee… "\nG… http… 2024-09-24 17:25:58
    #>  9 <chr [1]> 2018-10-29 23:00:31 @tidyversetwee… "\nW… http… 2024-09-24 17:25:58
    #> 10 <chr [1]> 2018-10-29 23:00:26 @ProCogia       "\nW… http… 2024-09-24 17:25:58
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
    #> Tweets únicos recolectados: 28

``` r
# Imprimimos en pantalla los datos de los tweets recuperados

timeline_tweets
```

    #> # A tibble: 28 × 6
    #>    art_html  fecha               user         tweet    url   fecha_captura      
    #>    <list>    <dttm>              <chr>        <chr>    <chr> <dttm>             
    #>  1 <chr [1]> 2020-09-25 22:12:32 @rstatstweet "I can’… http… 2024-09-24 17:26:34
    #>  2 <chr [1]> 2020-09-24 15:58:14 @rstatstweet "Welcom… http… 2024-09-24 17:26:34
    #>  3 <chr [1]> 2020-09-24 15:30:13 @rstatstweet "\nI am… http… 2024-09-24 17:26:34
    #>  4 <chr [1]> 2020-09-24 15:10:16 @rstatstweet "This i… http… 2024-09-24 17:26:34
    #>  5 <chr [1]> 2020-09-24 15:05:32 @rstatstweet "\nThan… http… 2024-09-24 17:26:34
    #>  6 <chr [1]> 2020-09-24 13:07:33 @rstatstweet "\nThan… http… 2024-09-24 17:26:34
    #>  7 <chr [1]> 2020-09-24 09:11:22 @rstatstweet "That’s… http… 2024-09-24 17:26:34
    #>  8 <chr [1]> 2020-09-24 00:28:46 @rstatstweet "I will… http… 2024-09-24 17:26:34
    #>  9 <chr [1]> 2020-09-24 00:25:17 @rstatstweet "\nTher… http… 2024-09-24 17:26:34
    #> 10 <chr [1]> 2020-09-24 00:21:15 @rstatstweet "\nSo t… http… 2024-09-24 17:26:34
    #> # ℹ 18 more rows

``` r
# Ahora con la función getUsersFullData() recuperamos los datos de usuarixs a 
# partir de las URLs de users recuperadas en el objeto tweets_historicos.

users <- unique(gsub("@", "", tweets_historicos$user))
usuarixs <- getUsersFullData(urls_users = paste0("https://x.com/", users))

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
    #> $ seguidorxs           <int> 4678, 127, 1517, 183953, 12033, 1622, 2361, 398, …
    #> $ amigxs               <int> 4275, 120, 1876, 20283, 0, 147, 1920, 312, 2506, …
    #> $ tweets               <int> 29593, 883, 5645, 92579, 98491, 1545, 1002, 779, …
    #> $ url                  <chr> "https://twitter.com/gjmount", "https://twitter.c…
    #> $ enlaces_relacionados <chr> "https://t.co/JcWH7Lwy9r, https://stringfestanaly…
