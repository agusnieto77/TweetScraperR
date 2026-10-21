# Parseo de usuarios via API GraphQL/JSON de X (experimental, 0.4.0) --------
#
# Comparten parser: getUsersDataAPI (UserByScreenName, fetch crafteado),
# getUserFollowersAPI/getUserFollowingAPI y getTweetsRetweetsAPI (harvest de
# Followers/Following/Retweeters, que devuelven user entries).

#' Construye una fila-tibble de usuario a partir de un user_results$result
#' @noRd
#' @description Estructura 2026-10: X elimino el bloque `legacy` de usuarios.
#'   Los counts viven en `relationship_counts` (followers/following),
#'   `tweet_counts` (tweets) y `action_counts` (favorites_count); bio en
#'   `profile_bio`, avatar en `avatar`, banner en `banner`. Se conservan
#'   fallbacks a `legacy` por si X mezcla esquemas durante el rollout.
.user_row <- function(ur) {
  if (is.null(ur)) return(NULL)
  rc <- ur$relationship_counts
  tc <- ur$tweet_counts
  ac <- ur$action_counts
  pb <- ur$profile_bio
  lg <- ur$legacy
  cr <- ur$core
  handle <- .or_null(cr$screen_name, lg$screen_name)
  if (is.null(handle)) return(NULL)
  bio_web <- .or_null(pb$entities$url$urls, .or_null(lg$entities$url$urls, list()))
  web <- .entity_vec(bio_web, "expanded_url")
  vtype <- ur$verification$verified_type
  tibble::tibble(
    user             = paste0("@", handle),
    nombre           = .or_null(.or_null(cr$name, lg$name), NA_character_),
    user_id          = .or_null(ur$rest_id, NA_character_),
    descripcion      = .or_null(.or_null(pb$description, lg$description), NA_character_),
    seguidores       = as.integer(.or_null(.or_null(rc$followers, lg$followers_count), NA)),
    siguiendo        = as.integer(.or_null(.or_null(rc$following, lg$friends_count), NA)),
    tweets           = as.integer(.or_null(.or_null(tc$tweets, lg$statuses_count), NA)),
    favoritos        = as.integer(.or_null(.or_null(ac$favorites_count, lg$favourites_count), NA)),
    verificado       = isTRUE(ur$is_blue_verified) || (!is.null(vtype) && nzchar(vtype)) || isTRUE(lg$verified),
    ubicacion        = .or_null(.or_null(ur$location$location, lg$location), NA_character_),
    sitio_web        = if (length(web)) web[1] else .or_null(.or_null(ur$website$url, NA_character_), NA_character_),
    imagen_perfil    = .or_null(.or_null(ur$avatar$image_url, lg$profile_image_url_https), NA_character_),
    banner           = .or_null(.or_null(ur$banner$image_url, lg$profile_banner_url), NA_character_),
    fecha_creacion   = .x_parse_twitter_date(.or_null(.or_null(cr$created_at, lg$created_at), NA_character_)),
    url              = paste0("https://x.com/", handle),
    tweets_media     = as.integer(.or_null(.or_null(tc$media_tweets, lg$media_count), NA)),
    protegida        = isTRUE(.or_null(ur$privacy$protected, lg$protected)),
    tipo_verificacion = if (is.null(vtype) || !nzchar(vtype)) NA_character_ else vtype
  )
}

#' Extrae usuarios y cursor de una respuesta de timeline de usuarios GraphQL
#' @noRd
.parse_users <- function(d) {
  insts <- .find_instructions(d)
  if (is.null(insts)) return(list(users = NULL, cursor = NA_character_))
  rows <- list()
  cursor <- NA_character_
  for (ins in insts) {
    for (e in .or_null(ins$entries, list())) {
      if (grepl("^cursor-bottom", .or_null(e$entryId, ""))) {
        cursor <- .or_null(e$content$value, cursor)
        next
      }
      ur <- e$content$itemContent$user_results$result
      row <- .user_row(ur)
      if (!is.null(row)) rows[[length(rows) + 1L]] <- row
    }
  }
  list(
    users = if (length(rows)) dplyr::bind_rows(rows) else NULL,
    cursor = cursor
  )
}

#' Recolecta usuarios cosechando una pagina (Followers/Following/Retweeters)
#' @noRd
.collect_users <- function(url, op_name, n_users, dir, save, prefix) {
  docs <- .pw_harvest(url, op_name, max_scrolls = .scrolls_for(n_users), n = n_users, unit = "users")
  rows <- list()
  for (d in docs) {
    p <- .parse_users(d)
    if (!is.null(p$users)) rows[[length(rows) + 1L]] <- p$users
  }
  users <- if (length(rows)) {
    dplyr::distinct(dplyr::bind_rows(rows), user_id, .keep_all = TRUE)
  } else {
    tibble::tibble()
  }
  if (nrow(users) > n_users) users <- utils::head(users, n_users)
  cat("Usuarios \u00fanicos recolectados:", nrow(users), "\n")
  .save_rds(users, dir, prefix, save = save)
  users
}

