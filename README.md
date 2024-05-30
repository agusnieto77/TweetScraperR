
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

    #> # A tibble: 21 × 6
    #>    art_html  fecha               user            tweet url   fecha_captura      
    #>    <list>    <dttm>              <chr>           <chr> <chr> <dttm>             
    #>  1 <chr [1]> 2024-05-30 01:45:06 @HackPro10_     "\nC… http… 2024-05-29 22:46:34
    #>  2 <chr [1]> 2024-05-30 01:29:26 @Williamhacks0  "\nH… http… 2024-05-29 22:46:34
    #>  3 <chr [1]> 2024-05-30 01:26:42 @trusted_shiel… "\nD… http… 2024-05-29 22:46:34
    #>  4 <chr [1]> 2024-05-30 01:25:30 @trusted_shiel… "\nD… http… 2024-05-29 22:46:34
    #>  5 <chr [1]> 2024-05-30 01:22:27 @trusted_shiel… "\nD… http… 2024-05-29 22:46:34
    #>  6 <chr [1]> 2024-05-30 01:21:55 @trusted_shiel… "\nD… http… 2024-05-29 22:46:34
    #>  7 <chr [1]> 2024-05-30 00:58:31 @draxlordd      "\nH… http… 2024-05-29 22:46:34
    #>  8 <chr [1]> 2024-05-30 01:45:06 @HackPro10_     "\nC… http… 2024-05-29 22:46:34
    #>  9 <chr [1]> 2024-05-30 01:29:26 @Williamhacks0  "\nH… http… 2024-05-29 22:46:34
    #> 10 <chr [1]> 2024-05-30 01:26:42 @trusted_shiel… "\nD… http… 2024-05-29 22:46:34
    #> # ℹ 11 more rows

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
    #>  1 <chr [1]> 2018-10-29 23:54:40 @gjmount        "\nC… http… 2024-05-29 22:47:08
    #>  2 <chr [1]> 2018-10-29 23:53:10 @ahammami0      "\nP… http… 2024-05-29 22:47:08
    #>  3 <chr [1]> 2018-10-29 23:49:06 @ChrisTokita    "\nC… http… 2024-05-29 22:47:08
    #>  4 <chr [1]> 2018-10-29 23:35:04 @gp_pulipaka    "\nI… http… 2024-05-29 22:47:08
    #>  5 <chr [1]> 2018-10-29 23:30:07 @gp_pulipaka    "\nA… http… 2024-05-29 22:47:08
    #>  6 <chr [1]> 2018-10-29 23:28:07 @gp_pulipaka    "\nL… http… 2024-05-29 22:47:08
    #>  7 <chr [1]> 2018-10-29 23:26:09 @gp_pulipaka    "\nM… http… 2024-05-29 22:47:08
    #>  8 <chr [1]> 2018-10-29 23:00:32 @tidyversetwee… "\nG… http… 2024-05-29 22:47:08
    #>  9 <chr [1]> 2018-10-29 23:49:06 @ChrisTokita    "\nC… http… 2024-05-29 22:47:08
    #> 10 <chr [1]> 2018-10-29 23:35:04 @gp_pulipaka    "\nI… http… 2024-05-29 22:47:08
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
    #>  1 <chr [1]> 2020-09-25 22:12:32 @rstatstweet "I can’… http… 2024-05-29 22:47:31
    #>  2 <chr [1]> 2020-09-24 15:58:14 @rstatstweet "Welcom… http… 2024-05-29 22:47:31
    #>  3 <chr [1]> 2020-09-24 15:30:13 @rstatstweet "\nI am… http… 2024-05-29 22:47:31
    #>  4 <chr [1]> 2020-09-24 15:10:16 @rstatstweet "This i… http… 2024-05-29 22:47:31
    #>  5 <chr [1]> 2020-09-24 15:05:32 @rstatstweet "\nThan… http… 2024-05-29 22:47:31
    #>  6 <chr [1]> 2020-09-24 13:07:33 @rstatstweet "\nThan… http… 2024-05-29 22:47:31
    #>  7 <chr [1]> 2020-09-24 09:11:22 @rstatstweet "That’s… http… 2024-05-29 22:47:31
    #>  8 <chr [1]> 2020-09-24 00:28:46 @rstatstweet "I will… http… 2024-05-29 22:47:31
    #>  9 <chr [1]> 2020-09-24 00:25:17 @rstatstweet "\nTher… http… 2024-05-29 22:47:31
    #> 10 <chr [1]> 2020-09-24 00:21:15 @rstatstweet "\nSo t… http… 2024-05-29 22:47:31
    #> 11 <chr [1]> 2020-09-24 00:16:20 @rstatstweet "I was … http… 2024-05-29 22:47:31
    #> 12 <chr [1]> 2020-09-24 00:09:42 @rstatstweet "\nThis… http… 2024-05-29 22:47:31
    #> 13 <chr [1]> 2020-02-12 01:36:45 @rstatstweet "Happy … http… 2024-05-29 22:47:31

``` r
# Ahora con la función getUsersData() recuperamos los datos de usuarixs a 
# partir de las URLs de users recuperadas en el objeto tweets_historicos.

users <- unique(gsub("@", "", tweets_historicos$user))
usuarixs <- getUsersData(urls_users = paste0("https://x.com/", users))

# Imprimimos en pantalla los datos de lxs users recuperadxs 

usuarixs
```

    #> # A tibble: 25 × 8
    #>    fecha_inicio nombre            username n_post n_siguiendo n_seguidorxs url  
    #>    <date>       <chr>             <chr>     <dbl>       <dbl>        <dbl> <chr>
    #>  1 2014-05-01   George Mount      gjmount   28600        4236         4594 http…
    #>  2 2017-10-01   Abdessalem Hamma… ahammam…    883         120          117 http…
    #>  3 2009-05-01   Chris Tokita      ChrisTo…   5534        1849         1447 http…
    #>  4 2015-11-01   Dr. Ganapathi Pu… gp_puli…  88400       20400       174800 http…
    #>  5 2017-11-01   tidyverse tweets  tidyver…  98400           0        12100 http…
    #>  6 2013-06-01   ProCogia          ProCogia   1546         148         1628 http…
    #>  7 2013-12-01   Feyaad Allie      FeyaadA…    967        1866         2238 http…
    #>  8 2015-02-01   Wendel Raymond    wendel_…    780         315          403 http…
    #>  9 2011-11-01   Peter Higgins     ibddoct…  23700        2481        10800 http…
    #> 10 2018-05-01   We are R-Ladies   WeAreRL…   8181         192        34200 http…
    #> # ℹ 15 more rows
    #> # ℹ 1 more variable: fecha_captura <dttm>
