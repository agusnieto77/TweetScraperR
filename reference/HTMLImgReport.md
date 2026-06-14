# Generate HTML visualization of analyzed images

\#'
[![\[Experimental\]](https://lifecycle.r-lib.org/articles/figures/lifecycle-experimental.svg)](https://lifecycle.r-lib.org/articles/stages.html#experimental)

Esta función crea una visualización HTML interactiva de imágenes
analizadas, mostrando cada imagen junto con su clasificación,
descripción, palabras clave y banderas de contenido en un diseño
responsivo con un carrusel y miniaturas.

## Usage

``` r
HTMLImgReport(results, output_file = "visualizacion_imagenes.html")
```

## Arguments

- results:

  Un data frame o tibble que contiene los resultados del análisis de
  imágenes de la función `getTweetsImagesAnalysis`. Debe incluir las
  siguientes columnas:

  - clasificacion: La clasificación de la imagen (character)

  - descripcion: Una descripción detallada de la imagen (character)

  - palabras_clave: Palabras clave que describen la imagen (character)

  - contiene_texto: Indica si la imagen contiene texto (logical)

  - texto_contenido: El texto contenido en la imagen, si lo hay
    (character)

  - contenido_discriminatorio: Indica si hay contenido discriminatorio
    (logical)

  - contenido_violento: Indica si hay contenido violento (logical)

  - contenido_pornografico: Indica si hay contenido pornográfico
    (logical)

  - contenido_inapropiado: Indica si hay contenido inapropiado (logical)

  - img: La ruta o URL de la imagen (character)

- output_file:

  Una cadena de caracteres con el nombre (o la ruta) del archivo HTML de
  salida. Por defecto es "visualizacion_imagenes.html" en el directorio
  de trabajo actual.

## Value

Esta función no devuelve ningún valor. Genera un archivo HTML (por
defecto "visualizacion_imagenes.html" en el directorio de trabajo
actual) y muestra un mensaje de confirmación.

## Details

La función crea una página HTML responsiva utilizando Bootstrap para el
diseño. Cada imagen se presenta en una tarjeta que incluye la imagen, su
clasificación, descripción, palabras clave y banderas de contenido
potencialmente problemático. El diseño se ajusta automáticamente a
diferentes tamaños de pantalla.

La visualización incluye:

- Un título centrado que menciona la función getTweetsImagesAnalysis

- Un carrusel de tarjetas de imágenes

- Una vista de miniaturas de todas las imágenes

- Banderas de colores para contenido problemático

- Estilos CSS personalizados para mejorar la presentación

## Examples

``` r
if (FALSE) { # \dontrun{
# Asumiendo que tienes un data frame llamado 'resultados_analisis'
HTMLImgReport(resultados_analisis)
} # }
```
