# Get the "About this account" Data of Users via the X API (experimental)

[![\[Experimental\]](https://lifecycle.r-lib.org/articles/figures/lifecycle-experimental.svg)](https://lifecycle.r-lib.org/articles/stages.html#experimental)

Recupera la ficha "Acerca de esta cuenta" de unx o varixs usuarixs
consultando la **API GraphQL interna de X** (AboutAccountQuery): el pais
desde el que opera la cuenta, cuantas veces cambio de nombre de usuarix,
desde cuando esta verificada, etc. Util para estudiar redes de cuentas
coordinadas o de origen extranjero. Requiere una sesion importada con
[`importSessionX()`](https://agusnieto77.github.io/TweetScraperR/reference/importSessionX.md).
X no publica todos los campos para todas las cuentas; los ausentes
quedan en NA.

## Usage

``` r
getUsersAboutAPI(usernames, dir = getwd(), save = TRUE)
```

## Arguments

- usernames:

  Vector de nombres de usuarix (acepta "NASA", "@NASA" o la URL
  completa).

- dir:

  Directorio de destino del RDS. Por defecto el de trabajo.

- save:

  Logico. Si TRUE (por defecto) guarda el resultado en un RDS.

## Value

Un tibble con una fila por usuarix y columnas user, nombre, user_id,
pais_cuenta, ubicacion_precisa, cambios_usuario, ultimo_cambio_usuario,
afiliada_a, origen_cuenta, identidad_verificada, verificada_desde,
fecha_creacion y url.

## Examples

``` r
if (FALSE) { # \dontrun{
importSessionX(auth_token = "...", ct0 = "...")
getUsersAboutAPI(c("NASA", "rstatstweet"))
} # }
```
