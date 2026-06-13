# Helpers internos de sesion (login, navegacion con retry, cierre) --------

#' Evalua JavaScript en una sesion live y devuelve el resultado
#'
#' Envoltura fina sobre la API CDP de chromote (Runtime.evaluate) expuesta por
#' el objeto LiveHTML de rvest. Se usa para manejar el modal de login de X, que
#' es una SPA de React con DOM duplicado (formulario visible vs. oculto) donde
#' los metodos de nodo de rvest ($type/$click) fallan por nodos obsoletos.
#'
#' @param session Sesion live (objeto LiveHTML de rvest).
#' @param js Cadena de JavaScript a evaluar.
#'
#' @return El valor de retorno de la expresion JS.
#' @noRd
.x_eval <- function(session, js) {
  session$session$Runtime$evaluate(js)$result$value
}

#' Escribe un valor en el primer input VISIBLE que matchea el selector CSS
#'
#' Inyecta el valor con el setter nativo de `value` (necesario para que los
#' inputs controlados de React de X registren el cambio) y dispara los eventos
#' input/change. Filtra por visibilidad (offsetParent) para ignorar el
#' formulario oculto del modal de login duplicado.
#'
#' @param session Sesion live (objeto LiveHTML de rvest).
#' @param css Selector CSS del input.
#' @param value Texto a escribir.
#'
#' @return "OK" si escribio, "NO-VISIBLE" si no encontro un input visible.
#' @noRd
.x_fill <- function(session, css, value) {
  js <- sprintf(
    "(function(){function vis(el){return el&&el.offsetParent!==null&&el.getClientRects().length>0;}var els=Array.from(document.querySelectorAll(%s)).filter(vis);if(!els.length)return 'NO-VISIBLE';var el=els[0];el.focus();var proto=el.tagName==='TEXTAREA'?window.HTMLTextAreaElement.prototype:window.HTMLInputElement.prototype;var setter=Object.getOwnPropertyDescriptor(proto,'value').set;setter.call(el,%s);el.dispatchEvent(new Event('input',{bubbles:true}));el.dispatchEvent(new Event('change',{bubbles:true}));return 'OK';})()",
    jsonlite::toJSON(css, auto_unbox = TRUE),
    jsonlite::toJSON(value, auto_unbox = TRUE)
  )
  .x_eval(session, js)
}

#' Clickea el primer boton VISIBLE cuyo texto coincide con alguno de `texts`
#'
#' X renderiza los botones del flujo de login como `div[role=button]` sin
#' data-testid estable, por lo que se identifican por su texto visible. Se
#' prueba cada texto en orden y se clickea el primero que matchea.
#'
#' @param session Sesion live (objeto LiveHTML de rvest).
#' @param texts Vector de textos candidatos (p.ej. c("Continuar", "Siguiente")).
#'
#' @return "CLICK:<texto>" si clickeo, "NO-BTN" si no encontro ninguno.
#' @noRd
.x_click_text <- function(session, texts) {
  js <- sprintf(
    "(function(){function vis(el){return el&&el.offsetParent!==null&&el.getClientRects().length>0;}var texts=%s;var c=Array.from(document.querySelectorAll('button,[role=button]')).filter(vis);for(var i=0;i<texts.length;i++){var t=texts[i].toLowerCase();var el=c.find(function(e){return (e.innerText||'').trim().toLowerCase()===t;});if(el){el.click();return 'CLICK:'+texts[i];}}return 'NO-BTN';})()",
    jsonlite::toJSON(texts)
  )
  .x_eval(session, js)
}

