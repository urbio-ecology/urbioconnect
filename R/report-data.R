#' Everything one connectivity analysis produces
#'
#' Runs the connectivity pipeline once per distance and keeps both the summary
#'   and the spatial layers the maps need. [habitat_connectivity()] returns the
#'   summary alone; this also keeps the buffered habitat and the patch-ID
#'   raster for each distance, which is what the downloadable assets and the
#'   report are built from.
#'
#' @param habitat Terra SpatRaster. The habitat layer.
#' @param barrier Terra SpatRaster. The barrier layer.
#' @param species Species name. E.g., "Superb Fairy Wren".
#' @param interpatch_distance Numeric. The distance (in metres) at which
#'   habitat patches are considered connected. May be a scalar or a vector.
#'   Provide exactly one of `interpatch_distance` or `buffer_radius`.
#' @param buffer_radius Numeric. The radius in metres around the habitat, an
#'   alternative to `interpatch_distance`.
#' @param verbose Logical. Display progress messages (default: TRUE).
#'
#' @returns A `connectivity_report_data` object: a list of
#'   * `connectivity`, a `connectivity` summary with one row per distance
#'   * `habitat` and `barrier`, the layers as supplied
#'   * `buffered_habitat` and `patch_id_raster`, lists of `SpatRaster`, one per
#'     distance and named by it
#'   * `species` and `interpatch_distance`
#' @seealso [habitat_connectivity()] when only the summary is wanted.
#' @export
#'
#' @examples
#' \donttest{
#' report_data <- connectivity_report_data(
#'   habitat = example_wren_habitat(),
#'   barrier = example_wren_barrier(),
#'   species = "Superb Fairy Wren",
#'   interpatch_distance = 200,
#'   verbose = FALSE
#' )
#'
#' report_data$connectivity
#' names(report_data$patch_id_raster)
#' }
connectivity_report_data <- function(
  habitat,
  barrier,
  species,
  interpatch_distance = NULL,
  buffer_radius = NULL,
  verbose = TRUE
) {
  supplied <- check_distance_arg(
    interpatch_distance,
    buffer_radius,
    require_length = TRUE
  )
  check_scalar_character(species)

  distances <- distance_values(supplied, interpatch_distance, buffer_radius)

  # a buffer radius is half an interpatch distance; the object is labelled with
  # the interpatch distance whichever argument the caller used
  interpatch_distances <- if (supplied == "buffer_radius") {
    distances * 2
  } else {
    distances
  }

  runs <- purrr::map(distances, function(distance) {
    full_at_distance(habitat, barrier, distance, supplied, verbose)
  })
  runs <- rlang::set_names(runs, as.character(interpatch_distances))

  connectivity <- purrr::map2(
    runs,
    interpatch_distances,
    function(run, interpatch_distance) {
      patch_size_tbl(
        data = run$areas_connected,
        species = species,
        interpatch_distance = interpatch_distance,
        res = terra::res(habitat)
      ) |>
        summarise_connectivity()
    }
  ) |>
    dplyr::bind_rows()

  new_connectivity_report_data(
    connectivity = connectivity,
    habitat = habitat,
    barrier = barrier,
    buffered_habitat = purrr::map(runs, "buffered_habitat"),
    patch_id_raster = purrr::map(runs, "patch_id_raster"),
    species = species,
    interpatch_distance = interpatch_distances
  )
}

#' Run the full pipeline at one distance
#'
#' As `connectivity_at_distance()`, but keeping the intermediate rasters.
#'
#' @noRd
full_at_distance <- function(habitat, barrier, distance, supplied, verbose) {
  rlang::exec(
    habitat_connectivity_full,
    habitat,
    barrier,
    verbose = verbose,
    !!!rlang::set_names(list(distance), supplied)
  )
}

#' Construct a `connectivity_report_data` object
#'
#' @noRd
new_connectivity_report_data <- function(
  connectivity,
  habitat,
  barrier,
  buffered_habitat,
  patch_id_raster,
  species,
  interpatch_distance
) {
  structure(
    list(
      connectivity = connectivity,
      habitat = habitat,
      barrier = barrier,
      buffered_habitat = buffered_habitat,
      patch_id_raster = patch_id_raster,
      species = species,
      interpatch_distance = interpatch_distance
    ),
    class = "connectivity_report_data"
  )
}
