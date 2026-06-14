# Get Tweets Images

[![\[Experimental\]](https://lifecycle.r-lib.org/articles/figures/lifecycle-experimental.svg)](https://lifecycle.r-lib.org/articles/stages.html#experimental)

**Obsoleta**: preféri getUserMediaAPI(), basada en la API de X (datos
del JSON, mas robusta).

Esta función toma una lista de URLs de imágenes extraídas de tweets, las
descarga y opcionalmente las guarda en un directorio específico. Si el
directorio no existe, se creará.

## Usage

``` r
getTweetsImages(urls, directorio = "img_x", save = TRUE)
```

## Arguments

- urls:

  Lista o vector de URLs de imágenes que se desea descargar.

- directorio:

  (opcional) Nombre del directorio donde se guardarán las imágenes. El
  valor predeterminado es "img_x". Si el directorio no existe, la
  función lo crea.

- save:

  Lógico. Indica si se deben guardar las imágenes en el directorio
  especificado (por defecto TRUE).

## Value

Una lista invisible de las rutas de archivo donde se guardaron las
imágenes, o NULL si save = FALSE.

## Details

La función primero asegura que el directorio donde se guardarán las
imágenes exista; si no es así, lo crea (si save = TRUE). Luego, recorre
cada URL proporcionada, extrae un nombre de archivo a partir del URL, y
descarga la imagen en formato JPG usando la librería `httr`.

El nombre de archivo se genera a partir del segmento de la URL que sigue
a "media/" y se le agrega la extensión ".jpg".

Si save = FALSE, la función descargará las imágenes pero no las guardará
en el disco.

## Examples

``` r
if (FALSE) { # \dontrun{
urls <- c(
  "https://x.com/AAS_Sociologia/status/1838907832927768645",
  "https://x.com/AAS_Sociologia/status/1841819590587822081"
)
getTweetsImages(urls)

# Sin guardar las imágenes
getTweetsImages(urls, save = FALSE)
} # }
```
