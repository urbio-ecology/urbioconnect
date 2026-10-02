#' Save barrier habitat interpatch distance plot
#'
#' Draws the plot [gg_barrier_habitat_interpatch_dist()] makes and writes it to
#'   a PNG in the working directory, at the shared size from
#'   [urbio_figure_size()]. Returns the file path, which is what a
#'   `targets::tar_file()` target wants.
#'
#' @param barrier barrier layer
#' @param habitat habitat layer
#' @param buffered buffered layer
#' @param species character, species name, e.g., "Superb Fairy Wren"
#' @param col_barrier colour to colour the barrier layer. Defaults to the
#'   package palette, see [urbio_colours()].
#' @param col_interpatch_dist colour to colour the interpatch distance layer
#' @param col_habitat colour to colour the habitat layer
#' @param col_paper colour to colour the paper layer of ggplot
#' @param interpatch_distance Numeric. The distance (in meters) where habitat
#'   patches are considered connected. E.g., if set to 500, patches 498m apart
#'   are connected, those 501m apart are not connected. This is passed
#'   internally to a spatial operation known as "buffering", where this
#'   distance is used as a radius from the edge of the habitat zone. This means
#'   the specified `interpatch_distance` is halved exactly. So an interpatch
#'   distance of 500 will be converted to 250.
#'
#' @returns Named character vector. The file path, named by the interpatch
#'   distance.
#' @examples
#' \dontrun{
#' lizard_habitat <- example_habitat()
#' lizard_barrier <- example_barrier()
#' buffered <- habitat_buffer(lizard_habitat, interpatch_distance = 10)
#' # Creates plot-barrier-interpatch-dist-habitat-*.png in the working directory
#' plot_barrier_habitat_interpatch_dist(
#'   barrier = lizard_barrier,
#'   buffered = buffered,
#'   habitat = lizard_habitat,
#'   interpatch_distance = 10,
#'   species = "Blue-tongued Lizard",
#'   col_barrier = "white",
#'   col_interpatch_dist = "lightgreen",
#'   col_habitat = "seagreen",
#'   col_paper = "grey50"
#' )
#' }
#' @export
plot_barrier_habitat_interpatch_dist <- function(
  barrier,
  buffered,
  habitat,
  interpatch_distance,
  species,
  col_barrier = urbio_colours()$barrier,
  col_interpatch_dist = urbio_colours()$interpatch_distance,
  col_habitat = urbio_colours()$habitat,
  col_paper = NA
) {
  # slugified, so a species with a space in it still gives a clean file name
  path <- as.character(glue::glue(
    "plot-barrier-interpatch-distance-habitat-\\
     {slugify(species)}-{interpatch_distance}.png"
  ))

  gg_barrier_habitat_interpatch_dist(
    barrier = barrier,
    habitat = habitat,
    buffered = buffered,
    interpatch_distance = interpatch_distance,
    species = species,
    col_barrier = col_barrier,
    col_interpatch_dist = col_interpatch_dist,
    col_habitat = col_habitat,
    col_paper = col_paper
  ) |>
    save_asset_plot(path)

  stats::setNames(path, interpatch_distance)
}