#' Navega a una URL con rvest::read_html_live y retry acotado
#'
#' Encapsula el idioma legacy de reintento ante errores "loadEventFired"
#' (timeout de carga), con un tope de intentos que evita el loop infinito
#' del patron `while (!success)`. Cualquier otro error se re-lanza tal cual.
#'
#' @param url URL a cargar.
#' @param wait Segundos de espera entre reintentos (legacy: 5).
#' @param max_tries Numero maximo de intentos antes de abortar con error.
#'
#' @return La sesion live (objeto LiveHTML de rvest).
#' @noRd
.read_html_live_retry <- function(url, wait = 5, max_tries = 5) {
  for (intento in seq_len(max_tries)) {
    session <- NULL
    resultado <- tryCatch({
      session <- rvest::read_html_live(url)
      TRUE
    }, error = function(e) e)
    if (isTRUE(resultado)) {
      return(session)
    }
    # Cerrar la sesion parcial fallida (si llego a crearse) antes de seguir
    .close_sessions(session)
    if (!grepl("loadEventFired", conditionMessage(resultado))) {
      stop(resultado)
    }
    if (intento < max_tries) {
      message("Error de tiempo de espera, reintentando...")
      Sys.sleep(wait)
    }
  }
  stop("No se pudo cargar la p\u00e1gina despu\u00e9s de ", max_tries, " intentos: ", url)
}

#' Inicia sesion en X.com y devuelve siempre la sesion live
#'
#' Promocion a nivel de paquete del flujo de autenticacion (basado en el
#' .authenticate_twitter local de getTweetsSearchStreaming2.R): conexion a la
#' pagina de login con reintentos y backoff lineal, tipeo de credenciales con
#' los selectores centralizados de .sel y semantica legacy lenient ante
#' errores de tipeo (mensaje de cuenta ya autenticada + detalle del error,
#' y se continua con la sesion abierta). A diferencia de la version legacy,
#' NUNCA devuelve NULL: si no logra conectar, aborta con stop().
#'
#' @param xuser Usuario de X/Twitter.
#' @param xpass Contrasena de X/Twitter.
#' @param max_attempts Numero maximo de intentos de conexion a la pagina de login.
#'
#' @return La sesion live (objeto LiveHTML de rvest), siempre.
#' @noRd
.x_login <- function(xuser, xpass, max_attempts = 3) {
  twitter <- NULL
  login_attempts <- 0
  while (is.null(twitter) && login_attempts < max_attempts) {
    resultado <- tryCatch({
      twitter <- rvest::read_html_live(.sel$login_url)
      TRUE
    }, error = function(e) e)
    if (!isTRUE(resultado)) {
      login_attempts <- login_attempts + 1
      if (grepl("loadEventFired", conditionMessage(resultado))) {
        message("Error de timeout en conexi\u00f3n, reintentando en ", login_attempts * 2, " segundos...")
        Sys.sleep(login_attempts * 2)
      } else {
        stop(resultado)
      }
    }
  }
  if (is.null(twitter)) {
    stop("No se pudo conectar a la p\u00e1gina de login despu\u00e9s de ", max_attempts, " intentos")
  }
  Sys.sleep(3)
  tryCatch({
    # Paso 1: usuario. Modal nuevo de X = un solo formulario donde se tipea el
    # usuario y se confirma con "Continuar"; el flujo clasico usaba "Siguiente".
    .x_fill(twitter, .sel$login_user, xuser)
    Sys.sleep(1.5)
    .x_click_text(twitter, c("Continuar", "Siguiente", "Next"))
    Sys.sleep(3)
    # Paso 2: contrasena. El boton final es "Iniciar sesion" (o "Continuar" en
    # el modal consolidado).
    .x_fill(twitter, .sel$login_pass, xpass)
    Sys.sleep(1.5)
    .x_click_text(twitter, c("Iniciar sesi\u00f3n", "Acceder", "Entrar", "Log in", "Continuar"))
    Sys.sleep(3)
  }, error = function(e) {
    message("La cuenta ya est\u00e1 autenticada o ha ocurrido un error. ", conditionMessage(e))
  })
  twitter
}

#' Cierra de forma segura una o mas sesiones live
#'
#' Cierra el $session de cada argumento no-NULL dentro de un tryCatch
#' silencioso. Pensado para registrarse con on.exit(..., add = TRUE)
#' inmediatamente despues de crear cada sesion, lo que ademas corrige los
#' cierres inalcanzables ubicados despues de return().
#'
#' @param ... Objetos LiveHTML (o NULL) a cerrar.
#'
#' @return NULL, de forma invisible.
#' @noRd
.close_sessions <- function(...) {
  sesiones <- list(...)
  for (s in sesiones) {
    if (!is.null(s)) {
      tryCatch(s$session$close(), error = function(e) NULL)
    }
  }
  invisible(NULL)
}
