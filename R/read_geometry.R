#' Read shapefile geometry
#'
#' Reads a shapefile and extracts only the spatial geometry, discarding
#' attribute data.
#'
#' @param shapefile Character. File path to a shapefile, or an SF object.
#'
#' @returns An `sfc` object containing only the spatial geometry.
#'
#' @examples
#' # Read geometry from a file path
#' barrier_path <- system.file("ex/lizard_barrier.shp", package = "urbioconnect")
#' barrier_geom <- read_geometry(barrier_path)
#'
#' # Can also pass an existing SF object
#' barrier_sf <- sf::st_read(barrier_path, quiet = TRUE)
#' barrier_geom <- read_geometry(barrier_sf)
#'
#' @export
read_geometry <- function(shapefile) {
  UseMethod("read_geometry")
}

#' @export
#' @rdname read_geometry
read_geometry.sf <- function(shapefile) {
  sf::st_geometry(shapefile)
}

#' @export
#' @rdname read_geometry
read_geometry.default <- function(shapefile) {
  shapefile |>
    sf::st_read(quiet = TRUE) |>
    sf::st_geometry()
}
