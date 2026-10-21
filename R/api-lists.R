# Listas de X via API GraphQL/JSON (experimental) ---------------------------
#
# La pagina de una lista dispara ListLatestTweetsTimeline (sus tweets) y la de
# miembros dispara ListMembers; se cosechan con el mismo esquema ride-along que
# el resto de la familia *API.

#' Normaliza una lista: acepta el id numerico o la URL https://x.com/i/lists/<id>
#' @noRd
.x_list_id <- function(x) {
  id <- sub("^.*/lists/([0-9]+).*$", "\\1", trimws(as.character(x)))
  if (!grepl("^[0-9]+$", id)) stop("No reconozco el id de lista: ", x)
  id
}

#' Get the Tweets of an X List via the X API (experimental)
#'
#' @description
#'
#' <a href="https://lifecycle.r-lib.org/articles/stages.html#experimental" target="_blank"><img src="https://lifecycle.r-lib.org/articles/figures/lifecycle-experimental.svg" alt="[Experimental]"></a>
#'
#' Recupera los tweets mas recientes de una Lista de X consultando la **API
#' GraphQL interna de X** (ListLatestTweetsTimeline). Requiere una sesion
#' importada con [importSessionX()].
#'
#' @param list_id Id numerico de la lista o su URL
#'   (`https://x.com/i/lists/<id>`).
#' @param n_tweets Numero maximo de tweets a recuperar. Por defecto 40.
#' @param dir Directorio de destino del RDS. Por defecto el de trabajo.
#' @param save Logico. Si TRUE guarda el resultado en un RDS dentro de `dir`.
#'   Por defecto FALSE: no se escribe ningun archivo.
#'
#' @return Un tibble con un tweet por fila (mismas columnas que
#'   [getUserTweetsAPI()]).
#' @export
#'
#' @examples
#' \dontrun{
#' importSessionX(auth_token = "...", ct0 = "...")
#' getListTweetsAPI("https://x.com/i/lists/53645372", n_tweets = 100)
#' }
getListTweetsAPI <- function(list_id, n_tweets = 40, dir = getwd(), save = FALSE) {
  id <- .x_list_id(list_id)
  cat("Recolectando tweets de la lista ", id, "...\n", sep = "")
  docs <- .pw_harvest(paste0("https://x.com/i/lists/", id), "ListLatestTweetsTimeline",
                      max_scrolls = .scrolls_for(n_tweets), n = n_tweets)
  rows <- list()
  for (d in docs) {
    p <- .parse_timeline_tweets(d)
    if (!is.null(p$tweets)) rows[[length(rows) + 1L]] <- p$tweets
  }
  tweets <- if (length(rows)) {
    dplyr::distinct(dplyr::bind_rows(rows), tweet_id, .keep_all = TRUE)
  } else {
    tibble::tibble()
  }
  if (nrow(tweets) > n_tweets) tweets <- utils::head(tweets, n_tweets)
  cat("Tweets \u00fanicos recolectados:", nrow(tweets), "\n")
  .save_rds(tweets, dir, paste0("api_list_", id), save = save)
  tweets
}

#' Get the Members of an X List via the X API (experimental)
#'
#' @description
#'
#' <a href="https://lifecycle.r-lib.org/articles/stages.html#experimental" target="_blank"><img src="https://lifecycle.r-lib.org/articles/figures/lifecycle-experimental.svg" alt="[Experimental]"></a>
#'
#' Recupera las cuentas que integran una Lista de X consultando la **API
#' GraphQL interna de X** (ListMembers). Requiere una sesion importada con
#' [importSessionX()].
#'
#' @param list_id Id numerico de la lista o su URL
#'   (`https://x.com/i/lists/<id>`).
#' @param n_users Numero maximo de usuarixs a recuperar. Por defecto 100.
#' @param dir Directorio de destino del RDS. Por defecto el de trabajo.
#' @param save Logico. Si TRUE guarda el resultado en un RDS dentro de `dir`.
#'   Por defecto FALSE: no se escribe ningun archivo.
#'
#' @return Un tibble con una fila por usuarix (mismas columnas que
#'   [getUsersDataAPI()]).
#' @export
#'
#' @examples
#' \dontrun{
#' importSessionX(auth_token = "...", ct0 = "...")
#' getListMembersAPI("53645372")
#' }
getListMembersAPI <- function(list_id, n_users = 100, dir = getwd(), save = FALSE) {
  id <- .x_list_id(list_id)
  cat("Recolectando miembros de la lista ", id, "...\n", sep = "")
  .collect_users(paste0("https://x.com/i/lists/", id, "/members"), "ListMembers",
                 n_users, dir, save, paste0("api_list_members_", id))
}
