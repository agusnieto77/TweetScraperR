#' Input Twitter Password for Authentication
#'
#' @description
#'
#' <a href="https://lifecycle.r-lib.org/articles/stages.html#experimental" target="_blank"><img src="https://lifecycle.r-lib.org/articles/figures/lifecycle-experimental.svg" alt="[Experimental]"></a>
#'
#' @description
#' **Obsoleta**: el login automatizado por navegador ya no funciona porque X lo bloquea por fingerprint.
#' Usá `importSessionX(auth_token, ct0)` para cargar tu sesión desde el navegador.
#'
#' Esta función automatiza el segundo paso del proceso de autenticación en Twitter/X al ingresar
#' la contraseña en el campo correspondiente de la interfaz de login. La función localiza
#' el campo de entrada de contraseña mediante selectores CSS específicos, ingresa la contraseña
#' proporcionada y procede a hacer clic en el botón "Iniciar sesión" para completar el proceso
#' de autenticación.
#'
#' La función utiliza el objeto `twitter` (una instancia de navegador web automatizado) para
#' interactuar con los elementos de la página web. Después de ingresar la contraseña,
#' la función incluye una pausa de 1 segundo para permitir que la página procese la entrada
#' antes de proceder con el clic en el botón de login.
#'
#' Esta función forma parte del flujo de autenticación automatizada del paquete TweetScraperR
#' y debe utilizarse después de la función `userTwitter()` para completar el proceso de
#' autenticación en Twitter/X. Una vez ejecutada exitosamente, el usuario quedará autenticado
#' y podrá proceder con las funciones de scraping de tweets.
#'
#' @param xpass Contraseña de Twitter/X para autenticación. Por defecto es el valor
#' de la variable de entorno TWITTER_PASS y, si no está definida, el de la variable de
#' entorno del sistema PASS, obtenido mediante `Sys.getenv("TWITTER_PASS", Sys.getenv("PASS"))`.
#'
#' @return La función no retorna ningún valor. Su propósito es realizar acciones de automatización
#' en el navegador web para completar el paso de ingreso de contraseña y finalizar el proceso
#' de autenticación.
#'
#' @details
#' La función utiliza selectores CSS altamente específicos para localizar los elementos de la
#' interfaz de Twitter/X:
#'
#' - Campo de contraseña: Un selector CSS complejo que navega a través de múltiples capas de divs
#'   para encontrar el campo de entrada de texto de la contraseña.
#' - Botón "Iniciar sesión": Selector que localiza el botón para completar el proceso de login.
#'
#' **Consideraciones de seguridad**: Para proteger las credenciales, se recomienda configurar
#' la variable de entorno TWITTER_PASS en lugar de pasar la contraseña directamente como parámetro.
#'
#' @export
#'
#' @examples
#' \dontrun{
#' # Usar la contraseña de la variable de entorno TWITTER_PASS (o PASS)
#' passTwitter()
#'
#' # Especificar una contraseña personalizada (NO recomendado para producción)
#' passTwitter(xpass = "mi_contraseña_segura")
#'
#' # Ejemplo de flujo completo de autenticación
#' userTwitter(xuser = "mi_usuario")
#' passTwitter(xpass = Sys.getenv("TWITTER_PASS"))
#'
#' # Configurar variables de entorno previamente (recomendado)
#' Sys.setenv(TWITTER_USER = "mi_usuario")
#' Sys.setenv(TWITTER_PASS = "mi_contraseña")
#' userTwitter()
#' passTwitter()
#' }
#'
#' @references
#' Puedes encontrar más información sobre el paquete TweetScrapeR en:
#' <https://github.com/agusnieto77/TweetScraperR>
#'
#' @seealso
#' \code{\link{userTwitter}} para el paso anterior de autenticación con nombre de usuario.
#' \code{\link{getTweetsSearchStreaming}} para obtener tweets después de la autenticación.

passTwitter <- function(xpass = Sys.getenv("TWITTER_PASS", Sys.getenv("PASS"))) {
  .Deprecated(msg = "passTwitter() qued\u00f3 obsoleta: X bloquea el login automatizado. Us\u00e1 importSessionX(auth_token, ct0) para cargar tu sesi\u00f3n desde el navegador. Ver ?importSessionX.")
  .x_fill(twitter, .sel$login_pass, xpass)
  Sys.sleep(1)
  .x_click_text(twitter, c("Iniciar sesi\u00f3n", "Acceder", "Entrar", "Log in", "Continuar"))
}
