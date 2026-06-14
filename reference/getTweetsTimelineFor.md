# Get Tweets from Multiple Users Iteratively

[![\[Experimental\]](https://lifecycle.r-lib.org/articles/figures/lifecycle-experimental.svg)](https://lifecycle.r-lib.org/articles/stages.html#experimental)

**Obsoleta**: preferí getUserTweetsAPI(), basada en la API de X (datos
del JSON, mas robusta).

Esta función recolecta tweets de múltiples usuarios de X (Twitter) de
forma iterativa, permitiendo obtener un conjunto de datos combinado con
tweets de todos los usuarios especificados.

## Usage

``` r
getTweetsTimelineFor(
  usernames,
  n_tweets = 10,
  save = FALSE,
  save_path = NULL,
  file_format = "rds",
  include_user_column = TRUE,
  dir = getwd(),
  system = "windows",
  kill_system = FALSE
)
```

## Arguments

- usernames:

  Vector de caracteres con los nombres de usuario de X (Twitter) para
  recolectar tweets.

- n_tweets:

  Número de tweets a recolectar por usuario (por defecto: 10).

- save:

  Booleano que indica si se deben guardar los resultados en un archivo
  (por defecto: FALSE).

- save_path:

  Ruta del archivo donde guardar los resultados (por defecto: NULL).

- file_format:

  Formato del archivo para guardar los resultados ("rds" o "csv", por
  defecto: "rds").

- include_user_column:

  Booleano que indica si se debe añadir una columna con el nombre de
  usuario (por defecto: TRUE).

- dir:

  Directorio para guardar los tweets recolectados (por defecto:
  directorio de trabajo actual).

- system:

  Sistema operativo ("windows", "unix", o "mac"). Se mantiene por
  compatibilidad; el cierre del navegador ya no depende del sistema
  operativo.

- kill_system:

  Booleano que indica si se debe cerrar el navegador (solo las sesiones
  propias del paquete) después de la recolección (por defecto: FALSE).

## Value

Un dataframe que contiene los tweets de todos los usuarios
especificados.

## Details

La función realiza las siguientes operaciones:

1.  Valida los parámetros de entrada.

2.  Crea el directorio de destino si no existe y es necesario.

3.  Abre la línea de tiempo de X (Twitter).

4.  Itera a través de cada nombre de usuario especificado.

5.  Recolecta los tweets de cada usuario utilizando getTweetsTimeline().

6.  Añade una columna "cuenta" con el nombre de usuario a cada conjunto
    de datos.

7.  Combina todos los resultados en un único dataframe.

8.  Guarda los resultados combinados si se especifica, en formato .rds
    (por defecto) o .csv.

## Examples

``` r
if (FALSE) { # \dontrun{

# Iniciar sesión
openTimeline()

# Recolectar 5 tweets de cada usuario
usuarios <- c("S1RSTAT1C", "gregoriosz", "ori_oberman")
tweets_df <- getTweetsTimelineFor(
  usernames = usuarios, 
  n_tweets = 5
)

# Guardar resultados en formato RDS (por defecto)
tweets_df <- getTweetsTimelineFor(
  usernames = usuarios,
  n_tweets = 10,
  save = TRUE,
  save_path = "tweets_data.rds"
)

# Guardar resultados en formato CSV
tweets_df <- getTweetsTimelineFor(
  usernames = usuarios,
  n_tweets = 10,
  save = TRUE,
  save_path = "tweets_data.csv",
  file_format = "csv"
)
} # }
```
