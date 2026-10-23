# Crawler de conversaciones -------------------------------------------------

test_that("el instante del snowflake coincide con la fecha real del tweet", {
  # https://x.com/agustinromm/status/2113035042599616557, publicado 2026-10-21 22:29:47 UTC
  expect_equal(format(TweetScraperR:::.snowflake_time("2113035042599616557"), "%Y-%m-%d %H:%M:%S"),
               "2026-10-21 22:29:47")
})

# IDs reales de conversacion (snowflakes del 2026-10-21) y un buscador que
# responde `conversation_id:<id>` con el arbol de esa conversacion.
conv_ids <- c(a = "2113035042599616557", b = "2113054350658650314", c = "2113065507804881040")
arbol <- function(id, n = 5) {
  inicio <- TweetScraperR:::.snowflake_time(id)
  tibble::tibble(tweet_id = c(id, paste0(id, seq_len(n))), conversation_id = id,
                 fecha = inicio + c(0, seq_len(n) * 60))
}

local_fake_threads <- function(on_call = NULL, env = parent.frame()) {
  calls <- character(0)
  testthat::local_mocked_bindings(
    .hist_now = function() as.POSIXct("2026-10-22 10:00:00", tz = "UTC"),
    .search_canary = function() TRUE,
    getTweetsSearchAPI = function(search, ...) {
      calls <<- c(calls, search)
      id <- sub("^conversation_id:(\\d+) .*", "\\1", search)
      if (!is.null(on_call)) on_call(length(calls), id)
      arbol(id)
    },
    .env = env
  )
  function() calls
}

quiet <- function(expr) suppressMessages(utils::capture.output(expr))

test_that("cada conversacion con respuestas se pide una vez y los retweets siguen al original", {
  entrada <- tibble::tibble(
    tweet_id        = c(conv_ids[["a"]], "x1", "200", "400"),
    conversation_id = c(conv_ids[["a"]], conv_ids[["a"]], "200", "400"),
    respuestas      = c(5L, 0L, 0L, 0L),
    respuesta_a_id  = c(NA, conv_ids[["a"]], NA, NA),
    es_retweet      = c(FALSE, FALSE, FALSE, TRUE),
    retweet_id      = c(NA, NA, NA, conv_ids[["b"]])
  )
  calls <- local_fake_threads()

  quiet(out <- getTweetsThreadsAPI(entrada))

  # 200 es una raiz sin respuestas; 400 es un retweet: se sigue el original b.
  pedidas <- unique(sub("^conversation_id:(\\d+) .*", "\\1", calls()))
  expect_setequal(pedidas, conv_ids[c("a", "b")])
  expect_setequal(out$tweet_id, c(arbol(conv_ids[["a"]])$tweet_id, arbol(conv_ids[["b"]])$tweet_id))
  # Cada conversacion se pide desde su propio inicio (snowflake - 60 s).
  desde <- as.numeric(sub(".*since_time:(\\d+).*", "\\1", calls()[grepl(conv_ids[["a"]], calls())][1]))
  expect_equal(desde, floor(as.numeric(TweetScraperR:::.snowflake_time(conv_ids[["a"]]))) - 60)
})

test_that("una conversacion cortada guarda lo recibido, queda pendiente y se completa al reanudar", {
  db <- withr::local_tempfile(fileext = ".sqlite")
  cortar <- TRUE
  local_fake_threads(on_call = function(n, id) {
    if (cortar && id == conv_ids[["b"]]) {
      signalCondition(structure(list(message = "", call = NULL), class = c("interrupt", "condition")))
    }
  })

  quiet(parcial <- getTweetsThreadsAPI(unname(conv_ids), db = db))
  con <- TweetScraperR:::.store_open(db)
  pend <- sub("^conv\\|", "", TweetScraperR:::.store_plan_pending(con, "conv|")$task_key)
  DBI::dbDisconnect(con)
  # El orden de la cola es de la mas reciente a la mas vieja: c, b (cortada), a.
  expect_true(conv_ids[["b"]] %in% pend)
  expect_false(conv_ids[["c"]] %in% pend)
  expect_true(all(arbol(conv_ids[["c"]])$tweet_id %in% parcial$tweet_id))

  cortar <- FALSE
  quiet(out <- getTweetsThreadsAPI(db = db))
  esperados <- unlist(lapply(conv_ids, function(id) arbol(id)$tweet_id))
  expect_setequal(out$tweet_id, esperados)

  expect_error(quiet(getTweetsThreadsAPI(c(conv_ids[["a"]], "999"), db = db)), "no coinciden")
})

test_that("una conversacion con consultas fallidas queda pendiente", {
  db <- withr::local_tempfile(fileext = ".sqlite")
  local_fake_threads(on_call = function(n, id) if (id == conv_ids[["a"]]) stop("HTTP 500"))

  msgs <- testthat::capture_messages(utils::capture.output(
    getTweetsThreadsAPI(unname(conv_ids[c("a", "c")]), db = db)
  ))

  expect_true(any(grepl(paste0("incompletas: ", conv_ids[["a"]]), msgs)))
  expect_true(any(grepl("Reanuda con getTweetsThreadsAPI", msgs)))
})

test_that("con una sola conversacion se muestra el avance por ventana; con varias, no", {
  local_fake_threads()
  una <- utils::capture.output(suppressMessages(getTweetsThreadsAPI(conv_ids[["a"]])))
  varias <- utils::capture.output(suppressMessages(getTweetsThreadsAPI(unname(conv_ids))))

  expect_true(any(grepl(" -> .*tweets, .*nuevos", una)))
  expect_false(any(grepl(" -> ", varias)))
  expect_true(any(grepl("^3/3 \\| conversacion", varias)))
})

test_that("un vector de IDs se acepta tal cual y uno invalido se rechaza", {
  expect_equal(TweetScraperR:::.thread_conversations(c("1", "1", "2")), c("1", "2"))
  expect_error(TweetScraperR:::.thread_conversations("https://x.com/a/status/1"), "invalidos")
})
