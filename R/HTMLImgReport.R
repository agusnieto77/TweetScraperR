#' Generate HTML visualization of analyzed images
#' 
#' @description
#' 
#' #' <a href="https://lifecycle.r-lib.org/articles/stages.html#experimental" target="_blank"><img src="https://lifecycle.r-lib.org/articles/figures/lifecycle-experimental.svg" alt="[Experimental]"></a>
#' 
#' Esta función crea una visualización HTML interactiva de imágenes analizadas,
#' mostrando cada imagen junto con su clasificación, descripción, palabras clave
#' y banderas de contenido en un diseño responsivo con un carrusel y miniaturas.
#'
#' @param results Un data frame o tibble que contiene los resultados del análisis de imágenes de la función `getTweetsImagesAnalysis`.
#'   Debe incluir las siguientes columnas:
#'   \itemize{
#'     \item clasificacion: La clasificación de la imagen (character)
#'     \item descripcion: Una descripción detallada de la imagen (character)
#'     \item palabras_clave: Palabras clave que describen la imagen (character)
#'     \item contiene_texto: Indica si la imagen contiene texto (logical)
#'     \item texto_contenido: El texto contenido en la imagen, si lo hay (character)
#'     \item contenido_discriminatorio: Indica si hay contenido discriminatorio (logical)
#'     \item contenido_violento: Indica si hay contenido violento (logical)
#'     \item contenido_pornografico: Indica si hay contenido pornográfico (logical)
#'     \item contenido_inapropiado: Indica si hay contenido inapropiado (logical)
#'     \item img: La ruta o URL de la imagen (character)
#'   }
#'
#' @return Esta función no devuelve ningún valor. Genera un archivo HTML llamado 
#'   "visualizacion_imagenes.html" en el directorio de trabajo actual y muestra 
#'   un mensaje de confirmación.
#'
#' @details
#' La función crea una página HTML responsiva utilizando Bootstrap para el diseño.
#' Cada imagen se presenta en una tarjeta que incluye la imagen, su clasificación,
#' descripción, palabras clave y banderas de contenido potencialmente problemático.
#' El diseño se ajusta automáticamente a diferentes tamaños de pantalla.
#'
#' La visualización incluye:
#' \itemize{
#'   \item Un título centrado que menciona la función getTweetsImagesAnalysis
#'   \item Un carrusel de tarjetas de imágenes
#'   \item Una vista de miniaturas de todas las imágenes
#'   \item Banderas de colores para contenido problemático
#'   \item Estilos CSS personalizados para mejorar la presentación
#' }
#'
#' @examples
#' \dontrun{
#' # Asumiendo que tienes un data frame llamado 'resultados_analisis'
#' HTMLImgReport(resultados_analisis)
#' }
#'
#' @importFrom htmltools tags div img h5 p span strong save_html HTML
#'
#' @export
#' 

