#' Authenticate and Log In to Twitter
#'
#' Esta función realiza la autenticación en Twitter y luego inicia sesión.
#'
#' @description
#' Esta función automatiza el proceso de autenticación y inicio de sesión en Twitter utilizando las credenciales proporcionadas.
#'
#' @details
#' Utiliza la librería rvest para realizar la interacción con la página de inicio de sesión de Twitter.
#'
#' @return Esta función no devuelve ningún valor, solo autentica y realiza el inicio de sesión en Twitter.
#'
#' @export
#'
#' @examples
#' \dontrun{
#' getAuthentication()
#' }
#'
#' @import rvest
#'
#' @references
#' Para obtener más información sobre la autenticación en Twitter, consulta la documentación del paquete.
#'


getAuthentication <- function() {
  twitter <- rvest::read_html_live("https://twitter.com/i/flow/login")
  Sys.sleep(3)
  userx <- "input"
  nextx <- "#layers div > div > div > button:nth-child(6) > div"
  passx <- "#layers > div > div > div > div > div > div > div > div > div > div > div > div > div > div > div > div > div > label > div > div > div > input"
  login <- "#layers > div > div > div > div > div > div > div.css-175oi2r > div.css-175oi2r > div > div > div.css-175oi2r > div.css-175oi2r.r-16y2uox > div.css-175oi2r > div > div.css-175oi2r > div > div > button"
  twitter$type(css = userx, text = xuser)
  twitter$click(css = nextx, n_clicks = 1)
  twitter$type(css = passx, text = xpass)
  twitter$click(css = login, n_clicks = 1)
}
