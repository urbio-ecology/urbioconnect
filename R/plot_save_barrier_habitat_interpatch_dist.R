#' Save barrier habitat interpatch distance plot
#'
#' Draws the plot [gg_barrier_habitat_interpatch_dist()] makes and writes it to
#'   a PNG in the working directory, at the shared size from
#'   [urbio_figure_size()]. Returns the file path, which is what a
#'   `targets::tar_file()` target wants.
#'
#' @inheritParams gg_barrier_habitat_interpatch_dist
#' @param interpatch_distance Numeric. The interpatch distance, in metres,
#'   that `buffered` was made for. Used only to label the plot and name the
#'   file.
#'
#' @returns Named character vector. The file path, named by the interpatch
#'   distance.
#' @examples
#' \dontrun{
#' lizard_habitat <- example_habitat()
#' lizard_barrier <- example_barrier()
#' interpatch_distance <- 20
#' lizard_full <- habitat_connectivity_full(
#'   habitat = lizard_habitat,
#'   barrier = lizard_barrier,
#'   interpatch_distance = interpatch_distance,
#'   verbose = FALSE
#' )
#' # Creates plot-barrier-interpatch-distance-habitat-*.png in the working
#' # directory
#' plot_barrier_habitat_interpatch_dist(
#'   barrier = lizard_barrier,
#'   buffered = lizard_full$buffered_habitat,
#'   habitat = lizard_habitat,
#'   interpatch_distance = interpatch_distance,
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
  col_paper = "grey96"
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
