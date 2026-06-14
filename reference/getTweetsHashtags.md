# Get Hashtags from Tweets

[![\[Experimental\]](https://lifecycle.r-lib.org/articles/figures/lifecycle-experimental.svg)](https://lifecycle.r-lib.org/articles/stages.html#experimental)

Esta función toma un dataframe de tweets y extrae todos los hashtags del
campo 'texto' o 'tweet', añadiéndolos como una nueva columna al
dataframe.

## Usage

``` r
getTweetsHashtags(df)
```

## Arguments

- df:

  Un dataframe que contiene una columna 'texto' o 'tweet' con el
  contenido de los tweets.

## Value

Un dataframe con una nueva columna 'hashtags' que contiene, para cada
tweet, un vector de caracteres con sus hashtags. Los tweets sin hashtags
devuelven `character(0)`. Nota: en versiones anteriores los hashtags
llegaban anidados en una lista adicional (`x[[i]][[1]]`) y los tweets
sin hashtags devolvían `NA`.

## Examples

``` r
df1 <- data.frame(
  texto = c("Este es un #tweet con #hashtags", "Este no tiene hashtags", "Otro #ejemplo")
)
getTweetsHashtags(df1)
#>                             texto          hashtags
#> 1 Este es un #tweet con #hashtags #tweet, #hashtags
#> 2          Este no tiene hashtags                  
#> 3                   Otro #ejemplo          #ejemplo

df2 <- data.frame(
  tweet = c("Este es un #tweet con #hashtags", "Este no tiene hashtags", "Otro #ejemplo")
)
getTweetsHashtags(df2)
#>                             tweet          hashtags
#> 1 Este es un #tweet con #hashtags #tweet, #hashtags
#> 2          Este no tiene hashtags                  
#> 3                   Otro #ejemplo          #ejemplo
```
