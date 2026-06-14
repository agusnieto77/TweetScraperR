# Get Users Data

[![\[Experimental\]](https://lifecycle.r-lib.org/articles/figures/lifecycle-experimental.svg)](https://lifecycle.r-lib.org/articles/stages.html#experimental)

**Obsoleta**: preféri getUsersDataAPI(), basada en la API de X (datos
del JSON, mas robusta).

Esta función permite recuperar y procesar datos de usuarixs de Twitter a
partir de un vector de URLs proporcionadas. Opcionalmente puede realizar
la autenticación en Twitter si open=TRUE utilizando las credenciales
proporcionadas. La función extrae información detallada de cada perfil
de usuarix incluyendo el nombre del usuarix, el username, la fecha de
creación del perfil, el número de publicaciones, seguidorxs y seguidxs.
La función maneja posibles errores durante el proceso de recolección de
datos y realiza reintentos automáticos cuando es necesario. Los datos
recopilados se devuelven en forma de un tibble y, si se especifica, se
guardan en un archivo RDS para su posterior uso.

## Usage

``` r
getUsersData(
  urls_users,
  open = FALSE,
  xuser = Sys.getenv("TWITTER_USER", Sys.getenv("USER")),
  xpass = Sys.getenv("TWITTER_PASS", Sys.getenv("PASS")),
  max_retries = 3,
  dir = getwd(),
  save = TRUE
)
```

## Arguments

- urls_users:

  Vector de URLs de users de los cuales se desea obtener datos.

- open:

  Indica si se debe realizar el proceso de autenticación (por defecto
  FALSE).

- xuser:

  Nombre de usuarix de Twitter para autenticación. Por defecto es el
  valor de la variable de entorno TWITTER_USER (o, si no está definida,
  USER).

- xpass:

  Contraseña de Twitter para autenticación. Por defecto es el valor de
  la variable de entorno TWITTER_PASS (o, si no está definida, PASS).

- max_retries:

  número máximo de intentos de conexión. Por defecto es 3.

- dir:

  Directorio donde se guardará el archivo RDS con los datos recopilados.
  Por defecto es el directorio actual.

- save:

  Lógico. Indica si se debe guardar el resultado en un archivo RDS (por
  defecto TRUE).

## Value

Un tibble que contiene los datos de los users recuperados.

## Examples

``` r
if (FALSE) { # \dontrun{
# Sin autenticación
getUsersData(urls_users = "https://x.com/estacion_erre")

# Con autenticación
getUsersData(urls_users = "https://x.com/estacion_erre", open = TRUE)

# Sin guardar los resultados
getUsersData(urls_users = "https://x.com/estacion_erre", save = FALSE)
} # }
```
