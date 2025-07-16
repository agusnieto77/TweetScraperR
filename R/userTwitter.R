#' Input Twitter Username for Authentication
#' 
#' @description
#' 
#' <a href="https://lifecycle.r-lib.org/articles/stages.html#experimental" target="_blank"><img src="https://lifecycle.r-lib.org/articles/figures/lifecycle-experimental.svg" alt="[Experimental]"></a>
#' 
#' Esta función automatiza el primer paso del proceso de autenticación en Twitter/X al ingresar 
#' el nombre de usuario en el campo correspondiente de la interfaz de login. La función localiza 
#' el campo de entrada de usuario mediante selectores CSS específicos, ingresa el nombre de usuario 
#' proporcionado y procede a hacer clic en el botón "Siguiente" para continuar con el flujo de 
#' autenticación.
#' 
#' La función utiliza el objeto `twitter` (una instancia de navegador web automatizado) para 
#' interactuar con los elementos de la página web. Después de ingresar el texto del usuario, 
#' la función incluye una pausa de 1 segundo para permitir que la página procese la entrada 
#' antes de proceder al siguiente paso.
#' 
#' Esta función forma parte del flujo de autenticación automatizada del paquete TweetScraperR 
#' y debe utilizarse en secuencia con otras funciones de autenticación como `passTwitter()` 
#' para completar el proceso de login.
#' 
#' @param xuser Nombre de usuario de Twitter/X para autenticación. Por defecto es el valor 
#' de la variable de entorno del sistema USER obtenido mediante `Sys.getenv("USER")`.
#' 
#' @return La función no retorna ningún valor. Su propósito es realizar acciones de automatización 
#' en el navegador web para completar el paso de ingreso de usuario en el proceso de autenticación.
#' 
#' @details 
#' La función utiliza selectores CSS altamente específicos para localizar los elementos de la 
#' interfaz de Twitter/X:
#' 
#' - Campo de usuario: Un selector CSS complejo que navega a través de múltiples capas de divs 
#'   para encontrar el campo de entrada de texto del nombre de usuario.
#' - Botón "Siguiente": Selector que localiza el botón para proceder al siguiente paso del login.
#' 
#' @export
#'
#' @examples
#' \dontrun{
#' # Usar el nombre de usuario del sistema operativo
#' userTwitter()
#' 
#' # Especificar un nombre de usuario personalizado
#' userTwitter(xuser = "mi_usuario_twitter")
#' 
#' # Usar una variable con el nombre de usuario
#' usuario <- "ejemplo_usuario"
#' userTwitter(xuser = usuario)
#' 
#' # Ejemplo de uso en secuencia con otras funciones de autenticación
#' userTwitter(xuser = "mi_usuario")
#' passTwitter(xpass = "mi_contraseña")
#' }
#'
#' @references
#' Puedes encontrar más información sobre el paquete TweetScrapeR en:
#' <https://github.com/agusnieto77/TweetScraperR>
#'
#' @seealso 
#' \code{\link{passTwitter}} para el siguiente paso de autenticación con contraseña.
#' \code{\link{getTweetsSearchStreaming}} para obtener tweets después de la autenticación.

userTwitter <- function(xuser = Sys.getenv("USER")) {
  userx <- "#layers > div > div > div > div > div > div > div.css-175oi2r > div.css-175oi2r > div > div > div.css-175oi2r > div.css-175oi2r > div > div > div > div.css-175oi2r > label > div > div.css-175oi2r > div > input"
  nextx <- "#layers div > div > div > button:nth-child(6) > div"
  twitter$type(css = userx, text = xuser)
  Sys.sleep(1)
  twitter$click(css = nextx, n_clicks = 1)
}
