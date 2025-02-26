#' Create Bar Chart of EmoticonsPNG in Tweets
#' 
#' @description
#' 
#' <a href="https://lifecycle.r-lib.org/articles/stages.html#experimental" target="_blank"><img src="https://lifecycle.r-lib.org/articles/figures/lifecycle-experimental.svg" alt="[Experimental]"></a>
#' 
#' Esta función toma un dataframe de tweets y crea un gráfico de barras
#' mostrando la frecuencia de los emoticones en colores utilizados en los tweets.
#'
#' @param df Un dataframe que contiene una columna 'emoticones' con listas de emoticones.
#' @param top_n Número de emoticones más frecuentes a mostrar (por defecto 10).
#' @param fill Color de las barras en el gráfico (por defecto "skyblue").
#' @param color Color de los bordes de las barras en el gráfico (por defecto "grey30").
#' 
#' @return Un objeto ggplot con el gráfico de barras.
#' 
#' @importFrom ggplot2 ggplot aes geom_col coord_flip labs theme_minimal theme element_blank
#' @importFrom tidyr unnest
#' @importFrom dplyr filter mutate count slice_head
#' @importFrom stringr str_sub
#' @importFrom purrr map_chr
#' @importFrom ggimage geom_image
#' @importFrom stats reorder
#' @importFrom utils install.packages
#' 
#' @export
#'
#' @examples
#' 
#' df <- data.frame(emoticones = I(list(c("😊", "😂", "😂"), c("😊"), c("😂", "😍"), character(0))))
#' plotEmojisPNG(df)
#' 

plotEmojisPNG <- function(
    df, 
    top_n = 10, 
    fill = "skyblue",
    color = "grey30"
) {
  
  # Lista de paquetes necesarios
  required_packages <- c("ggplot2", "tidyr", "dplyr", "stringr", "purrr", "ggimage")
  
  # Función para instalar paquetes si no están instalados
  install_if_missing <- function(package) {
    if (!requireNamespace(package, quietly = TRUE)) {
      utils::install.packages(package, dependencies = TRUE)
    }
  }
  
  # Instalar paquetes necesarios
  sapply(required_packages, install_if_missing)
  
  # Verificar que el dataframe tiene una columna 'emoticones'
  if (!"emoticones" %in% colnames(df)) {
    stop("El dataframe debe contener una columna llamada 'emoticones'")
  }
  
  # Verificar que 'emoticones' es una columna de listas
  if (!is.list(df$emoticones)) {
    stop("La columna 'emoticones' debe ser una columna de listas")
  }
  
  # Desanidar la columna de emoticones y contar frecuencias
  emoji_counts <- df |>
    tidyr::unnest(emoticones) |>
    dplyr::filter(emoticones != "") |>
    dplyr::mutate(emoji = stringr::str_sub(emoticones, end = 1)) |>
    dplyr::count(emoji, sort = TRUE) |>
    dplyr::slice_head(n = top_n) |>
    dplyr::mutate(
      emoji_url = purrr::map_chr(emoji, 
                                 ~paste0("https://abs.twimg.com/emoji/v2/72x72/", 
                                         as.hexmode(utf8ToInt(.x)),".png"))
    )
  
  # Crear el gráfico
  p <- ggplot2::ggplot(emoji_counts, ggplot2::aes(x = stats::reorder(emoji, n), y = n)) +
    ggplot2::geom_col(fill = fill, color = color, width = 0.2) +
    ggimage::geom_image(ggplot2::aes(image = emoji_url), size = 0.04) +
    ggplot2::coord_flip() +
    ggplot2::labs(
      title = paste("Top", top_n, "emoticones más usados"),
      x = "Emoticones",
      y = "Frecuencia"
    ) +
    ggplot2::theme_minimal() +
    ggplot2::theme(
      axis.text.y = ggplot2::element_blank()
    )
  
  return(p)
}