#' Get a User's Profile Data via the X API (experimental)
#'
#' @description
#'
#' <a href="https://lifecycle.r-lib.org/articles/stages.html#experimental" target="_blank"><img src="https://lifecycle.r-lib.org/articles/figures/lifecycle-experimental.svg" alt="[Experimental]"></a>
#'
#' Recupera los datos de perfil de unx o varixs usuarixs consultando la **API
#' GraphQL interna de X** (UserByScreenName). Requiere una sesion importada con
#' [importSessionX()].
#'
#' @param usernames Vector de nombres de usuarix (sin @).
#' @param dir Directorio de destino del RDS. Por defecto el de trabajo.
#' @param save Logico. Si TRUE guarda el resultado en un RDS dentro de `dir`.
#'   Por defecto FALSE: no se escribe ningun archivo.
#'
#' @return Un tibble con una fila por usuarix y columnas user, nombre, user_id,
#'   descripcion, seguidores, siguiendo, tweets, favoritos, verificado,
#'   ubicacion, sitio_web, imagen_perfil, banner, fecha_creacion, url,
#'   tweets_media, protegida y tipo_verificacion.
#' @export
#'
#' @examples
#' \dontrun{
#' importSessionX(auth_token = "...", ct0 = "...")
#' getUsersDataAPI(c("NASA", "rstatstweet"))
#' }
getUsersDataAPI <- function(usernames, dir = getwd(), save = FALSE) {
  if (missing(usernames) || !length(usernames)) stop("Necesito al menos un nombre de usuarix.")
  # Una sola sesion de navegador para TODOS los perfiles (batch).
  grupos <- .pw_harvest_batch(paste0("https://x.com/", usernames), "UserByScreenName",
                              max_scrolls = 2, n = 1, unit = "users")
  rows <- list()
  for (k in seq_along(grupos)) {
    row <- NULL
    for (d in grupos[[k]]) {
      row <- .user_row(d$data$user$result)
      if (!is.null(row)) break
    }
    if (!is.null(row)) rows[[length(rows) + 1L]] <- row else warning("No se encontr\u00f3 @", usernames[k])
  }
  users <- if (length(rows)) dplyr::bind_rows(rows) else tibble::tibble()
  .save_rds(users, dir, "api_users", save = save)
  users
}

#' Get a User's Followers via the X API (experimental)
#'
#' @description
#'
#' <a href="https://lifecycle.r-lib.org/articles/stages.html#experimental" target="_blank"><img src="https://lifecycle.r-lib.org/articles/figures/lifecycle-experimental.svg" alt="[Experimental]"></a>
#'
#' Recupera lxs seguidorxs de unx usuarix consultando la **API GraphQL interna
#' de X** (Followers). Requiere una sesion importada con [importSessionX()].
#'
#' @param username Nombre de usuarix (sin @).
#' @param n_users Numero maximo de usuarixs a recuperar. Por defecto 100.
#' @param dir Directorio de destino del RDS. Por defecto el de trabajo.
#' @param save Logico. Si TRUE guarda el resultado en un RDS dentro de `dir`.
#'   Por defecto FALSE: no se escribe ningun archivo.
#'
#' @return Un tibble con una fila por usuarix (mismas columnas que getUsersDataAPI).
#' @export
#'
#' @examples
#' \dontrun{
#' importSessionX(auth_token = "...", ct0 = "...")
#' getUserFollowersAPI("rstatstweet", n_users = 200)
#' }
getUserFollowersAPI <- function(username, n_users = 100, dir = getwd(), save = FALSE) {
  if (missing(username) || !nzchar(username)) stop("Necesito un nombre de usuarix.")
  cat("Recolectando seguidorxs de @", username, "...\n", sep = "")
  .collect_users(
    paste0("https://x.com/", username, "/followers"), "Followers",
    n_users, dir, save, paste0("api_followers_", username)
  )
}

