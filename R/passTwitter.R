#' Input Twitter Password for Authentication
#'
#' @description
#'
#' <a href="https://lifecycle.r-lib.org/articles/stages.html#experimental" target="_blank"><img src="https://lifecycle.r-lib.org/articles/figures/lifecycle-experimental.svg" alt="[Experimental]"></a>
#'
#' Esta funci\u00f3n automatiza el segundo paso del proceso de autenticaci\u00f3n en Twitter/X al ingresar
#' la contrase\u00f1a en el campo correspondiente de la interfaz de login. La funci\u00f3n localiza
#' el campo de entrada de contrase\u00f1a mediante selectores CSS espec\u00edficos, ingresa la contrase\u00f1a
#' proporcionada y procede a hacer clic en el bot\u00f3n "Iniciar sesi\u00f3n" para completar el proceso
#' de autenticaci\u00f3n.
#'
#' La funci\u00f3n utiliza el objeto `twitter` (una instancia de navegador web automatizado) para
#' interactuar con los elementos de la p\u00e1gina web. Despu\u00e9s de ingresar la contrase\u00f1a,
#' la funci\u00f3n incluye una pausa de 1 segundo para permitir que la p\u00e1gina procese la entrada
#' antes de proceder con el clic en el bot\u00f3n de login.
#'
#' Esta funci\u00f3n forma parte del flujo de autenticaci\u00f3n automatizada del paquete TweetScraperR
#' y debe utilizarse despu\u00e9s de la funci\u00f3n `userTwitter()` para completar el proceso de
#' autenticaci\u00f3n en Twitter/X. Una vez ejecutada exitosamente, el usuario quedar\u00e1 autenticado
#' y podr\u00e1 proceder con las funciones de scraping de tweets.
#'
#' @param xpass Contrase\u00f1a de Twitter/X para autenticaci\u00f3n. Por defecto es el valor
#' de la variable de entorno del sistema PASS obtenido mediante `Sys.getenv("PASS")`.
#'
#' @return La funci\u00f3n no retorna ning\u00fan valor. Su prop\u00f3sito es realizar acciones de automatizaci\u00f3n
#' en el navegador web para completar el paso de ingreso de contrase\u00f1a y finalizar el proceso
#' de autenticaci\u00f3n.
#'
#' @details
#' La funci\u00f3n utiliza selectores CSS altamente espec\u00edficos para localizar los elementos de la
#' interfaz de Twitter/X:
#'
#' - Campo de contrase\u00f1a: Un selector CSS complejo que navega a trav\u00e9s de m\u00faltiples capas de divs
#'   para encontrar el campo de entrada de texto de la contrase\u00f1a.
#' - Bot\u00f3n "Iniciar sesi\u00f3n": Selector que localiza el bot\u00f3n para completar el proceso de login.
#'
#' **Consideraciones de seguridad**: Para proteger las credenciales, se recomienda configurar
#' la variable de entorno PASS en lugar de pasar la contrase\u00f1a directamente como par\u00e1metro.
#'
#' @export
#'
#' @examples
#' \dontrun{
#' # Usar la contrase\u00f1a de la variable de entorno del sistema
#' passTwitter()
#'
#' # Especificar una contrase\u00f1a personalizada (NO recomendado para producci\u00f3n)
#' passTwitter(xpass = "mi_contrase\u00f1a_segura")
#'
#' # Ejemplo de flujo completo de autenticaci\u00f3n
#' userTwitter(xuser = "mi_usuario")
#' passTwitter(xpass = Sys.getenv("PASS"))
#'
#' # Configurar variables de entorno previamente (recomendado)
#' Sys.setenv(USER = "mi_usuario")
#' Sys.setenv(PASS = "mi_contrase\u00f1a")
#' userTwitter()
#' passTwitter()
#' }
#'
#' @references
#' Puedes encontrar m\u00e1s informaci\u00f3n sobre el paquete TweetScrapeR en:
#' <https://github.com/agusnieto77/TweetScraperR>
#'
#' @seealso
#' \code{\link{userTwitter}} para el paso anterior de autenticaci\u00f3n con nombre de usuario.
#' \code{\link{getTweetsSearchStreaming}} para obtener tweets despu\u00e9s de la autenticaci\u00f3n.

passTwitter <- function(xpass = Sys.getenv("PASS")) {
  passx <- "#layers > div > div > div > div > div > div > div > div > div > div > div > div > div > div > div > div > div > label > div > div > div > input"
  login <- "#layers > div > div > div > div > div > div > div.css-175oi2r > div.css-175oi2r > div > div > div.css-175oi2r > div.css-175oi2r.r-16y2uox > div.css-175oi2r > div > div.css-175oi2r > div > div > button"
  twitter$type(css = passx, text = xpass)
  Sys.sleep(1)
  twitter$click(css = login, n_clicks = 1)
}
