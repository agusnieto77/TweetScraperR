# Get Tweets by Search with Xquik

Consulta el endpoint de busqueda de tweets de Xquik y devuelve una tabla
compatible con los flujos del paquete. Deduplica tweets por id o URL,
respeta el maximo solicitado por `n_tweets` y requiere una clave de API
en `XQUIK_API_KEY` o en el argumento `api_key`.

## Usage

``` r
getTweetsXquikSearch(
  search = "#RStats",
  n_tweets = 100,
  query_type = c("Latest", "Top"),
  api_key = Sys.getenv("XQUIK_API_KEY"),
  base_url = "https://xquik.com",
  timeout = 30
)
```

## Arguments

- search:

  La consulta de busqueda para recuperar tweets. Por defecto es
  "#RStats".

- n_tweets:

  El numero maximo de tweets a recuperar. Por defecto es 100.

- query_type:

  Orden de busqueda. Puede ser "Latest" o "Top".

- api_key:

  Clave de API de Xquik. Por defecto usa la variable de entorno
  `XQUIK_API_KEY`.

- base_url:

  URL base de Xquik. Por defecto es "https://xquik.com".

- timeout:

  Tiempo de espera de la peticion en segundos.

## Value

Un tibble con tweets recuperados desde Xquik.

## Note

Xquik es un servicio comercial externo de terceros: esta funcion envia
la consulta de busqueda y la clave de API configurada a los servidores
de xquik.com.

## References

Puedes encontrar mas informacion sobre Xquik en:
<https://docs.xquik.com>

## Examples

``` r
if (FALSE) { # \dontrun{
getTweetsXquikSearch(search = "#RStats", n_tweets = 50)

getTweetsXquikSearch(
  search = "from:rstats",
  query_type = "Top",
  api_key = Sys.getenv("XQUIK_API_KEY")
)
} # }
```
