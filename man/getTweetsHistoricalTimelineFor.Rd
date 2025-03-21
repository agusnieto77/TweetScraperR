% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/getTweetsHistoricalTimelineFor.R
\name{getTweetsHistoricalTimelineFor}
\alias{getTweetsHistoricalTimelineFor}
\title{Get Historical Tweets from User Timeline Iteratively}
\usage{
getTweetsHistoricalTimelineFor(
  iterations,
  username,
  n_tweets,
  since,
  until,
  interval_unit = "days",
  xuser = Sys.getenv("USER"),
  xpass = Sys.getenv("PASS"),
  dir = getwd(),
  system = "windows",
  kill_system = FALSE,
  sleep_time = 5 * 60
)
}
\arguments{
\item{iterations}{Número de iteraciones a realizar.}

\item{username}{Nombre de usuario de Twitter del cual se recolectarán los tweets.}

\item{n_tweets}{Número de tweets a recolectar por iteración.}

\item{since}{Fecha y hora de inicio para la búsqueda (formato: "YYYY-MM-DD_HH:MM:SS_UTC").}

\item{until}{Número de unidades de tiempo a avanzar en cada iteración.}

\item{interval_unit}{Unidad de tiempo para el intervalo ("days", "hours", o "minutes").}

\item{xuser}{Nombre de usuario de Twitter para autenticación (por defecto: variable de entorno del sistema "USER").}

\item{xpass}{Contraseña de Twitter para autenticación (por defecto: variable de entorno del sistema "PASS").}

\item{dir}{Directorio para guardar los tweets recolectados (por defecto: directorio de trabajo actual).}

\item{system}{Sistema operativo ("windows", "unix", o "mac").}

\item{kill_system}{Booleano que indica si se debe cerrar el navegador después de cada iteración (por defecto: FALSE).}

\item{sleep_time}{Tiempo de espera entre iteraciones en segundos (por defecto: 300 segundos).}
}
\value{
No devuelve un valor explícito, pero guarda los tweets recolectados en el directorio especificado.
}
\description{
\if{html}{\out{<a href="https://lifecycle.r-lib.org/articles/stages.html#experimental" target="_blank">}}\if{html}{\out{<img src="https://lifecycle.r-lib.org/articles/figures/lifecycle-experimental.svg" alt="[Experimental]">}}\if{html}{\out{</a>}}

Esta función realiza búsquedas históricas de tweets de la línea de tiempo de un usuario de forma iterativa,
permitiendo recolectar tweets en intervalos de tiempo específicos (días, horas o minutos).
}
\details{
La función realiza las siguientes operaciones:
\enumerate{
\item Valida el formato de la fecha y hora de inicio.
\item Crea el directorio de destino si no existe.
\item Ejecuta búsquedas históricas de tweets de la línea de tiempo del usuario de forma iterativa.
\item Calcula la fecha y hora de finalización para cada iteración basándose en el intervalo especificado.
\item Cierra el navegador después de cada iteración si kill_system es TRUE.
\item Espera un tiempo especificado entre iteraciones.
}
}
\examples{
\dontrun{
# Usando intervalos de días
getTweetsHistoricalTimelineFor(
  iterations = 5,
  username = "rstatstweet",
  n_tweets = 10,
  since = "2018-07-01_00:00:00_UTC",
  until = 60,
  interval_unit = "days",
  dir = "./datos/tweets",
  system = "windows",
  kill_system = FALSE,
  sleep_time = 10
)

# Usando intervalos de horas
getTweetsHistoricalTimelineFor(
  iterations = 12,
  username = "rstatstweet",
  n_tweets = 10,
  since = "2018-07-01_00:00:00_UTC",
  until = 2,
  interval_unit = "hours",
  dir = "./datos/tweets",
  system = "windows",
  kill_system = FALSE,
  sleep_time = 10
)
}

}
