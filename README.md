
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

| Nombre                    | Ciclo                                                                        | Descripción                                    |
|:--------------------------|:-----------------------------------------------------------------------------|:-----------------------------------------------|
| `getAuthentication()`     | ![](https://lifecycle.r-lib.org/articles/figures/lifecycle-experimental.svg) | Inicia sesión en Twitter con las credenciales. |
| `getTweetsData()`         | ![](https://lifecycle.r-lib.org/articles/figures/lifecycle-experimental.svg) | Recupera datos de tweets a partir de URLs.     |
| `getTweetsTimeline()`     | ![](https://lifecycle.r-lib.org/articles/figures/lifecycle-experimental.svg) | Recupera tweets de un timeline.                |
| `getTweetsUrlsSearch()`   | ![](https://lifecycle.r-lib.org/articles/figures/lifecycle-experimental.svg) | Recupera URLs de tweets por búsqueda.          |
| `getTweetsUrlsTimeline()` | ![](https://lifecycle.r-lib.org/articles/figures/lifecycle-experimental.svg) | Recupera URLs de tweets de un timeline.        |
| `getUsersData`            | ![](https://lifecycle.r-lib.org/articles/figures/lifecycle-experimental.svg) | Recupera datos de users a partir de URLs.      |
