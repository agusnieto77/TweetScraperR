#' Input Twitter Username for Authentication
#'
#' @description
#'
#' <a href="https://lifecycle.r-lib.org/articles/stages.html#experimental" target="_blank"><img src="https://lifecycle.r-lib.org/articles/figures/lifecycle-experimental.svg" alt="[Experimental]"></a>
#'
#' Esta funci\u00f3n automatiza el primer paso del proceso de autenticaci\u00f3n en Twitter/X al ingresar
#' el nombre de usuario en el campo correspondiente de la interfaz de login. La funci\u00f3n localiza
#' el campo de entrada de usuario mediante selectores CSS espec\u00edficos, ingresa el nombre de usuario
#' proporcionado y procede a hacer clic en el bot\u00f3n "Siguiente" para continuar con el flujo de
#' autenticaci\u00f3n.
#'
#' La funci\u00f3n utiliza el objeto `twitter` (una instancia de navegador web automatizado) para
#' interactuar con los elementos de la p\u00e1gina web. Despu\u00e9s de ingresar el texto del usuario,
#' la funci\u00f3n incluye una pausa de 1 segundo para permitir que la p\u00e1gina procese la entrada
#' antes de proceder al siguiente paso.
#'
#' Esta funci\u00f3n forma parte del flujo de autenticaci\u00f3n automatizada del paquete TweetScraperR
#' y debe utilizarse en secuencia con otras funciones de autenticaci\u00f3n como `passTwitter()`
#' para completar el proceso de login.
#'
#' @param xuser Nombre de usuario de Twitter/X para autenticaci\u00f3n. Por defecto es el valor
#' de la variable de entorno del sistema USER obtenido mediante `Sys.getenv("USER")`.
#'
#' @return La funci\u00f3n no retorna ning\u00fan valor. Su prop\u00f3sito es realizar acciones de automatizaci\u00f3n
#' en el navegador web para completar el paso de ingreso de usuario en el proceso de autenticaci\u00f3n.
#'
#' @details
#' La funci\u00f3n utiliza selectores CSS altamente espec\u00edficos para localizar los elementos de la
#' interfaz de Twitter/X:
#'
#' - Campo de usuario: Un selector CSS complejo que navega a trav\u00e9s de m\u00faltiples capas de divs
#'   para encontrar el campo de entrada de texto del nombre de usuario.
#' - Bot\u00f3n "Siguiente": Selector que localiza el bot\u00f3n para proceder al siguiente paso del login.
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
#' # Ejemplo de uso en secuencia con otras funciones de autenticaci\u00f3n
#' userTwitter(xuser = "mi_usuario")
#' passTwitter(xpass = "mi_contrase\u00f1a")
#' }
#'
#' @references
#' Puedes encontrar m\u00e1s informaci\u00f3n sobre el paquete TweetScrapeR en:
#' <https://github.com/agusnieto77/TweetScraperR>
#'
#' @seealso
#' \code{\link{passTwitter}} para el siguiente paso de autenticaci\u00f3n con contrase\u00f1a.
#' \code{\link{getTweetsSearchStreaming}} para obtener tweets despu\u00e9s de la autenticaci\u00f3n.

userTwitter <- function(xuser = Sys.getenv("USER")) {
  userx <- "#layers > div > div > div > div > div > div > div.css-175oi2r > div.css-175oi2r > div > div > div.css-175oi2r > div.css-175oi2r > div > div > div > div.css-175oi2r > label > div > div.css-175oi2r > div > input"
  nextx <- "#layers div > div > div > button:nth-child(6) > div"
  twitter$type(css = userx, text = xuser)
  Sys.sleep(1)
  twitter$click(css = nextx, n_clicks = 1)
}