#' Get the Accounts a User Follows via the X API (experimental)
#'
#' @description
#'
#' <a href="https://lifecycle.r-lib.org/articles/stages.html#experimental" target="_blank"><img src="https://lifecycle.r-lib.org/articles/figures/lifecycle-experimental.svg" alt="[Experimental]"></a>
#'
#' Recupera las cuentas que sigue unx usuarix consultando la **API GraphQL
#' interna de X** (Following). Requiere una sesion importada con [importSessionX()].
#'
#' @param username Nombre de usuarix (sin @).
#' @param n_users Numero maximo de usuarixs a recuperar. Por defecto 100.
#' @param dir Directorio de destino del RDS. Por defecto el de trabajo.
#' @param save Logico. Si TRUE guarda el resultado en un RDS dentro de `dir`.
#'   Por defecto FALSE: no se escribe ningun archivo.
#'
#' @return Un tibble con una fila por usuarix (mismas columnas que getUsersDataAPI).
#' @export
#'
#' @examples
#' \dontrun{
#' importSessionX(auth_token = "...", ct0 = "...")
#' getUserFollowingAPI("rstatstweet", n_users = 200)
#' }
getUserFollowingAPI <- function(username, n_users = 100, dir = getwd(), save = FALSE) {
  if (missing(username) || !nzchar(username)) stop("Necesito un nombre de usuarix.")
  cat("Recolectando cuentas que sigue @", username, "...\n", sep = "")
  .collect_users(
    paste0("https://x.com/", username, "/following"), "Following",
    n_users, dir, save, paste0("api_following_", username)
  )
}

#' Get the Users Who Retweeted a Tweet via the X API (experimental)
#'
#' @description
#'
#' <a href="https://lifecycle.r-lib.org/articles/stages.html#experimental" target="_blank"><img src="https://lifecycle.r-lib.org/articles/figures/lifecycle-experimental.svg" alt="[Experimental]"></a>
#'
#' Recupera lxs usuarixs que repostearon un tweet consultando la **API GraphQL
#' interna de X** (Retweeters). Requiere una sesion importada con [importSessionX()].
#'
#' @param url URL del tweet.
#' @param n_users Numero maximo de usuarixs a recuperar. Por defecto 100.
#' @param dir Directorio de destino del RDS. Por defecto el de trabajo.
#' @param save Logico. Si TRUE guarda el resultado en un RDS dentro de `dir`.
#'   Por defecto FALSE: no se escribe ningun archivo.
#'
#' @return Un tibble con una fila por usuarix (mismas columnas que getUsersDataAPI).
#' @export
#'
#' @examples
#' \dontrun{
#' importSessionX(auth_token = "...", ct0 = "...")
#' getTweetsRetweetsAPI("https://x.com/sanchezcastejon/status/2111426246517072370", n_users = 100)
#' }
getTweetsRetweetsAPI <- function(url, n_users = 100, dir = getwd(), save = FALSE) {
  if (missing(url) || !nzchar(url)) stop("Necesito la URL de un tweet.")
  cat("Recolectando usuarixs que repostearon: ", url, "\n", sep = "")
  prefix <- paste0("api_rt_", gsub("https://x.com/(.*)/status/(.*)", "\\1_\\2", url))
  .collect_users(paste0(url, "/retweets"), "Retweeters", n_users, dir, save, prefix)
}

#' Fecha en milisegundos unix (string de X) a POSIXct UTC
#'
#' X oculta algunas fechas con valores negativos (p. ej. verificada "desde el
#' anio -3000"): se devuelven como NA.
#' @noRd
.x_msec <- function(x) {
  ms <- suppressWarnings(as.numeric(.or_null(x, NA)))
  if (is.na(ms) || ms < 0) return(as.POSIXct(NA, tz = "UTC"))
  as.POSIXct(ms / 1000, origin = "1970-01-01", tz = "UTC")
}

#' Fila-tibble de "Acerca de esta cuenta" (AboutAccountQuery)
#' @noRd
.about_row <- function(ur) {
  if (is.null(ur)) return(NULL)
  handle <- ur$core$screen_name
  if (is.null(handle)) return(NULL)
  ab <- ur$about_profile
  vi <- ur$verification_info
  tibble::tibble(
    user                  = paste0("@", handle),
    nombre                = .or_null(ur$core$name, NA_character_),
    user_id               = .or_null(ur$rest_id, NA_character_),
    pais_cuenta           = .or_null(ab$account_based_in, NA_character_),
    ubicacion_precisa     = as.logical(.or_null(ab$location_accurate, NA)),
    cambios_usuario       = as.integer(.or_null(ab$username_changes$count, NA)),
    ultimo_cambio_usuario = .x_msec(ab$username_changes$last_changed_at_msec),
    afiliada_a            = .or_null(ab$affiliate_username, NA_character_),
    origen_cuenta         = .or_null(ab$source, NA_character_),
    identidad_verificada  = as.logical(.or_null(vi$is_identity_verified, NA)),
    verificada_desde      = .x_msec(vi$reason$verified_since_msec),
    fecha_creacion        = .x_parse_twitter_date(.or_null(ur$core$created_at, NA_character_)),
    url                   = paste0("https://x.com/", handle)
  )
}

