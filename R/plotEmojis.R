#' Create Bar Chart of Emoticons in Tweets
#'
#' @description
#' 
#' <a href="https://lifecycle.r-lib.org/articles/stages.html#experimental" target="_blank"><img src="https://lifecycle.r-lib.org/articles/figures/lifecycle-experimental.svg" alt="[Experimental]"></a>
#' 
#' Esta función toma un dataframe de tweets y crea un gráfico de barras
#' mostrando la frecuencia de los emoticones utilizados en los tweets.
#'
#' @param df Un dataframe que contiene una columna 'emoticones' con listas de emoticones.
#' @param top_n Número de emoticones más frecuentes a mostrar (por defecto 10).
#' @param fill Color de las barras en el gráfico (por defecto "skyblue").
#' @param color Color de los bordes de las barras en el gráfico (por defecto "grey30").
#' 
#' @return Un objeto ggplot con el gráfico de barras.
#' 
#' @importFrom ggplot2 ggplot aes geom_col coord_flip labs theme_minimal theme element_text
#' @importFrom tidyr unnest
#' @importFrom dplyr filter count slice_head
#' @importFrom stats reorder
#'
#' @export
#'
#' @examples
#' \dontrun{
#' df <- data.frame(emoticones = I(list(
#'   c("\U0001F60A", "\U0001F602", "\U0001F602"),
#'   c("\U0001F60A"),
#'   c("\U0001F602", "\U0001F60D"),
#'   character(0)
#' )))
#' plotEmojis(df)
#' }
#' 

plotEmojis <- function(
    df, 
    top_n = 10, 
    fill = "skyblue",
    color = "grey30"
) {

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
  p <- ggplot2::ggplot(emoji_counts, ggplot2::aes(x = stats::reorder(emoticones, n), y = n)) +
    ggplot2::geom_col(fill = fill, color = color) +
    ggplot2::coord_flip() +
    ggplot2::labs(
      title = paste("Top", top_n, "emoticones m\u00e1s usados"),
      x = "Emoticones",
      y = "Frecuencia"
    ) +
    ggplot2::theme_minimal() +
    ggplot2::theme(
      axis.text.y = ggplot2::element_text(size = 20)
    )
  
  return(p)
}
