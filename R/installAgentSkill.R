# Skill conversacional para agentes de IA ----------------------------------
#
# La skill vive en inst/skills/tweetscraperr (SKILL.md + references/) y sigue
# la especificacion Agent Skills (https://agentskills.io). Esta funcion solo
# la copia a la carpeta donde cada agente la descubre.

#' Subcarpetas de skills por agente (relativas al home o al proyecto)
#' @noRd
.skill_dirs <- c(
  posit  = ".posit/assistant/skills",
  agents = ".agents/skills",
  claude = ".claude/skills"
)

#' Home del usuario tal como lo resuelven los agentes
#' @noRd
#' @description En Windows R define `~` como la carpeta Documentos, pero Posit
#'   Assistant, Claude Code y el resto de los agentes buscan sus skills en
#'   `%USERPROFILE%`. Usar `path.expand("~")` instalaria la skill donde ningun
#'   agente la encuentra.
.skill_home <- function() {
  home <- if (.Platform$OS.type == "windows") Sys.getenv("USERPROFILE") else ""
  if (!nzchar(home)) home <- path.expand("~")
  normalizePath(home, winslash = "/", mustWork = FALSE)
}

#' Install the TweetScraperR Skill for AI Agents
#'
#' @description
#'
#' <a href="https://lifecycle.r-lib.org/articles/stages.html#experimental" target="_blank"><img src="https://lifecycle.r-lib.org/articles/figures/lifecycle-experimental.svg" alt="[Experimental]"></a>
#'
#' Instala una *skill* (formato [Agent Skills](https://agentskills.io)) que
#' le enseña a un agente de IA a usar TweetScraperR de forma conversacional:
#' puesta a punto del motor y la sesión, qué función corresponde a cada pedido,
#' columnas devueltas, recetas de análisis y solución de errores frecuentes.
#'
#' Pensada en particular para **Posit Assistant** (el agente nativo de RStudio
#' y Positron), que la carga automáticamente cuando el pedido trata de X/Twitter
#' y también la expone como el comando `/tweetscraperr`. Sirve para cualquier
#' cliente compatible con Agent Skills.
#'
#' @param agent Agente(s) destino. Uno o más de:
#'   \itemize{
#'     \item `"posit"` (por defecto): Posit Assistant,
#'       `.posit/assistant/skills/`.
#'     \item `"agents"`: ubicación genérica del estándar Agent Skills,
#'       `.agents/skills/` (también la lee Posit Assistant, Codex y otros).
#'     \item `"claude"`: Claude Code, `.claude/skills/`.
#'   }
#' @param scope `"user"` (por defecto) instala en tu carpeta personal, disponible
#'   en todos los proyectos. `"project"` instala en el directorio de trabajo
#'   actual (raíz del proyecto), solo para ese proyecto.
#' @param path Carpeta de skills personalizada. Si se indica, ignora `agent` y
#'   `scope` y crea `path/tweetscraperr/`.
#' @param overwrite Lógico. Si `TRUE` reemplaza una instalación previa de la
#'   skill (útil tras actualizar el paquete). Por defecto `FALSE`.
#'
#' @return Invisiblemente, las rutas de las carpetas de la skill instaladas.
#'
#' @details
#' En Windows la carpeta personal es `%USERPROFILE%` (no la carpeta Documentos
#' que R usa como `~`), que es donde los agentes buscan sus skills. Las versiones
#' antiguas de Posit Assistant usaban `~/.positai/skills/`: si tenés una de esas
#' versiones, usá `path = "~/.positai/skills"` o actualizá el asistente.
#'
#' La skill queda disponible en la siguiente conversación del agente.
#'
#' @export
#'
#' @examples
#' \dontrun{
#' # Posit Assistant, para todos los proyectos
#' installAgentSkill()
#'
#' # Posit Assistant y Claude Code, solo en el proyecto actual
#' installAgentSkill(c("posit", "claude"), scope = "project")
#'
#' # Actualizar la skill tras reinstalar el paquete
#' installAgentSkill(overwrite = TRUE)
#' }
installAgentSkill <- function(agent = "posit", scope = c("user", "project"),
                              path = NULL, overwrite = FALSE) {
  src <- system.file("skills", "tweetscraperr", package = "TweetScraperR")
  if (!nzchar(src) || !file.exists(file.path(src, "SKILL.md"))) {
    stop("No se encontr\u00f3 la skill (inst/skills/tweetscraperr) en el paquete instalado.")
  }
  if (is.null(path)) {
    agent <- match.arg(agent, names(.skill_dirs), several.ok = TRUE)
    scope <- match.arg(scope)
    base <- if (scope == "user") .skill_home() else getwd()
    roots <- file.path(base, .skill_dirs[agent])
  } else {
    roots <- path.expand(path)
  }
  dests <- file.path(roots, "tweetscraperr")
  existing <- dests[dir.exists(dests)]
  if (length(existing) && !overwrite) {
    stop("La skill ya est\u00e1 instalada en: ", paste(existing, collapse = ", "),
         ". Us\u00e1 overwrite = TRUE para reemplazarla.")
  }
  for (i in seq_along(dests)) {
    if (dir.exists(dests[i])) unlink(dests[i], recursive = TRUE)
    dir.create(roots[i], recursive = TRUE, showWarnings = FALSE)
    if (!file.copy(src, roots[i], recursive = TRUE)) {
      stop("No se pudo copiar la skill a ", roots[i])
    }
    message("Skill 'tweetscraperr' instalada en: ", dests[i])
  }
  message("Estar\u00e1 disponible en la pr\u00f3xima conversaci\u00f3n del agente.")
  invisible(dests)
}
