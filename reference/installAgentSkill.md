# Install the TweetScraperR Skill for AI Agents

[![\[Experimental\]](https://lifecycle.r-lib.org/articles/figures/lifecycle-experimental.svg)](https://lifecycle.r-lib.org/articles/stages.html#experimental)

Instala una *skill* (formato [Agent Skills](https://agentskills.io)) que
le enseña a un agente de IA a usar TweetScraperR de forma
conversacional: puesta a punto del motor y la sesión, qué función
corresponde a cada pedido, columnas devueltas, recetas de análisis y
solución de errores frecuentes.

Pensada en particular para **Posit Assistant** (el agente nativo de
RStudio y Positron), que la carga automáticamente cuando el pedido trata
de X/Twitter y también la expone como el comando `/tweetscraperr`. Sirve
para cualquier cliente compatible con Agent Skills.

## Usage

``` r
installAgentSkill(
  agent = "posit",
  scope = c("user", "project"),
  path = NULL,
  overwrite = FALSE
)
```

## Arguments

- agent:

  Agente(s) destino. Uno o más de:

  - `"posit"` (por defecto): Posit Assistant,
    `.posit/assistant/skills/`.

  - `"agents"`: ubicación genérica del estándar Agent Skills,
    `.agents/skills/` (también la lee Posit Assistant, Codex y otros).

  - `"claude"`: Claude Code, `.claude/skills/`.

- scope:

  `"user"` (por defecto) instala en tu carpeta personal, disponible en
  todos los proyectos. `"project"` instala en el directorio de trabajo
  actual (raíz del proyecto), solo para ese proyecto.

- path:

  Carpeta de skills personalizada. Si se indica, ignora `agent` y
  `scope` y crea `path/tweetscraperr/`.

- overwrite:

  Lógico. Si `TRUE` reemplaza una instalación previa de la skill (útil
  tras actualizar el paquete). Por defecto `FALSE`.

## Value

Invisiblemente, las rutas de las carpetas de la skill instaladas.

## Details

En Windows la carpeta personal es `%USERPROFILE%` (no la carpeta
Documentos que R usa como `~`), que es donde los agentes buscan sus
skills. Las versiones antiguas de Posit Assistant usaban
`~/.positai/skills/`: si tenés una de esas versiones, usá
`path = "~/.positai/skills"` o actualizá el asistente.

La skill queda disponible en la siguiente conversación del agente.

## Examples

``` r
if (FALSE) { # \dontrun{
# Posit Assistant, para todos los proyectos
installAgentSkill()

# Posit Assistant y Claude Code, solo en el proyecto actual
installAgentSkill(c("posit", "claude"), scope = "project")

# Actualizar la skill tras reinstalar el paquete
installAgentSkill(overwrite = TRUE)
} # }
```
