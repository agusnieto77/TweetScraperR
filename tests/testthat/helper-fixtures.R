# Helpers compartidos por los tests ---------------------------------------

# Lee un fixture HTML de tests/testthat/fixtures/ como un unico string
read_fixture <- function(name) {
  path <- testthat::test_path("fixtures", name)
  paste(readLines(path, encoding = "UTF-8", warn = FALSE), collapse = "\n")
}

# data.frame sintetico con la forma que devuelve getTweetsImagesAnalysis
make_img_results <- function() {
  tibble::tibble(
    clasificacion             = c("Meme", "Fotografia", "Captura", "Ilustracion"),
    descripcion               = paste("Descripcion de la imagen", 1:4),
    palabras_clave            = paste("clave", 1:4),
    contiene_texto            = c(TRUE, FALSE, NA, TRUE),
    texto_contenido           = c("texto en imagen", NA, NA, "otro texto"),
    contenido_discriminatorio = c(FALSE, TRUE, NA, FALSE),
    contenido_violento        = c(FALSE, FALSE, NA, TRUE),
    contenido_pornografico    = c(FALSE, FALSE, NA, FALSE),
    contenido_inapropiado     = c(TRUE, FALSE, NA, FALSE),
    img                       = paste0("imagen_", 1:4, ".jpg")
  )
}
