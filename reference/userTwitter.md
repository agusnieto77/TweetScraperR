# Input Twitter Username for Authentication

[![\[Experimental\]](https://lifecycle.r-lib.org/articles/figures/lifecycle-experimental.svg)](https://lifecycle.r-lib.org/articles/stages.html#experimental)

**Obsoleta**: el login automatizado por navegador ya no funciona porque
X lo bloquea por fingerprint. Usá `importSessionX(auth_token, ct0)` para
cargar tu sesión desde el navegador.

Esta función automatiza el primer paso del proceso de autenticación en
Twitter/X al ingresar el nombre de usuario en el campo correspondiente
de la interfaz de login. La función localiza el campo de entrada de
usuario mediante selectores CSS específicos, ingresa el nombre de
usuario proporcionado y procede a hacer clic en el botón "Siguiente"
para continuar con el flujo de autenticación.

La función utiliza el objeto `twitter` (una instancia de navegador web
automatizado) para interactuar con los elementos de la página web.
Después de ingresar el texto del usuario, la función incluye una pausa
de 1 segundo para permitir que la página procese la entrada antes de
proceder al siguiente paso.

Esta función forma parte del flujo de autenticación automatizada del
paquete TweetScraperR y debe utilizarse en secuencia con otras funciones
de autenticación como
[`passTwitter()`](https://agusnieto77.github.io/TweetScraperR/reference/passTwitter.md)
para completar el proceso de login.

## Usage

``` r
userTwitter(xuser = Sys.getenv("TWITTER_USER", Sys.getenv("USER")))
```

## Arguments

- xuser:

  Nombre de usuario de Twitter/X para autenticación. Por defecto es el
  valor de la variable de entorno TWITTER_USER y, si no está definida,
  el de la variable de entorno del sistema USER, obtenido mediante
  `Sys.getenv("TWITTER_USER", Sys.getenv("USER"))`.

## Value

La función no retorna ningún valor. Su propósito es realizar acciones de
automatización en el navegador web para completar el paso de ingreso de
usuario en el proceso de autenticación.

## Details

La función utiliza selectores CSS altamente específicos para localizar
los elementos de la interfaz de Twitter/X:

- Campo de usuario: Un selector CSS complejo que navega a través de
  múltiples capas de divs para encontrar el campo de entrada de texto
  del nombre de usuario.

- Botón "Siguiente": Selector que localiza el botón para proceder al
  siguiente paso del login.

## References

Puedes encontrar más información sobre el paquete TweetScrapeR en:
<https://github.com/agusnieto77/TweetScraperR>

## See also

[`passTwitter`](https://agusnieto77.github.io/TweetScraperR/reference/passTwitter.md)
para el siguiente paso de autenticación con contraseña.
[`getTweetsSearchStreaming`](https://agusnieto77.github.io/TweetScraperR/reference/getTweetsSearchStreaming.md)
para obtener tweets después de la autenticación.

## Examples

``` r
if (FALSE) { # \dontrun{
# Usar el nombre de usuario de la variable de entorno TWITTER_USER (o USER)
userTwitter()

# Especificar un nombre de usuario personalizado
userTwitter(xuser = "mi_usuario_twitter")

# Usar una variable con el nombre de usuario
usuario <- "ejemplo_usuario"
userTwitter(xuser = usuario)

# Ejemplo de uso en secuencia con otras funciones de autenticación
userTwitter(xuser = "mi_usuario")
passTwitter(xpass = "mi_contraseña")
} # }
```
