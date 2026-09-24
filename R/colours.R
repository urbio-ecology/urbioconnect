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
