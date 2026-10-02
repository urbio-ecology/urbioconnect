#' The urbioconnect map colours
#'
#' The palette the package's maps use, so a map downloaded from the Shiny app
#'   matches the one on screen. Based on scico's tofino palette.
#'
#' @returns A named list of colours: `habitat`, `interpatch_distance` and
#'   `barrier`.
#' @export
#'
#' @examples
#' urbio_colours()
urbio_colours <- function() {
  palette <- scico::scico(n = 11, palette = "tofino")[6:11]

  list(
    habitat = palette[2],
    interpatch_distance = palette[5],
    barrier = "#FFFFFF"
  )
}

#' The default figure size for urbioconnect maps and plots
#'
#' Shared by the downloadable PNGs and the report, so a map keeps its shape
#'   across both. Width and heights are inches and `dpi` is dots per inch, as
#'   [ggplot2::ggsave()] and Quarto's `fig-width`, `fig-height` and `fig-dpi`
#'   expect. `tall_height` is for the faceted over-distance plot, which needs
#'   more vertical room than a map.
#'
#' @returns A named list: `width`, `height`, `tall_height` and `dpi`.
#' @export
#'
#' @examples
#' urbio_figure_size()
urbio_figure_size <- function() {
  list(width = 8, height = 6, tall_height = 8, dpi = 150)
}
