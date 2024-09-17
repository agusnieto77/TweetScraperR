## Requisitos para usar **TweetScraperR**

### Conocimientos previos:
- Tener un conocimiento básico de **R**.

### Software necesario:
- **Instalación de R**: Asegúrate de tener R instalado en tu ordenador.
- **RStudio**: Instala RStudio para facilitar el desarrollo en R.
- **Controlador de Chrome**: Instala el controlador **chromedriver.exe** en tu sistema operativo para realizar tareas de scraping.

### Librerías de R:
Asegúrate de tener instaladas las siguientes librerías en R:

- `tidyverse`

- `rvest` (última versión)

- `chromote`

- `TweetScraperR`

### Cuenta en X/Twitter:
- Tener una cuenta activa en **X/Twitter** es necesario para acceder a los tweets y usuarixs mediante las funciones de scraping.

---

## Visión general de **TweetScraperR**

El paquete proporciona funciones para extraer datos de **X/Twitter**, como tweets, usuarixs y metadatos asociados. Permite la recolección y manejo de estos datos en **R**, facilitando su análisis y visualización. Está diseñado sobre la librería **rvest** y no utiliza las API de **X/Twitter**, lo que lo convierte en una alternativa gratuita, flexible y de código abierto.


### Instalación

Para instalar la versión de desarrollo desde GitHub, ejecuta:

```r
# install.packages("devtools")
devtools::install_github("agusnieto77/TweetScraperR")
```

### Funcionalidades principales

El paquete incluye funciones para:

- Extraer tweets históricos y en tiempo real.
- Recuperar timelines y buscar por hashtags.
- Obtener datos completos de usuarixs.

El paquete se encuentra en un estado activo de desarrollo, con una licencia MIT que garantiza su uso libre y abierto.