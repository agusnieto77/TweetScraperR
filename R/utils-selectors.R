# Selectores internos de X.com -------------------------------------------
#
# Lista centralizada con los selectores CSS de X.com que estaban duplicados
# como literales en los archivos R/get*.R (la plantilla es la lista .SELECTORS
# que vivia dentro de getTweetsSearchStreaming2.R). Cuando X cambie su DOM,
# este es el unico archivo que hay que editar.

#' Selectores CSS internos de X.com
#'
#' Lista interna con la URL de login y los selectores CSS usados por los
#' helpers internos y las funciones exportadas del paquete. Los strings estan
#' copiados exactamente de los literales legacy.
#'
#' @noRd
.sel <- list(
  login_url   = "https://x.com/i/flow/login",
  # Selectores de login basados en ATRIBUTOS estables (name/autocomplete), no en
  # las clases generadas que X reescribe en cada deploy. El modal de login actual
  # usa name='username_or_email'; el flujo clasico usaba name='text'. Se cubren
  # ambos mas el fallback por autocomplete. Los botones del flujo (Continuar /
  # Iniciar sesion) no tienen selector estable: se clickean por texto visible
  # con .x_click_text() en R/utils-session.R.
  login_user  = "input[name='username_or_email'], input[name='text'], input[autocomplete~='username']",
  login_pass  = "input[name='password']",
  tweet_url   = "div.css-175oi2r > div > div.css-175oi2r > a.css-146c3p1.r-bcqeeo.r-1ttztb7.r-qvutc0.r-37j5jr.r-a023e6",
  tweet_user  = "div.css-175oi2r.r-18u37iz.r-1wbh5a2.r-1ez5h0i > div > div.css-175oi2r.r-1wbh5a2.r-dnmrzs > a > div > span",
  tweet_text  = "div[data-testid='tweetText']",
  tweet_time  = "time",
  article     = "article",
  quoted_user = "div.css-175oi2r.r-1wbh5a2.r-dnmrzs > div > div > span",
  tweet_emoji = "div[data-testid='tweetText'] img"
)
