# Parseo de usuarios via API GraphQL/JSON de X (experimental, 0.4.0) --------
#
# Comparten parser: getUsersDataAPI (UserByScreenName, fetch crafteado),
# getUserFollowersAPI/getUserFollowingAPI y getTweetsRetweetsAPI (harvest de
# Followers/Following/Retweeters, que devuelven user entries).

#' Construye una fila-tibble de usuario a partir de un user_results$result
#' @noRd
.user_row <- function(ur) {
  if (is.null(ur)) return(NULL)
  lg <- ur$legacy
  cr <- ur$core
  handle <- .or_null(cr$screen_name, lg$screen_name)
  if (is.null(handle)) return(NULL)
  tibble::tibble(
    user             = paste0("@", handle),
    nombre           = .or_null(.or_null(cr$name, lg$name), NA_character_),
    user_id          = .or_null(ur$rest_id, NA_character_),
    descripcion      = .or_null(lg$description, NA_character_),
    seguidores       = as.integer(.or_null(lg$followers_count, NA)),
    siguiendo        = as.integer(.or_null(lg$friends_count, NA)),
    tweets           = as.integer(.or_null(lg$statuses_count, NA)),
    favoritos        = as.integer(.or_null(lg$favourites_count, NA)),
    verificado       = isTRUE(ur$is_blue_verified) || isTRUE(lg$verified),
    ubicacion        = .or_null(.or_null(ur$location$location, lg$location), NA_character_),
    fecha_creacion   = .x_parse_twitter_date(.or_null(cr$created_at, lg$created_at)),
    url              = paste0("https://x.com/", handle)
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
  scrolls <- max(3L, as.integer(ceiling(n_users / 15) + 3L))
  docs <- .pw_harvest(url, op_name, max_scrolls = scrolls)
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
#' @param save Logico. Si TRUE (por defecto) guarda el resultado en un RDS.
#'
#' @return Un tibble con una fila por usuarix y columnas user, nombre, user_id,
#'   descripcion, seguidores, siguiendo, tweets, favoritos, verificado,
#'   ubicacion, fecha_creacion, url.
#' @export
#'
#' @examples
#' \dontrun{
#' importSessionX(auth_token = "...", ct0 = "...")
#' getUsersDataAPI(c("NASA", "rstatstweet"))
#' }
getUsersDataAPI <- function(usernames, dir = getwd(), save = TRUE) {
  if (missing(usernames) || !length(usernames)) stop("Necesito al menos un nombre de usuarix.")
  # Una sola sesion de navegador para TODOS los perfiles (batch).
  grupos <- .pw_harvest_batch(paste0("https://x.com/", usernames), "UserByScreenName", max_scrolls = 2)
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
#' @param save Logico. Si TRUE (por defecto) guarda el resultado en un RDS.
#'
#' @return Un tibble con una fila por usuarix (mismas columnas que getUsersDataAPI).
#' @export
#'
#' @examples
#' \dontrun{
#' importSessionX(auth_token = "...", ct0 = "...")
#' getUserFollowersAPI("rstatstweet", n_users = 200)
#' }
getUserFollowersAPI <- function(username, n_users = 100, dir = getwd(), save = TRUE) {
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
#' @param save Logico. Si TRUE (por defecto) guarda el resultado en un RDS.
#'
#' @return Un tibble con una fila por usuarix (mismas columnas que getUsersDataAPI).
#' @export
#'
#' @examples
#' \dontrun{
#' importSessionX(auth_token = "...", ct0 = "...")
#' getUserFollowingAPI("rstatstweet", n_users = 200)
#' }
getUserFollowingAPI <- function(username, n_users = 100, dir = getwd(), save = TRUE) {
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
#' @param save Logico. Si TRUE (por defecto) guarda el resultado en un RDS.
#'
#' @return Un tibble con una fila por usuarix (mismas columnas que getUsersDataAPI).
#' @export
#'
#' @examples
#' \dontrun{
#' importSessionX(auth_token = "...", ct0 = "...")
#' getTweetsRetweetsAPI("https://x.com/NASA/status/123", n_users = 100)
#' }
getTweetsRetweetsAPI <- function(url, n_users = 100, dir = getwd(), save = TRUE) {
  if (missing(url) || !nzchar(url)) stop("Necesito la URL de un tweet.")
  cat("Recolectando usuarixs que repostearon: ", url, "\n", sep = "")
  prefix <- paste0("api_rt_", gsub("https://x.com/(.*)/status/(.*)", "\\1_\\2", url))
  .collect_users(paste0(url, "/retweets"), "Retweeters", n_users, dir, save, prefix)
}
