% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/getUrlsTweetsReplies.R
\name{getUrlsTweetsReplies}
\alias{getUrlsTweetsReplies}
\title{Get Tweets URLs Replies}
\usage{
getUrlsTweetsReplies(
  url = "https://x.com/Picanumeros/status/1610715405705789442",
  n_urls = 100,
  xuser = Sys.getenv("USER"),
  xpass = Sys.getenv("PASS"),
  view = FALSE,
  dir = getwd(),
  save = TRUE
)
}
\arguments{
\item{url}{URL del tweet del cual se quieren obtener las respuestas. Por defecto es "https://x.com/Picanumeros/status/1610715405705789442".}

\item{n_urls}{El número máximo de URLs de respuestas a recuperar. Por defecto es 100.}

\item{xuser}{Nombre de usuario de Twitter para autenticación. Por defecto es el valor de la variable de entorno del sistema USER.}

\item{xpass}{Contraseña de Twitter para autenticación. Por defecto es el valor de la variable de entorno del sistema PASS.}

\item{view}{Ver el navegador. Por defecto es FALSE.}

\item{dir}{Directorio donde se guardará el archivo RDS con las URLs recolectadas. Por defecto es el directorio de trabajo actual.}

\item{save}{Lógico. Indica si se debe guardar el resultado en un archivo RDS (por defecto TRUE).}
}
\value{
Un vector que contiene las URLs de las respuestas al tweet especificado.
}
\description{
\if{html}{\out{<a href="https://lifecycle.r-lib.org/articles/stages.html#experimental" target="_blank">}}\if{html}{\out{<img src="https://lifecycle.r-lib.org/articles/figures/lifecycle-experimental.svg" alt="[Experimental]">}}\if{html}{\out{</a>}}

Esta función recupera las URLs de las respuestas a un tweet específico en Twitter (ahora X).
Utiliza web scraping para acceder a la página del tweet, iniciar sesión con las credenciales proporcionadas,
y recolectar las URLs de las respuestas al tweet.

El proceso incluye:
\enumerate{
\item Iniciar sesión en Twitter usando las credenciales proporcionadas.
\item Navegar a la URL del tweet especificado.
\item Extraer las URLs de las respuestas mediante scraping.
\item Continuar scrolling y recolectando URLs hasta alcanzar el número deseado o no encontrar nuevas URLs.
}

La función guarda las URLs recolectadas en un archivo RDS en el directorio especificado si el parámetro 'save' es TRUE,
y las devuelve como un vector de cadenas.
}
\note{
Esta función utiliza web scraping y puede ser sensible a cambios en la estructura de la página de Twitter.
}
\examples{
\dontrun{
getUrlsTweetsReplies(url = "https://x.com/Picanumeros/status/1610715405705789442", n_urls = 130)

# Sin guardar los resultados
getUrlsTweetsReplies(url = "https://x.com/Picanumeros/status/1610715405705789442", n_urls = 130, save = FALSE)
}

}
\references{
Puedes encontrar más información sobre el paquete TweetScraperR en:
\url{https://github.com/agusnieto77/TweetScraperR}
}
