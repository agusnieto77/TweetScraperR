#' Create Line Graph of Tweets by Time
#'
#' Esta función toma un dataframe de tweets y crea un gráfico de líneas
#' mostrando la frecuencia de tweets a lo largo del tiempo, con opciones
#' para agrupar por hora, día, semana, mes o año.
#'
#' @param df Un dataframe que contiene una columna 'fecha' con las fechas de los tweets.
#' @param group_by Una cadena que indica cómo agrupar las fechas. 
#'   Opciones válidas son "hour", "day", "week", "month", "year".
#' @param color Color de la línea en el gráfico (por defecto "blue").
#' @return Un objeto ggplot con el gráfico de líneas.
#' 
#' @import ggplot2
#' @import dplyr
#' @import lubridate
#' @export
#'
#' @examples
#' df <- data.frame(fecha = seq(as.POSIXct("2023-01-01"), by = "hour", length.out = 1000))
#' plot_tweets_over_time(df, group_by = "day")
#' 

plotTime <- function(
    df, 
    group_by = "hour", 
    color = "blue"
    ) {
  
  # Lista de paquetes necesarios
  required_packages <- c("ggplot2", "lubridate", "dplyr")
  
  # Función para instalar paquetes si no están instalados
  install_if_missing <- function(package) {
    if (!requireNamespace(package, quietly = TRUE)) {
      install.packages(package, dependencies = TRUE)
    }
    library(package, character.only = TRUE)
  }
  
  # Instalar y cargar paquetes necesarios
  sapply(required_packages, install_if_missing)
  
  # Verificar que el dataframe tiene una columna 'fecha'
  if (!"fecha" %in% colnames(df)) {
    stop("El dataframe debe contener una columna llamada 'fecha'")
  }
  
  # Verificar que 'fecha' es de tipo fecha o datetime
  if (!inherits(df$fecha, c("Date", "POSIXct", "POSIXlt"))) {
    stop("La columna 'fecha' debe ser de tipo Date o POSIXct/POSIXlt")
  }
  
  # Verificar que group_by es una opción válida
  valid_groups <- c("hour", "day", "week", "month", "year")
  if (!group_by %in% valid_groups) {
    stop(paste("group_by debe ser uno de:", paste(valid_groups, collapse = ", ")))
  }
  
  # Función para redondear fechas según la agrupación
  round_date <- function(date, group) {
    switch(group,
           "hour" = lubridate::floor_date(date, "hour"),
           "day" = lubridate::as_date(date),
           "week" = lubridate::floor_date(date, "week"),
           "month" = lubridate::floor_date(date, "month"),
           "year" = lubridate::floor_date(date, "year")
    )
  }
  
  # Agrupar y contar tweets
  df_grouped <- df %>%
    dplyr::mutate(date_grouped = round_date(fecha, group_by)) %>%
    dplyr::group_by(date_grouped) %>%
    dplyr::summarise(count = n())
  
  # Crear el gráfico
  p <- ggplot2::ggplot(df_grouped, ggplot2::aes(x = date_grouped, y = count)) +
    ggplot2::geom_line(color = color) +
    ggplot2::labs(
      title = paste("Frecuencia de tweets por", group_by),
      x = "Fecha",
      y = "Número de tweets"
    ) +
    ggplot2::theme_minimal()
  
  # Ajustar el formato del eje x según la agrupación
  if (group_by == "hour") {
    p <- p + ggplot2::scale_x_datetime(date_labels = "%Y-%m-%d %H:00")
  } else if (group_by %in% c("day", "week")) {
    p <- p + ggplot2::scale_x_date(date_labels = "%Y-%m-%d")
  } else if (group_by == "month") {
    p <- p + ggplot2::scale_x_date(date_labels = "%Y-%m")
  } else if (group_by == "year") {
    p <- p + ggplot2::scale_x_date(date_labels = "%Y")
  }
  
  return(p)
}
