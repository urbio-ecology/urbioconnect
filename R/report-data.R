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

#' Save and reload a connectivity analysis
#'
#' Writes a `connectivity_report_data` object to an `.rds` file, and reads it
#'   back. The summary, the habitat and barrier layers, and the patch raster
#'   for each distance all travel together in the one file.
#'
#'   [base::saveRDS()] on its own isn't enough. A `SpatRaster` points at
#'   memory or at a file on disk rather than carrying its own values, so it
#'   saves as a null pointer and comes back unusable. [terra::wrap()] packs
#'   the values into the object on the way out, and [terra::unwrap()] restores
#'   them on the way in.
#'
#'   This is also how an analysis reaches the separate R session that Quarto
#'   renders the report in.
#'
#' @param x A `connectivity_report_data` object from
#'   [connectivity_report_data()].
#' @param path File to write to, or read from.
#'
#' @returns `write_report_data()` returns `path` invisibly;
#'   `read_report_data()` returns the `connectivity_report_data`.
#' @seealso [connectivity_report_data()]
#' @export
#'
#' @examples
#' \donttest{
#' report_data <- connectivity_report_data(
#'   habitat = example_habitat(),
#'   barrier = example_barrier(),
#'   species = "Blue Tongue Lizard",
#'   interpatch_distance = 20,
#'   verbose = FALSE
#' )
#'
#' path <- write_report_data(report_data, tempfile(fileext = ".rds"))
#' read_report_data(path)$connectivity
#' }
write_report_data <- function(x, path) {
  check_report_data(x)
  report_rasters <- map_report_rasters(x, terra::wrap)
  saveRDS(report_rasters, path)
  invisible(path)
}

#' @rdname write_report_data
#' @export
read_report_data <- function(path) {
  # checked before unwrapping: an rds of something else would otherwise fail
  # deep inside terra, or quietly come back malformed
  x <- readRDS(path)

  if (!is_report_data(x)) {
    cli::cli_abort(c(
      "{.path {basename(path)}} doesn't hold a
       {.cls connectivity_report_data} object.",
      "x" = "It holds {.obj_type_friendly {x}}.",
      "i" = "Write one with {.fn write_report_data}."
    ))
  }

  map_report_rasters(x, terra::unwrap)
}

#' Is this a `connectivity_report_data` object?
#'
#' @noRd
is_report_data <- function(x) {
  inherits(x, "connectivity_report_data")
}

#' Is there more than one distance to compare?
#'
#' A single distance gives a single point, so the over-distance plot has
#' nothing to show. Asked by both the manifest and the report, so that the
#' rule lives with the analysis rather than in each renderer.
#'
#' @noRd
has_over_distance_plot <- function(x) {
  length(x$interpatch_distance) > 1
}

#' Apply a function to every raster in a `connectivity_report_data`
#'
#' @noRd
map_report_rasters <- function(x, f) {
  x$habitat <- f(x$habitat)
  x$barrier <- f(x$barrier)
  x$buffered_habitat <- purrr::map(x$buffered_habitat, f)
  x$patch_id_raster <- purrr::map(x$patch_id_raster, f)
  x
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
