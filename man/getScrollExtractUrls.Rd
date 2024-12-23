% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/getScrollExtractUrls.R
\name{getScrollExtractUrls}
\alias{getScrollExtractUrls}
\title{Extraer las urls de los tweets de una línea de tiempo de Twitter mediante desplazamiento}
\usage{
getScrollExtractUrls(
  objeto = timeline,
  username = "rstatstweet",
  n_tweets = 100,
  dir = getwd(),
  save = TRUE
)
}
\arguments{
\item{objeto}{Un objeto de sesión de navegador web, por defecto 'timeline'.}

\item{username}{Character. El nombre de usuario de Twitter cuya línea de tiempo se está extrayendo.}

\item{n_tweets}{Numeric. El número máximo de tweets a extraer. Por defecto es 100.}

\item{dir}{Character. El directorio donde se guardará el archivo RDS con los tweets extraídos.
Por defecto es el directorio de trabajo actual.}

\item{save}{Logical. Indica si se debe guardar el resultado en un archivo RDS. Por defecto es TRUE.}
}
\value{
Un vector con las urls extraídas
}
\description{
\if{html}{\out{<a href="https://lifecycle.r-lib.org/articles/stages.html#experimental" target="_blank">}}\if{html}{\out{<img src="https://lifecycle.r-lib.org/articles/figures/lifecycle-experimental.svg" alt="[Experimental]">}}\if{html}{\out{</a>}}

Esta función extrae las urls de los tweets de una línea de tiempo de Twitter previamente abierta,
desplazándose por la página para recopilar la información deseada.
}
\details{
La función realiza las siguientes acciones:
\enumerate{
\item Inicia la extracción de tweets de la línea de tiempo.
\item Desplaza la página hacia abajo para cargar más tweets.
\item Extrae las urls de los tweets visibles.
\item Continúa el proceso hasta alcanzar el número deseado de urls o hasta que no se carguen más tweets nuevos.
\item Si save es TRUE, guarda las urls extraídas en un archivo RDS en el directorio especificado.
}

La función utiliza selectores CSS específicos para extraer la url de los tweets.
Si la extracción se detiene antes de alcanzar el número deseado de tweets, puede ser debido a
limitaciones en la carga de tweets por parte de Twitter o problemas de conexión.
}
\note{
Esta función asume que ya se ha abierto una sesión de navegador con la línea de tiempo de Twitter
utilizando la función \code{openTimeline()} u otra función similar.
}
\examples{
\dontrun{
# Primero, abrir una línea de tiempo
openTimeline("rstatstweet")

# Luego, extraer tweets y guardar el resultado
urls_extraidas <- getScrollExtractUrls(timeline, "rstatstweet", n_tweets = 200, save = TRUE)

# Extraer tweets sin guardar el resultado
urls_extraidas <- getScrollExtractUrls(timeline, "rstatstweet", n_tweets = 200, save = FALSE)

# Cerrar la línea de tiempo después de la extracción
closeTimeline()
}

}
\seealso{
\code{\link{openTimeline}} para abrir una línea de tiempo de Twitter.
\code{\link{closeTimeline}} para cerrar la sesión del navegador después de la extracción.
}
