#' Get Tweets Data II
#'
#' @description
#'
#' <a href="https://lifecycle.r-lib.org/articles/stages.html#experimental" target="_blank"><img src="https://lifecycle.r-lib.org/articles/figures/lifecycle-experimental.svg" alt="[Experimental]"></a>
#'
#' @description
#' **Obsoleta**: preféri getTweetsDataAPI(), basada en la API de X (datos del JSON, mas robusta).
#'
#' Esta función permite recuperar y procesar datos de tweets a partir de un vector de URLs
#' de tweets proporcionadas. Los datos extraídos incluyen la fecha del tweet,
#' el nombre de usuarix que lo publicó, el texto del tweet,
#' las respuestas, reposts, me gusta, URLs asociadas, y otra información relevante.
#' A diferencia de getTweetsData(), esta función no realiza el proceso de
#' autenticación en Twitter: asume que ya existe una sesión autenticada en el navegador.
#' La función también maneja tweets borrados y errores durante el proceso de recolección, y
#' clasifica las URLs de los tweets en tres categorías: tweets recuperados, tweets borrados, y
#' tweets que necesitan ser reprocesados. Si el parámetro 'save' es TRUE, los datos recopilados
#' se guardan en un archivo RDS en el directorio especificado por le usuarix.
#'
#' @param urls_tweets Vector de URLs de tweets de los cuales se desea obtener datos.
#' @param dir directorio para guardar el RDS con las URLs recolectadas
#' @param save Logical. Indica si se debe guardar el resultado en un archivo RDS. Por defecto es TRUE.
#' @return Un tibble que contiene los datos de los tweets recuperados.
#'
#' @details
#' Cuando save = TRUE, se guarda un archivo RDS con una lista que contiene:
#'
#' \itemize{
#'   \item \code{tweets_recuperados}: Un tibble con los datos de los tweets recuperados, incluyendo la fecha, nombre de usuario, texto, respuestas, reposts, me gusta, URLs asociadas y otras informaciones recopiladas.
#'   \item \code{tweets_borrados}: Un vector con las URLs de los tweets que fueron detectados como borrados.
#'   \item \code{tweets_a_reprocesar}: Un vector con las URLs de los tweets que no pudieron ser procesados exitosamente y necesitan ser reprocesados.
#'   \item \code{errores}: Un vector con los mensajes de error recopilados durante el proceso de recolección de datos.
#' }
#'
#' @export
#'
#' @examples
#' \dontrun{
#' getTweetsData2(urls_tweets = "https://twitter.com/estacion_erre/status/1788929978811232537")
#' getTweetsData2(
#'   urls_tweets = "https://twitter.com/estacion_erre/status/1788929978811232537",
#'   save = FALSE
#' )
#' }
#'
#' @importFrom rvest read_html_live html_elements html_element html_attr html_text
#' @importFrom lubridate as_datetime is.POSIXct
#' @importFrom tibble tibble
#' @importFrom stringr str_extract_all
#'

getTweetsData2 <- function(
    urls_tweets,
    dir = getwd(),
    save = TRUE
) {
  .Deprecated(msg = "getTweetsData2() est\u00e1 obsoleta: us\u00e1 getTweetsDataAPI() (basada en la API de X, datos estructurados del JSON, m\u00e1s robusta). Ver ?getTweetsDataAPI.")
  .collect_tweets_data(urls_tweets, dir = dir, save = save, msg_borrado = "\nEl tweet")
}
