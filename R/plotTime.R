#' Create Line Graph of Tweets by Time
#'
#' @description
#'
#' <a href="https://lifecycle.r-lib.org/articles/stages.html#experimental" target="_blank"><img src="https://lifecycle.r-lib.org/articles/figures/lifecycle-experimental.svg" alt="[Experimental]"></a>
#'
#' Esta funci\u00f3n toma un dataframe de tweets y crea un gr\u00e1fico de l\u00edneas
#' mostrando la frecuencia de tweets a lo largo del tiempo, con opciones
#' para agrupar por hora, d\u00eda, semana, mes o a\u00f1o.
#'
#' @param df Un dataframe que contiene una columna 'fecha' con las fechas de los tweets.
#' @param group_by Una cadena que indica c\u00f3mo agrupar las fechas.
#'   Opciones v\u00e1lidas son "hour", "day", "week", "month", "year".
#' @param color Color de la l\u00ednea en el gr\u00e1fico (por defecto "blue").
#' @return Un objeto ggplot con el gr\u00e1fico de l\u00edneas.
#'
#' @importFrom ggplot2 ggplot aes geom_line labs theme_minimal theme element_text scale_x_datetime scale_x_date
#' @importFrom lubridate floor_date as_date
#' @importFrom dplyr mutate group_by summarise n
#' @importFrom utils install.packages
#'
#' @export
#'
#' @examples
#'
#' df <- data.frame(fecha = c(
#'   seq(as.POSIXct("2023-01-02 00:00:00"), by = "hour", length.out = 3),
#'   seq(as.POSIXct("2023-01-02 01:00:00"), by = "hour", length.out = 2),
#'   seq(as.POSIXct("2023-01-02 03:00:00"), by = "hour", length.out = 3),
#'   seq(as.POSIXct("2023-01-02 01:00:00"), by = "hour", length.out = 2),
#'   seq(as.POSIXct("2023-01-02 03:00:00"), by = "hour", length.out = 3),
#'   seq(as.POSIXct("2023-01-02 01:00:00"), by = "hour", length.out = 2),
#'   seq(as.POSIXct("2023-01-02 03:00:00"), by = "hour", length.out = 3)
#' ))
#' plotTime(df, group_by = "hour")
#'

plotTime <- function(
    df,
    group_by = "hour",
    color = "blue"
    ) {

  # Lista de paquetes necesarios
  required_packages <- c("ggplot2", "lubridate", "dplyr")

  # Funci\u00f3n para instalar paquetes si no est\u00e1n instalados
  install_if_missing <- function(package) {
    if (!requireNamespace(package, quietly = TRUE)) {
      utils::install.packages(package, dependencies = TRUE)
    }
  }

  # Instalar y cargar paquetes necesarios
  sapply(required_packages, install_if_missing)

  # Verificar que el dataframe tiene una columna 'fecha'
  if (!"fecha" %in% colnames(df)) {
    stop("El dataframe debe contener una columna llamada 'fecha'")
  }

  # Verificar que 'fecha' es de tipo fecha o datetime
  if (!inherits(df$fecha, c("POSIXct", "POSIXlt"))) {
    stop("La columna 'fecha' debe ser de tipo POSIXct/POSIXlt")
  }

  # Verificar que group_by es una opci\u00f3n v\u00e1lida
  valid_groups <- c("hour", "day", "week", "month", "year")
  if (!group_by %in% valid_groups) {
    stop(paste("group_by debe ser uno de:", paste(valid_groups, collapse = ", ")))
  }

  # Funci\u00f3n para redondear fechas seg\u00fan la agrupaci\u00f3n
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
  df_grouped <- df |>
    dplyr::mutate(date_grouped = round_date(fecha, group_by)) |>
    dplyr::group_by(date_grouped) |>
    dplyr::summarise(count = dplyr::n())

  # Crear el gr\u00e1fico
  p <- ggplot2::ggplot(df_grouped, ggplot2::aes(x = date_grouped, y = count)) +
    ggplot2::geom_line(color = color) +
    ggplot2::labs(
      title = paste0("Frecuencia de tweets por '", group_by,"'"),
      x = "Fecha",
      y = "N\u00ba de tweets"
    ) +
    ggplot2::theme_minimal() +
    ggplot2::theme(
      axis.text.x = ggplot2::element_text(angle = 90, hjust = 1, vjust = 0.5)
    )

  # Ajustar el formato del eje x seg\u00fan la agrupaci\u00f3n
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
