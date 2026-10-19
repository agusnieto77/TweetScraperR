# installAgentSkill: despliegue de la skill para agentes -------------------

nuevo_dir_skills <- function() {
  d <- file.path(tempdir(), paste0("skills_test_", as.integer(stats::runif(1, 1, 1e9))))
  dir.create(d)
  d
}

test_that("la skill empaquetada cumple la especificacion Agent Skills", {
  src <- system.file("skills", "tweetscraperr", package = "TweetScraperR")
  lines <- readLines(file.path(src, "SKILL.md"), encoding = "UTF-8", warn = FALSE)
  delim <- which(lines == "---")
  expect_equal(delim[1], 1L)
  front <- lines[2:(delim[2] - 1)]
  campo <- function(key) {
    sub(paste0("^", key, ":\\s*"), "", grep(paste0("^", key, ":"), front, value = TRUE))
  }
  name <- campo("name")
  description <- campo("description")
  # name: minusculas/numeros/guiones, <= 64 y igual al nombre de la carpeta
  expect_match(name, "^[a-z0-9-]{1,64}$")
  expect_equal(name, basename(src))
  expect_true(nchar(description) > 0 && nchar(description) <= 1024)
  # Las referencias citadas en SKILL.md viajan con la skill
  expect_true(file.exists(file.path(src, "references", "functions.md")))
})

test_that("installAgentSkill copia la skill completa en path y devuelve la ruta", {
  d <- nuevo_dir_skills()
  on.exit(unlink(d, recursive = TRUE), add = TRUE)

  res <- withVisible(suppressMessages(installAgentSkill(path = d)))

  expect_false(res$visible)
  expect_equal(res$value, file.path(d, "tweetscraperr"))
  expect_true(file.exists(file.path(d, "tweetscraperr", "SKILL.md")))
  expect_true(file.exists(file.path(d, "tweetscraperr", "references", "functions.md")))
})

test_that("installAgentSkill no pisa una instalacion previa salvo overwrite = TRUE", {
  d <- nuevo_dir_skills()
  on.exit(unlink(d, recursive = TRUE), add = TRUE)
  suppressMessages(installAgentSkill(path = d))
  skill_md <- file.path(d, "tweetscraperr", "SKILL.md")
  viejo <- file.path(d, "tweetscraperr", "obsoleto.md")
  writeLines("version vieja", skill_md)
  writeLines("x", viejo)

  expect_error(installAgentSkill(path = d), "overwrite = TRUE")
  expect_equal(readLines(skill_md), "version vieja")

  suppressMessages(installAgentSkill(path = d, overwrite = TRUE))
  expect_match(readLines(skill_md, n = 2)[2], "^name: tweetscraperr$")
  # Reemplaza la carpeta entera: no quedan archivos de la version anterior
  expect_false(file.exists(viejo))
})

test_that("scope = 'project' instala en el directorio de trabajo de cada agente", {
  d <- nuevo_dir_skills()
  old <- setwd(d)
  on.exit({ setwd(old); unlink(d, recursive = TRUE) }, add = TRUE)

  res <- suppressMessages(installAgentSkill(c("posit", "agents", "claude"), scope = "project"))

  esperado <- file.path(d, c(".posit/assistant/skills", ".agents/skills", ".claude/skills"), "tweetscraperr")
  expect_equal(normalizePath(res, winslash = "/"), normalizePath(esperado, winslash = "/"))
  expect_true(all(file.exists(file.path(esperado, "SKILL.md"))))
})

test_that("installAgentSkill rechaza agentes desconocidos sin escribir nada", {
  d <- nuevo_dir_skills()
  old <- setwd(d)
  on.exit({ setwd(old); unlink(d, recursive = TRUE) }, add = TRUE)

  # El mensaje de match.arg depende del idioma de R: solo se verifica el error
  expect_error(installAgentSkill("cursor", scope = "project"))
  expect_length(list.files(d, all.files = TRUE, no.. = TRUE), 0)
})