HTMLImgReport <- function(results) {
  # Función para crear una tarjeta para cada imagen
  create_image_card <- function(row) {
    htmltools::div(
      class = "col",
      htmltools::div(
        class = "card h-100",
        htmltools::div(
          class = "card-img-container",
          htmltools::img(src = row$img, alt = row$clasificacion, class = "card-img-top")
        ),
        htmltools::div(
          class = "card-body",
          htmltools::div(
            class = "title-section",
            htmltools::h5(class = "card-title", row$clasificacion)
          ),
          htmltools::div(
            class = "description-section",
            htmltools::div(
              class = "description-container",
              htmltools::p(class = "card-text description", row$descripcion)
            )
          ),
          htmltools::div(
            class = "keywords-section",
            htmltools::p(class = "card-text", 
                         htmltools::strong("Palabras clave: "), 
                         htmltools::span(row$palabras_clave)
            )
          ),
          htmltools::div(
            class = "image-text-section",
            htmltools::p(class = "card-text", 
                         htmltools::strong("Texto en la imagen: "), 
                         htmltools::span(if(row$contiene_texto) row$texto_contenido else "No contiene texto")
            )
          )
        ),
        htmltools::div(
          class = "card-footer",
          htmltools::div(
            class = "content-tags",
            if(row$contenido_discriminatorio) htmltools::span(class = "tag discriminatorio", "Discriminatorio"),
            if(row$contenido_violento) htmltools::span(class = "tag violento", "Violento"),
            if(row$contenido_pornografico) htmltools::span(class = "tag pornografico", "Pornográfico"),
            if(row$contenido_inapropiado) htmltools::span(class = "tag inapropiado", "Inapropiado")
          )
        )
      )
    )
  }
  
  # Función para crear una tarjeta para cada imagen (versión miniatura)
  create_thumbnail_card <- function(row) {
    htmltools::div(
      class = "thumbnail-card d-flex",
      htmltools::div(
        class = "thumbnail-img-container",
        htmltools::img(src = row$img, alt = row$clasificacion, class = "thumbnail-img")
      ),
      htmltools::div(
        class = "thumbnail-content",
        htmltools::h5(class = "card-title", row$clasificacion),
        htmltools::div(
          class = "description-container-thumb",
          htmltools::p(class = "card-text description", row$descripcion)
        ),
        htmltools::p(class = "card-text", 
                     htmltools::strong("Palabras clave: "), 
                     htmltools::span(row$palabras_clave)
        ),
        htmltools::p(class = "card-text", 
                     htmltools::strong("Texto en la imagen: "), 
                     htmltools::span(if(row$contiene_texto) row$texto_contenido else "No contiene texto")
        ),
        htmltools::div(
          class = "content-tags-thumb",
          if(row$contenido_discriminatorio) htmltools::span(class = "tag discriminatorio", "Discriminatorio"),
          if(row$contenido_violento) htmltools::span(class = "tag violento", "Violento"),
          if(row$contenido_pornografico) htmltools::span(class = "tag pornografico", "Pornográfico"),
          if(row$contenido_inapropiado) htmltools::span(class = "tag inapropiado", "Inapropiado")
        )
      )
    )
  }
  
  # Función para crear el encabezado
  create_header <- function() {
    htmltools::div(
      class = "header",
      htmltools::div(class = "header-decoration"),
      htmltools::div(
        class = "header-content",
        htmltools::div(
          class = "title-container",
          htmltools::h1(class = "main-title", htmltools::HTML("Análisis de imágenes con <code>getTweetsImagesAnalysis</code>"))
          )
        )
      )
  }
  
  # Función para crear el pie de página
  create_footer <- function() {
    htmltools::div(
      class = "footer",
      htmltools::div(
        class = "footer-content",
        htmltools::div(
          class = "footer-brand-container",
          htmltools::a(
            href = "https://github.com/agusnieto77/TweetScraper", 
            class = "footer-brand",
            htmltools::tags$i(class = "bi bi-github"), 
            "TweetScraperR"
          ),
          htmltools::span(class = "footer-separator", "|"),
          htmltools::a(
            href = "https://laboratoriodehumanidadesdigitales.ar/", 
            class = "footer-brand",
            htmltools::tags$i(class = "bi bi-bar-chart"), 
            "HLab"
          )
        ),
        htmltools::p(
          class = "footer-copyright",
          paste0("© ", format(Sys.Date(), "%Y"), " Todos los derechos reservados")
        )
      )
    )
  }
  
  # Crear el contenido HTML
  content <- htmltools::div(
    class = "page-wrapper",
    create_header(),
    htmltools::div(
      class = "main-content",
      htmltools::div(
        class = "carousel-container",
        htmltools::div(
          id = "carouselImages",
          class = "carousel slide",
          `data-bs-ride` = "carousel",
          htmltools::div(
            class = "carousel-inner",
            lapply(seq(1, nrow(results), 3), function(i) {
              end_idx <- min(i + 2, nrow(results))
              htmltools::div(
                class = paste("carousel-item", if(i == 1) "active" else ""),
                htmltools::div(
                  class = "row g-4",
                  lapply(i:end_idx, function(j) {
                    htmltools::div(
                      class = "col-md-4",
                      create_image_card(results[j,])
                    )
                  })
                )
              )
            })
          )
        ),
        htmltools::tags$button(
          class = "carousel-control carousel-control-prev",
          type = "button",
          `data-bs-target` = "#carouselImages",
          `data-bs-slide` = "prev",
          htmltools::tags$span(class = "carousel-control-prev-icon", `aria-hidden` = "true"),
          htmltools::tags$span(class = "visually-hidden", "Previous")
        ),
        htmltools::tags$button(
          class = "carousel-control carousel-control-next",
          type = "button",
          `data-bs-target` = "#carouselImages",
          `data-bs-slide` = "next",
          htmltools::tags$span(class = "carousel-control-next-icon", `aria-hidden` = "true"),
          htmltools::tags$span(class = "visually-hidden", "Next")
        )
      ),
      # Nueva sección de miniaturas
      htmltools::div(
        class = "thumbnail-container",
        lapply(seq_len(nrow(results)), function(i) {
          create_thumbnail_card(results[i,])
        })
      )
    ),
    create_footer()
  )
  
  # Crear el HTML completo con estilos CSS incluidos
  html_content <- htmltools::tags$html(
    htmltools::tags$head(
      htmltools::tags$meta(charset = "UTF-8"),
      htmltools::tags$meta(name = "viewport", content = "width=device-width, initial-scale=1"),
      htmltools::tags$title("Visualizador de Imágenes"),
      htmltools::tags$link(rel = "icon", type = "image/png", href = "https://tweet-images-analysis.hlab.com.ar/hlab.png"),
      htmltools::tags$meta(property = "og:image", content = "https://tweet-images-analysis.hlab.com.ar/hlab.png"),
      htmltools::tags$link(rel = "stylesheet", href = "https://cdn.jsdelivr.net/npm/bootstrap@5.1.3/dist/css/bootstrap.min.css"),
      htmltools::tags$link(rel = "stylesheet", href = "https://cdn.jsdelivr.net/npm/bootstrap-icons@1.7.2/font/bootstrap-icons.css"),
      htmltools::tags$style(
        "
        :root {
          --primary-color: #2D3E50;
          --secondary-color: #E74C3C;
          --accent-color: #3498DB;
          --background-color: #F8F9FA;
          --text-color: #2C3E50;
          --border-color: #E5E9F0;
        }

        body { 
          font-family: 'Segoe UI', system-ui, -apple-system, sans-serif;
          color: var(--text-color);
          background-color: var(--background-color);
        }

        .page-wrapper {
          min-height: 100vh;
          display: flex;
          flex-direction: column;
        }

        .header {
          background: linear-gradient(135deg, var(--primary-color), var(--accent-color));
          color: white;
          padding: 2rem 0;
          position: relative;
          overflow: hidden;
        }

        .header-content {
          position: relative;
          z-index: 2;
        }

        .header-decoration {
          position: absolute;
          top: 0;
          right: 0;
          bottom: 0;
          left: 0;
          background: linear-gradient(45deg, rgba(255,255,255,0.1) 25%, transparent 25%),
                    linear-gradient(-45deg, rgba(255,255,255,0.1) 25%, transparent 25%);
          background-size: 60px 60px;
          opacity: 0.1;
        }

        .title-container {
          text-align: center;
          max-width: 1200px;
          margin: 0 auto;
          padding: 0 1rem;
        }

        .main-title {
          font-size: 2.5rem;
          font-weight: 700;
          margin: 0;
          line-height: 1.2;
        }

        .highlight {
          color: var(--secondary-color);
          background: rgba(255,255,255,0.1);
          padding: 0.2rem 0.5rem;
          border-radius: 4px;
        }

        .main-content {
          flex: 1;
          padding: 2rem 0;
          display: flex;
          flex-direction: column;
          align-items: center;
        }

        .carousel-container {
          width: 1200px;
          max-width: 100%;
          margin: 0 auto 2rem;
          padding: 0 4rem;
          position: relative;
        }

        .card {
          transition: transform 0.2s;
          border: 1px solid var(--border-color);
        }

        .card:hover {
          transform: translateY(-5px);
        }

        .card-img-container {
          height: 200px;
          overflow: hidden;
        }

        .card-img-top {
          width: 100%;
          height: 100%;
          object-fit: cover;
        }

        .card-body {
          padding: 1rem;
          display: flex;
          flex-direction: column;
          height: 360px;
        }

        .title-section {
          height: 30px;
          margin-bottom: 10px;
        }

        .description-section {
          height: 130px;
          margin-bottom: 20px;
          font-size: 15px;
        }

        .description-container {
          height: 130px;
          overflow-y: auto;
          padding-right: 0.5rem;
        }
        
        .description-container-thumb {
          height: 50%;
          overflow-y: auto;
          padding-right: 0.5rem;
        }

        .keywords-section {
          height: 75px;
          margin-bottom: 10px;
          overflow-y: auto;
          font-size: 14px;
        }

        .image-text-section {
          height: 110px;
          margin-bottom: 10px;
          overflow-y: auto;
          font-size: 14px;
        }

        .card-footer {
          height: 60px;
          padding: 1rem;
          border-top: 1px solid var(--border-color);
          background-color: #f0f1ff;
        }

        .content-tags {
          display: flex;
          flex-wrap: wrap;
          gap: 0.5rem;
          overflow-y: auto;
          border-radius: 4px;
        }
        
        .content-tags-thumb {
          display: flex;
          flex-wrap: wrap;
          gap: 0.5rem;
          overflow-y: auto;
          padding: 0.5rem;
          border-radius: 4px;
        }

        .description-container::-webkit-scrollbar,
        .keywords-section::-webkit-scrollbar,
        .image-text-section::-webkit-scrollbar,
        .content-tags::-webkit-scrollbar {
          width: 4px;
        }

        .description-container::-webkit-scrollbar-track,
        .keywords-section::-webkit-scrollbar-track,
        .image-text-section::-webkit-scrollbar-track,
        .content-tags::-webkit-scrollbar-track {
          background: #f1f1f1;
          border-radius: 2px;
        }

        .description-container::-webkit-scrollbar-thumb,
        .keywords-section::-webkit-scrollbar-thumb,
        .image-text-section::-webkit-scrollbar-thumb,
        .content-tags::-webkit-scrollbar-thumb {
          background: #888;
          border-radius: 2px;
        }

        .description-container::-webkit-scrollbar-thumb:hover,
        .keywords-section::-webkit-scrollbar-thumb:hover,
        .image-text-section::-webkit-scrollbar-thumb:hover,
        .content-tags::-webkit-scrollbar-thumb:hover {
          background: #555;
        }

        .tag {
          font-size: 0.75rem;
          padding: 0.25rem 0.5rem;
          border-radius: 1rem;
          color: #2C3E50;
          font-weight: 700;
        }

        .discriminatorio { background-color: #ffcdd2; }
        .violento { background-color: #fff9c4; }
        .pornografico { background-color: #e0e0e0; }
        .inapropiado { background-color: #b3e5fc; }

        .carousel-control {
          width: 3rem;
          height: 3rem;
          background-color: var(--primary-color);
          border-radius: 50%;
          opacity: 0.9;
          top: 50%;
          transform: translateY(-50%);
        }

        .carousel-control:hover {
          background-color: var(--accent-color);
          opacity: 1;
        }

        .carousel-control-prev {
          left: -1.5rem;
        }

        .carousel-control-next {
          right: -1.5rem;
        }

        .thumbnail-container {
          width: 100%;
          max-width: 1200px;
          height: 700px;
          overflow-y: auto;
          border: none;
          border-radius: 12px;
          padding: 1.5rem;
          margin-top: 2rem;
          background-color: #ffffff;
          box-shadow: 0 4px 6px rgba(0, 0, 0, 0.1), 0 1px 3px rgba(0, 0, 0, 0.08);
        }
        
        .thumbnail-card {
          border: none;
          border-radius: 8px;
          padding: 1rem;
          background-color: #f8f9fa;
          transition: all 0.3s ease;
          margin-bottom: 1rem;
        }
        
        .thumbnail-card:last-child {
          margin-bottom: 0;
        }
        
        .thumbnail-card:hover {
          transform: translateY(-2px);
          box-shadow: 0 4px 6px rgba(0, 0, 0, 0.1);
        }
        
        .thumbnail-img-container {
          width: 250px;
          height: 250px;
          flex-shrink: 0;
          margin-right: 1.5rem;
        }
        
        .thumbnail-img {
          width: 100%;
          height: 100%;
          object-fit: cover;
          border-radius: 8px;
        }
        
        .thumbnail-content {
          flex-grow: 1;
          overflow: hidden;
          display: flex;
          flex-direction: column;
          justify-content: space-between;
        }
        
        .thumbnail-container::-webkit-scrollbar {
          width: 8px;
        }
        
        .thumbnail-container::-webkit-scrollbar-track {
          background: #f1f1f1;
          border-radius: 4px;
        }
        
        .thumbnail-container::-webkit-scrollbar-thumb {
          background: #888;
          border-radius: 4px;
        }
        
        .thumbnail-container::-webkit-scrollbar-thumb:hover {
          background: #555;
        }
        
        @media (max-width: 768px) {
          .thumbnail-card {
            flex-direction: column;
          }
        
          .thumbnail-img-container {
            width: 100%;
            height: 250px;
            margin-right: 0;
            margin-bottom: 1rem;
          }
        }
        
        p {
          margin-top: 0;
          margin-bottom: 0;
        }

        code {
          font-size: .999em;
          color: plum;
          word-wrap: break-word;
        }

        .footer {
          background-color: #1e2937;
          color: white;
          padding: 1.5rem 0;
          margin-top: auto;
        }

        .footer-content {
          max-width: 1200px;
          margin: 0 auto;
          padding: 0 1rem;
          font-weight: 500;
        }

        .footer-brand-container {
          display: flex;
          align-items: center;
          justify-content: center;
          gap: 1rem;
          margin-bottom: 0.5rem;
        }

        .footer-brand {
          color: white;
          text-decoration: none;
          display: flex;
          align-items: center;
          gap: 0.5rem;
          font-size: 1rem;
        }

        .footer-brand:hover {
          color: rgba(255, 255, 255, 0.8);
        }

        .footer-separator {
          color: rgba(255, 255, 255, 0.5);
        }

        .footer-copyright {
          text-align: center;
          margin: 0;
          color: rgba(255, 255, 255, 0.8);
          font-size: 0.875rem;
        }

        .bi {
          font-size: 1.25rem;
        }

        @media (max-width: 1200px) {
          .carousel-container, .thumbnail-container {
            width: 100%;
            padding: 0 3rem;
          }
          
          .carousel-control-prev {
            left: 0;
          }

          .carousel-control-next {
            right: 0;
          }
        }

        @media (max-width: 768px) {
          .main-title {
            font-size: 1.8rem;
          }
          
        }
        "
      ),
      htmltools::tags$script(src = "https://code.jquery.com/jquery-3.6.0.min.js"),
      htmltools::tags$script(src = "https://cdn.jsdelivr.net/npm/bootstrap@5.1.3/dist/js/bootstrap.bundle.min.js")
    ),
    htmltools::tags$body(
      content
    )
  )
  
  # Guardar el HTML en un archivo
  output_file <- "visualizacion_imagenes.html"
  htmltools::save_html(html_content, file = output_file)
  file_name <- paste0(getwd(), "/", output_file)
  
  message("Visualización HTML generada y guardada en: ", file_name)
}
