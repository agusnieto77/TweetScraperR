
<!-- README.md is generated from README.Rmd. Please edit that file -->

# TweetScraperR<img src="man/figures/hex-twitterscraper.svg" align="right" height="320"/>

<!-- badges: start -->

[![Project Status: Active – The project has reached a stable, usable
state and is being actively
developed.](https://www.repostatus.org/badges/latest/active.svg)](https://www.repostatus.org/#active)
[![](https://img.shields.io/badge/devel%20version-0.1.0-blue.svg)](https://github.com/agusnieto77/TweetScraperR)
[![License:
MIT](https://img.shields.io/badge/license-MIT-blue.svg)](https://cran.r-project.org/web/licenses/MIT)
[![](https://img.shields.io/github/languages/code-size/agusnieto77/TweetScraperR.svg)](https://github.com/agusnieto77/TweetScraperR)
[![](https://img.shields.io/badge/Lifecycle-Experimental-ff7f2a)](https://lifecycle.r-lib.org/articles/stages.html#experimental)
[![](https://img.shields.io/badge/Build%20with-R%20&%20RStudio-blue?style=plastic=appveyor)](https://github.com/agusnieto77/TweetScraperR)
[![](https://img.shields.io/badge/TweetScraperR-ready%20to%20use-color:%20#39c?style=plastic=appveyor)](https://github.com/agusnieto77/TweetScraperR)

<!-- badges: end -->

### Vision general

Este paquete proporciona funciones para extraer datos de X/Twitter,
incluidos tweets, usuarixs y metadatos asociados. Permite realizar
extracción de datos de X/Twitter y manejar la respuesta de manera
conveniente en R. El paquete se enfoca en facilitar la tarea de
recolección de datos para análisis y visualización.

### Instalacion de la version en desarrollo

Puedes instalar la versión de desarrollo de TweetScraperR desde
[GitHub](https://github.com/) con:

``` r
# install.packages("devtools")
devtools::install_github("agusnieto77/TweetScraperR")
```

### Funciones

| Nombre                    | Ciclo                                                                        | Descripción                                |
|:--------------------------|:-----------------------------------------------------------------------------|:-------------------------------------------|
| `getTweetsData()`         | ![](https://lifecycle.r-lib.org/articles/figures/lifecycle-experimental.svg) | Recupera datos de tweets a partir de URLs. |
| `getTweetsTimeline()`     | ![](https://lifecycle.r-lib.org/articles/figures/lifecycle-experimental.svg) | Recupera tweets de un timeline.            |
| `getTweetsUrlsSearch()`   | ![](https://lifecycle.r-lib.org/articles/figures/lifecycle-experimental.svg) | Recupera URLs de tweets por búsqueda.      |
| `getTweetsUrlsTimeline()` | ![](https://lifecycle.r-lib.org/articles/figures/lifecycle-experimental.svg) | Recupera URLs de tweets de un timeline.    |
| `getUsersData`            | ![](https://lifecycle.r-lib.org/articles/figures/lifecycle-experimental.svg) | Recupera datos de users a partir de URLs.  |

### Uso de las funciones del paquete ACEP: un ejemplo

``` r
# Cargamos la librería
require(TweetScraperR)

# Con la función getTweetsUrlsSearch() recolectamos las URLs de tweets  
# que mencionan el término de búsqueda, en este ejemplo es un hashtag.
# Esta función guarda un rds con las URLs en el directorio de trabajo.
getTweetsUrlsSearch(
  search = "#RStats",
  n_urls = 20,
  xuser = Sys.getenv("USER"),
  xpass = Sys.getenv("PASS")
)
```

    #> Finalizó la recolección de URLs.

``` r
# Cargamos las URLs recuperadas y las imprimimos en pantalla
(url_search <- readRDS("search_hashtag_RStats_2024_05_15_20_41_13.rds"))
```

    #>  [1] "https://twitter.com/Cghlewis/status/1790830945978720350"     
    #>  [2] "https://twitter.com/RosanaFerrero/status/1790623170132619390"
    #>  [3] "https://twitter.com/mzloteanu/status/1790758351317369216"    
    #>  [4] "https://twitter.com/el_pachuli_/status/1251659674824380417"  
    #>  [5] "https://twitter.com/RosanaFerrero/status/1785187332565410025"
    #>  [6] "https://twitter.com/LuisDVerde/status/1790609352950174133"   
    #>  [7] "https://twitter.com/dickie_roper/status/1790109195003371670" 
    #>  [8] "https://twitter.com/ellaudet/status/1788555616484556869"     
    #>  [9] "https://twitter.com/dlizcano/status/1790512119835717771"     
    #> [10] "https://twitter.com/v_matzek/status/1376959852367372288"     
    #> [11] "https://twitter.com/emilynordmann/status/1790735653992345851"
    #> [12] "https://twitter.com/JosiahParry/status/1790768811819348111"  
    #> [13] "https://twitter.com/yohaniddawela/status/1787440188358017420"
    #> [14] "https://twitter.com/kyle_e_walker/status/1788265827277611273"
    #> [15] "https://twitter.com/estacion_erre/status/1790733570098544859"
    #> [16] "https://twitter.com/axiomsofxyz/status/1788476771526218018"  
    #> [17] "https://twitter.com/sabirahamedgd/status/1790213889743102080"
    #> [18] "https://twitter.com/dickie_roper/status/1790445361321869648" 
    #> [19] "https://twitter.com/gp_pulipaka/status/1790658633220448705"  
    #> [20] "https://twitter.com/lwpembleton/status/1788983056264753589"  
    #> [21] "https://twitter.com/gp_pulipaka/status/1790648821761835095"

``` r
# Ahora con la getTweetsData() recuperamos los datos de tweets a partir de las 
# URLs de tweets recuperadas con la función getTweetsUrlsSearch().

getTweetsData(
  urls_tweets = url_search,
  xuser = Sys.getenv("USER"),
  xpass = Sys.getenv("PASS")
)
```

``` r
# Cargamos los datos de los tweets recuperados y las imprimimos en pantalla
(db_tweets <- readRDS("db_tweets_2024_05_15_20_43_46.rds"))
```

    #> # A tibble: 21 × 8
    #>    fecha               username      texto         respuestas reposteos megustas
    #>    <dttm>              <chr>         <chr>              <dbl>     <dbl>    <dbl>
    #>  1 2024-05-15 19:45:44 Cghlewis      "Just a remi…          8        30      288
    #>  2 2024-05-15 06:00:06 RosanaFerrero " El mejor t…          1       105      410
    #>  3 2024-05-15 14:57:16 mzloteanu     "#statstab  …          1        10       56
    #>  4 2020-04-18 23:51:35 el_pachuli_   "Recibí un S…        377      4000    13000
    #>  5 2024-04-30 06:00:01 RosanaFerrero " Para que t…          2       125      464
    #>  6 2024-05-15 05:05:12 LuisDVerde    "Picking up …          1         5       26
    #>  7 2024-05-13 19:57:45 dickie_roper  "Animation m…          2         4       66
    #>  8 2022-11-29 12:24:52 ellaudet      "Want to lea…          4        59      271
    #>  9 2024-05-14 22:38:50 dlizcano      "Hace alguno…          1        24      161
    #> 10 2021-03-30 18:09:46 v_matzek      "Asked my st…        208      4000    19000
    #> # ℹ 11 more rows
    #> # ℹ 2 more variables: post_completo <list>, url <chr>

``` r
# Ahora con la getUsersData() recuperamos los datos de tweets a partir de las 
# URLs de users recuperadas con la función getTweetsData().
getUsersData(
  urls_users = unique(paste0("https://twitter.com/", db_tweets$username)),
  xuser = Sys.getenv("USER"),
  xpass = Sys.getenv("PASS")
)
```

``` r
# Cargamos los datos de lxs users recuperados y las imprimimos en pantalla
(db_users <- readRDS("db_users_2024_05_15_20_57_29.rds"))
```

    #> # A tibble: 18 × 7
    #>    fecha_inicio nombre            username n_post n_siguiendo n_seguidorxs url  
    #>    <date>       <chr>             <chr>     <dbl>       <dbl>        <dbl> <chr>
    #>  1 2018-04-01   Crystal Lewis     Cghlewis   4306        1799         2748 http…
    #>  2 2013-04-01   Rosana Ferrero    RosanaF…   9704        4749        40800 http…
    #>  3 2013-07-01   ᴅʀ ᴍɪʀᴄᴇᴀ ᴢʟᴏᴛᴇᴀ… mzlotea…   2081        1078          727 http…
    #>  4 2011-04-01   Lic. Leopoldo Ca… el_pach…   3241        1025         2573 http…
    #>  5 2011-01-01   Luis D. Verde Ar… LuisDVe…   4598        2126         2846 http…
    #>  6 2010-05-01   chris             dickie_…    979         390          956 http…
    #>  7 2015-04-01   Elena Llaudet     ellaudet    710        8312         9633 http…
    #>  8 2009-06-01   Diego J. Lizcano  dlizcano   5754        2098         1805 http…
    #>  9 2016-09-01   Virginia Matzek   v_matzek   5389        1005         2010 http…
    #> 10 2013-05-01   Emily Nordmann    emilyno…  11400        1281         5378 http…
    #> 11 2011-05-01   Josiah            JosiahP…  13600        1988         2841 http…
    #> 12 2017-03-01   Yohan Iddawela    yohanid…   3038         220        11700 http…
    #> 13 2010-05-01   Kyle Walker       kyle_e_…   6552         414         9066 http…
    #> 14 2020-01-01   Estación R        estacio…    836         206         4072 http…
    #> 15 2012-06-01   James Balamuta    axiomso…    727          60          550 http…
    #> 16 2009-09-01   SABIR AHAMED      sabirah…   5983        3667         1522 http…
    #> 17 2015-11-01   Dr. Ganapathi Pu… gp_puli…  87900       20500       173900 http…
    #> 18 2021-05-01   Luke Pembleton    lwpembl…    894         378          223 http…
