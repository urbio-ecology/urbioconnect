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
#'   habitat patches are considered connected. May be a scalar or a vector; a
#'   vector runs the pipeline once per distance.
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
  interpatch_distance,
  verbose = TRUE
) {
  check_distances(interpatch_distance)
  check_scalar_character(species)

  runs <- purrr::map(interpatch_distance, function(distance) {
    habitat_connectivity_full(
      habitat = habitat,
      barrier = barrier,
      interpatch_distance = distance,
      verbose = verbose
    )
  })
  runs <- rlang::set_names(runs, as.character(interpatch_distance))

  connectivity <- purrr::map2(
    runs,
    interpatch_distance,
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
    interpatch_distance = interpatch_distance
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