#' Get the "About this account" Data of Users via the X API (experimental)
#'
#' @description
#'
#' <a href="https://lifecycle.r-lib.org/articles/stages.html#experimental" target="_blank"><img src="https://lifecycle.r-lib.org/articles/figures/lifecycle-experimental.svg" alt="[Experimental]"></a>
#'
#' Recupera la ficha "Acerca de esta cuenta" de unx o varixs usuarixs
#' consultando la **API GraphQL interna de X** (AboutAccountQuery): el pais
#' desde el que opera la cuenta, cuantas veces cambio de nombre de usuarix,
#' desde cuando esta verificada, etc. Util para estudiar redes de cuentas
#' coordinadas o de origen extranjero. Requiere una sesion importada con
#' [importSessionX()]. X no publica todos los campos para todas las cuentas;
#' los ausentes quedan en NA.
#'
#' @param usernames Vector de nombres de usuarix (acepta "NASA", "@NASA" o la
#'   URL completa).
#' @param dir Directorio de destino del RDS. Por defecto el de trabajo.
#' @param save Logico. Si TRUE guarda el resultado en un RDS dentro de `dir`.
#'   Por defecto FALSE: no se escribe ningun archivo.
#'
#' @return Un tibble con una fila por usuarix y columnas user, nombre, user_id,
#'   pais_cuenta, ubicacion_precisa, cambios_usuario, ultimo_cambio_usuario,
#'   afiliada_a, origen_cuenta, identidad_verificada, verificada_desde,
#'   fecha_creacion y url.
#' @export
#'
#' @examples
#' \dontrun{
#' importSessionX(auth_token = "...", ct0 = "...")
#' getUsersAboutAPI(c("NASA", "rstatstweet"))
#' }
getUsersAboutAPI <- function(usernames, dir = getwd(), save = FALSE) {
  if (missing(usernames) || !length(usernames)) stop("Necesito al menos un nombre de usuarix.")
  usernames <- .x_handle(usernames)
  grupos <- .pw_harvest_batch(paste0("https://x.com/", usernames, "/about"), "AboutAccountQuery",
                              max_scrolls = 1, n = 1, unit = "users")
  rows <- list()
  for (k in seq_along(grupos)) {
    row <- NULL
    for (d in grupos[[k]]) {
      row <- .about_row(d$data$user_result_by_screen_name$result)
      if (!is.null(row)) break
    }
    if (!is.null(row)) rows[[length(rows) + 1L]] <- row else warning("No se encontr\u00f3 @", usernames[k])
  }
  users <- if (length(rows)) dplyr::bind_rows(rows) else tibble::tibble()
  .save_rds(users, dir, "api_about", save = save)
  users
}

#' Search Users via the X API (experimental)
#'
#' @description
#'
#' <a href="https://lifecycle.r-lib.org/articles/stages.html#experimental" target="_blank"><img src="https://lifecycle.r-lib.org/articles/figures/lifecycle-experimental.svg" alt="[Experimental]"></a>
#'
#' Busca cuentas (pestania "Personas" del buscador de X) consultando la **API
#' GraphQL interna de X** (SearchTimeline). Requiere una sesion importada con
#' [importSessionX()].
#'
#' @param search Consulta de busqueda (nombre, tema, etc.).
#' @param n_users Numero maximo de usuarixs a recuperar. Por defecto 40.
#' @param dir Directorio de destino del RDS. Por defecto el de trabajo.
#' @param save Logico. Si TRUE guarda el resultado en un RDS dentro de `dir`.
#'   Por defecto FALSE: no se escribe ningun archivo.
#'
#' @return Un tibble con una fila por usuarix (mismas columnas que getUsersDataAPI).
#' @export
#'
#' @examples
#' \dontrun{
#' importSessionX(auth_token = "...", ct0 = "...")
#' getUsersSearchAPI("rstats", n_users = 50)
#' }
getUsersSearchAPI <- function(search, n_users = 40, dir = getwd(), save = FALSE) {
  if (missing(search) || !nzchar(search)) stop("Necesito una consulta de b\u00fasqueda.")
  cat("Buscando usuarixs: ", search, "\n", sep = "")
  .collect_users(.search_url(search, "user"), "SearchTimeline", n_users, dir, save,
                 paste0("api_users_search_", gsub("[^A-Za-z0-9]+", "_", search)))
}
