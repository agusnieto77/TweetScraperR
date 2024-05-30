
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
incluidos tweets, usuarixs y metadatos asociados. Permite realizar
extracción de datos de X/Twitter y manejar la respuesta de manera
conveniente en R. El paquete se enfoca en facilitar la tarea de
recolección de datos para análisis y visualización.

This package provides functions to extract X/Twitter data, including
tweets, users and associated metadata. It allows you to perform
X/Twitter data extraction and handle the response in a convenient way in
R. The package focuses on easing the task of data collection for
analysis and visualisation.

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

``` r
urls_hashtagRstats
```

    #> # A tibble: 25 × 6
    #>    art_html  fecha               user           tweet  url   fecha_captura      
    #>    <list>    <dttm>              <chr>          <chr>  <chr> <dttm>             
    #>  1 <chr [1]> 2024-05-30 03:08:12 @Sheilds_Tech_ "\nDM… http… 2024-05-30 00:12:59
    #>  2 <chr [1]> 2024-05-30 03:04:49 @rcityviews    "\nIm… http… 2024-05-30 00:12:59
    #>  3 <chr [1]> 2024-05-30 02:51:46 @DawnDarasMS   "\nUp… http… 2024-05-30 00:12:59
    #>  4 <chr [1]> 2024-05-30 02:50:37 @DawnDarasMS   "\nUp… http… 2024-05-30 00:12:59
    #>  5 <chr [1]> 2024-05-30 02:32:15 @danoehm       "\nWr… http… 2024-05-30 00:12:59
    #>  6 <chr [1]> 2024-05-30 03:08:12 @Sheilds_Tech_ "\nDM… http… 2024-05-30 00:12:59
    #>  7 <chr [1]> 2024-05-30 03:04:49 @rcityviews    "\nIm… http… 2024-05-30 00:12:59
    #>  8 <chr [1]> 2024-05-30 02:51:46 @DawnDarasMS   "\nUp… http… 2024-05-30 00:12:59
    #>  9 <chr [1]> 2024-05-30 02:50:37 @DawnDarasMS   "\nUp… http… 2024-05-30 00:12:59
    #> 10 <chr [1]> 2024-05-30 02:32:15 @danoehm       "\nWr… http… 2024-05-30 00:12:59
    #> # ℹ 15 more rows

``` r
# Con la función getTweetsHistoricalHashtag(), recuperamos tweets históricos 
# que contengan el hashtag #rstats y los imprimimos en pantalla

tweets_historicos <- getTweetsHistoricalHashtag("#rstats", n_tweets = 20)
```

    #> Finalizó la recolección de tweets.
    #> Procesando datos...
    #> Datos procesados y guardados.

``` r
tweets_historicos
```

    #> # A tibble: 40 × 6
    #>    art_html  fecha               user            tweet url   fecha_captura      
    #>    <list>    <dttm>              <chr>           <chr> <chr> <dttm>             
    #>  1 <chr [1]> 2018-10-29 23:54:40 @gjmount        "\nC… http… 2024-05-30 00:13:33
    #>  2 <chr [1]> 2018-10-29 23:53:10 @ahammami0      "\nP… http… 2024-05-30 00:13:33
    #>  3 <chr [1]> 2018-10-29 23:49:06 @ChrisTokita    "\nC… http… 2024-05-30 00:13:33
    #>  4 <chr [1]> 2018-10-29 23:35:04 @gp_pulipaka    "\nI… http… 2024-05-30 00:13:33
    #>  5 <chr [1]> 2018-10-29 23:30:07 @gp_pulipaka    "\nA… http… 2024-05-30 00:13:33
    #>  6 <chr [1]> 2018-10-29 23:28:07 @gp_pulipaka    "\nL… http… 2024-05-30 00:13:33
    #>  7 <chr [1]> 2018-10-29 23:26:09 @gp_pulipaka    "\nM… http… 2024-05-30 00:13:33
    #>  8 <chr [1]> 2018-10-29 23:00:32 @tidyversetwee… "\nG… http… 2024-05-30 00:13:33
    #>  9 <chr [1]> 2018-10-29 23:49:06 @ChrisTokita    "\nC… http… 2024-05-30 00:13:33
    #> 10 <chr [1]> 2018-10-29 23:35:04 @gp_pulipaka    "\nI… http… 2024-05-30 00:13:33
    #> # ℹ 30 more rows

``` r
# Ahora con la getTweetsHistoricalTimeline() recuperamos los datos de tweets originales 
# de la cuenta rstatstweet.

timeline_tweets <- getTweetsHistoricalTimeline(username = "rstatstweet", n_tweets = 10, 
                                               since = "2018-10-26", until = "2020-10-30")
```

    #> Finalizó la recolección de URLs.
    #> Procesando datos...
    #> Datos procesados y guardados.

``` r
# Imprimimos en pantalla los datos de los tweets recuperados

timeline_tweets
```

    #> # A tibble: 13 × 6
    #>    art_html  fecha               user         tweet    url   fecha_captura      
    #>    <list>    <dttm>              <chr>        <chr>    <chr> <dttm>             
    #>  1 <chr [1]> 2020-09-25 22:12:32 @rstatstweet "I can’… http… 2024-05-30 00:13:56
    #>  2 <chr [1]> 2020-09-24 15:58:14 @rstatstweet "Welcom… http… 2024-05-30 00:13:56
    #>  3 <chr [1]> 2020-09-24 15:30:13 @rstatstweet "\nI am… http… 2024-05-30 00:13:56
    #>  4 <chr [1]> 2020-09-24 15:10:16 @rstatstweet "This i… http… 2024-05-30 00:13:56
    #>  5 <chr [1]> 2020-09-24 15:05:32 @rstatstweet "\nThan… http… 2024-05-30 00:13:56
    #>  6 <chr [1]> 2020-09-24 13:07:33 @rstatstweet "\nThan… http… 2024-05-30 00:13:56
    #>  7 <chr [1]> 2020-09-24 09:11:22 @rstatstweet "That’s… http… 2024-05-30 00:13:56
    #>  8 <chr [1]> 2020-09-24 00:28:46 @rstatstweet "I will… http… 2024-05-30 00:13:56
    #>  9 <chr [1]> 2020-09-24 00:25:17 @rstatstweet "\nTher… http… 2024-05-30 00:13:56
    #> 10 <chr [1]> 2020-09-24 00:21:15 @rstatstweet "\nSo t… http… 2024-05-30 00:13:56
    #> 11 <chr [1]> 2020-09-24 00:16:20 @rstatstweet "I was … http… 2024-05-30 00:13:56
    #> 12 <chr [1]> 2020-09-24 00:09:42 @rstatstweet "\nThis… http… 2024-05-30 00:13:56
    #> 13 <chr [1]> 2020-02-12 01:36:45 @rstatstweet "Happy … http… 2024-05-30 00:13:56

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
    #> $ seguidorxs           <int> 4594, 117, 1447, 174922, 12190, 1628, 2238, 403, …
    #> $ amigxs               <int> 4236, 120, 1849, 20498, 0, 148, 1866, 315, 2481, …
    #> $ tweets               <int> 28631, 883, 5534, 88428, 98491, 1546, 967, 780, 2…
    #> $ url                  <chr> "https://twitter.com/gjmount", "https://twitter.c…
    #> $ enlaces_relacionados <chr> "https://t.co/JcWH7Lwy9r, https://stringfestanaly…
