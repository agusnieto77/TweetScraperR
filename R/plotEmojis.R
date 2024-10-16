#' Create Bar Chart of Emoticons in Tweets
#'
#' Esta función toma un dataframe de tweets y crea un gráfico de barras
#' mostrando la frecuencia de los emoticones utilizados en los tweets.
#'
#' @param df Un dataframe que contiene una columna 'emoticones' con listas de emoticones.
#' @param top_n Número de emoticones más frecuentes a mostrar (por defecto 10).
#' @param color Color de las barras en el gráfico (por defecto "skyblue").
#' 
#' @return Un objeto ggplot con el gráfico de barras.
#' 
#' @import ggplot2
#' @import dplyr
#' @import tidyr
#' 
#' @export
#'
#' @examples
#' 
#' df <- data.frame(emoticones = I(list(c("😊", "😂"), c("😊"), c("😂", "😍"), character(0))))
#' plot_emojis(df)
#' 

plotEmojis <- function(
    df, 
    top_n = 10, 
    color = "skyblue"
) {
  
  # Lista de paquetes necesarios
  required_packages <- c("ggplot2", "tidyr", "dplyr")
  
  # Función para instalar paquetes si no están instalados
  install_if_missing <- function(package) {
    if (!requireNamespace(package, quietly = TRUE)) {
      install.packages(package, dependencies = TRUE)
    }
    library(package, character.only = TRUE)
  }
  
  # Instalar y cargar paquetes necesarios
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
    dplyr::count(emoticones, sort = TRUE) |>
    dplyr::slice_head(n = top_n)
  
  # Crear el gráfico
  p <- ggplot2::ggplot(emoji_counts, ggplot2::aes(x = reorder(emoticones, n), y = n)) +
    ggplot2::geom_col(fill = color) +
    ggplot2::coord_flip() +
    ggplot2::labs(
      title = paste("Top", top_n, "emoticones más usados"),
      x = "Emoticones",
      y = "Frecuencia"
    ) +
    ggplot2::theme_minimal() +
    ggplot2::theme(
      axis.text.y = ggplot2::element_text(size = 20)  # Aumentar el tamaño de los emoticones
    )
  
  return(p)
}
