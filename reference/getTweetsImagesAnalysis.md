# Analyze images of tweets

[![\[Experimental\]](https://lifecycle.r-lib.org/articles/figures/lifecycle-experimental.svg)](https://lifecycle.r-lib.org/articles/stages.html#experimental)

Esta función analiza imágenes asociadas con tweets. Procesa un vector de
URLs de imágenes o rutas de archivos locales, envía estas imágenes a la
API de OpenAI para su análisis y devuelve un informe detallado sobre el
contenido de cada imagen.

## Usage

``` r
getTweetsImagesAnalysis(
  img_sources,
  modelo = "gpt-4o-mini",
  api_key = Sys.getenv("OPENAI_API_KEY"),
  dir = getwd(),
  save = TRUE
)
```

## Arguments

- img_sources:

  Un vector de caracteres que contiene las URLs de las imágenes o rutas
  de archivos locales a analizar.

- modelo:

  Una cadena de caracteres que contiene el modelo de OpenAI. Por defecto
  es "gpt-4o-mini".

- api_key:

  Una cadena de caracteres que contiene la clave de API de OpenAI. Por
  defecto es `Sys.getenv("OPENAI_API_KEY")`.

- dir:

  Una cadena de caracteres que especifica el directorio donde se
  guardarán los resultados. Por defecto es
  [`getwd()`](https://rdrr.io/r/base/getwd.html).

- save:

  Lógico. Indica si se deben guardar los resultados (totales y
  parciales) en archivos RDS dentro de `dir`. Por defecto es `TRUE`.

## Value

Un tibble con las siguientes columnas:

- clasificacion:

  La clasificación de la imagen

- contiene_texto:

  Un booleano que indica si la imagen contiene texto

- texto_contenido:

  El contenido de texto de la imagen (si lo hay, limitado a 10 palabras)

- contenido_discriminatorio:

  Un booleano que indica la presencia de contenido discriminatorio

- contenido_violento:

  Un booleano que indica la presencia de contenido violento

- contenido_pornografico:

  Un booleano que indica la presencia de contenido pornográfico

- contenido_inapropiado:

  Un booleano que indica la presencia de contenido inapropiado

- descripcion:

  Una descripción detallada de la imagen

- palabras_clave:

  Una cadena de texto con 2 a 4 palabras clave separadas por punto y
  coma

- img:

  La URL o nombre del archivo de la imagen analizada

## Details

La función realiza los siguientes pasos:

1.  Verifica la presencia de una clave de API válida.

2.  Procesa el vector de URLs de imágenes o rutas de archivos locales,
    eliminando valores NA.

3.  Convierte los archivos locales a formato base64 si es necesario.

4.  Define un prompt de sistema detallado para la API de OpenAI,
    instruyéndola sobre cómo analizar las imágenes.

5.  Para cada imagen:

    - Envía una solicitud a la API de OpenAI con la URL de la imagen o
      los datos base64.

    - Procesa la respuesta de la API para extraer los resultados del
      análisis.

6.  Combina todos los resultados en un solo tibble.

7.  Guarda los resultados como archivos RDS en el directorio
    especificado, con resultados parciales cada 7 imágenes si el total
    es mayor a 7.

El análisis de la imagen incluye:

- Clasificación del tipo de imagen (por ejemplo, foto, meme, captura de
  pantalla)

- Detección de texto en la imagen (limitado a 10 palabras si es extenso)

- Identificación de contenido discriminatorio, violento, pornográfico o
  inapropiado

- Una descripción detallada del contenido de la imagen

- Generación de palabras clave descriptivas

## Note

Esta función requiere una conexión a internet activa y una clave de API
de OpenAI válida para funcionar correctamente. La función está diseñada
para manejar errores y continuar procesando otras imágenes si una falla.
El tiempo de espera para las solicitudes HTTP está configurado en 300
segundos (5 minutos). Tenga en cuenta que las imágenes analizadas (sus
URLs o su contenido codificado en base64) se transmiten a la API de
OpenAI (un servicio de terceros).

## Examples

``` r
if (FALSE) { # \dontrun{
# Ejemplo de uso con un vector de URLs de imágenes
urls <- c("https://ejemplo.com/imagen1.jpg", "https://ejemplo.com/imagen2.jpg")
resultados <- getTweetsImagesAnalysis(urls)

# Ejemplo de uso con rutas de archivos locales
archivos_locales <- c("./imagen1.jpg", "./imagen2.png")
resultados_locales <- getTweetsImagesAnalysis(archivos_locales)
} # }
```
