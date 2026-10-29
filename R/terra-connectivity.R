# RASTERISE LAYERS
# make the habitat file into a sf object, not sfc
# create an empty raster grid of the correct dimensions, resolution
# set the CRS to the same as the habitat layer

#' Create Empty terra raster grid
#'
#' @param habitat SF object or terra SpatRaster.
#' @param resolution Numeric. Cell size in meters (default: 10).
#' @returns Terra SpatRaster. Empty raster grid.
#' @examples
#' lizard_barrier_shp <- example_barrier_shp()
#' empty_grid(lizard_barrier_shp, resolution = 10)
#' @export
empty_grid <- function(habitat, resolution = 10) {
  grid <- terra::rast(
    x = terra::ext(habitat),
    res = resolution,
    crs = terra::crs(habitat)
  )
  grid
}

#' Align a raster to a template grid
#'
#' Resamples `x` to match the grid of `template` if their geometries differ.
#' Do not do anything if they already match.
#'
#' @param x Terra SpatRaster to align.
#' @param template Terra SpatRaster to align to.
#' @param method Resampling method passed to [terra::resample()]. Default
#'   `"near"` is appropriate for categorical/mask rasters.
#' @returns Terra SpatRaster aligned to `template`.
#' @noRd
#' @note internal
align_to <- function(x, template, method = "near") {
  already_aligned <- terra::compareGeom(x, template, stopOnError = FALSE)
  if (!already_aligned) {
    terra::resample(x, template, method = method)
  } else {
    x
  }
}

#' Put a layer on a grid, whichever form it arrives in
#'
#' A vector layer is rasterised; a `SpatRaster` is already cells, so it is
#' resampled onto the grid instead. This is the one place that decides what an
#' empty cell means, which is why `background` is required: `NA` for habitat,
#' because a cell with no habitat in it has no value, and `0` for a barrier,
#' because a cell with no barrier in it is not blocked.
#'
#' Use it to put a scenario layer on the grid of the layer it replaces. A
#' scenario rasterised onto a grid of its own extent is a different landscape,
#' and [habitat_connectivity_comparison()] will refuse to compare it.
#'
#' @param layer An `sf`, `SpatVector` or `SpatRaster` layer.
#' @param grid A `SpatRaster` whose geometry the result takes, from
#'   [empty_grid()] or an already-prepared layer.
#' @param background Value for cells the layer does not cover. Ignored when
#'   `layer` is a `SpatRaster`, which brings its own.
#'
#' @returns A `SpatRaster` on `grid`'s geometry.
#' @seealso [prepare_rasters()], which uses this for both of its layers.
#' @export
#'
#' @examples
#' grid <- empty_grid(example_barrier_shp(), resolution = 10)
#'
#' # a vector layer is rasterised
#' onto_grid(example_barrier_shp(), grid, background = 0)
#'
#' # a raster one is resampled
#' onto_grid(example_habitat(), grid, background = NA)
onto_grid <- function(layer, grid, background) {
  check_layer_covers(layer, grid)

  if (inherits(layer, "SpatRaster")) {
    return(align_to(layer, grid))
  }

  terra::rasterize(layer, grid, background = background)
}

#' Prepare habitat and barrier rasters
#'
#' Put habitat and barrier layers on one grid. Either layer may be a vector
#' (`sf` or `SpatVector`), which is rasterised, or a `SpatRaster`, which is
#' resampled onto the grid.
#'
#' @param habitat SF object or `SpatRaster`. Habitat spatial data. In a raster,
#'   habitat is any cell that is neither `NA` nor `0`, whatever value it is
#'   coded with.
#' @param barrier SF object or `SpatRaster`. Barrier spatial data.
#' @param data_resolution Numeric. Fine resolution in meters. Default, 10.
#' @param target_resolution Numeric. Coarse resolution in meters. Default, 500.
#' @returns List with `habitat_raster` and `barrier_raster` elements.
#' @examples
#' lizard_habitat_sf <- terra::as.polygons(example_habitat(), dissolve = TRUE) |>
#'   sf::st_as_sf()
#' lizard_barrier_shp <- example_barrier_shp()
#' prepare_rasters(lizard_habitat_sf, lizard_barrier_shp)
#'
#' # a raster layer is resampled onto the grid rather than rasterised
#' prepare_rasters(example_habitat(), lizard_barrier_shp)
#' @export
prepare_rasters <- function(
  habitat,
  barrier,
  data_resolution = 10,
  target_resolution = 500
) {
  aggregation_factor <- target_resolution / data_resolution

  grid <- empty_grid(habitat, resolution = data_resolution)

  habitat_raster <- onto_grid(habitat, grid, background = NA)
  barrier_raster <- onto_grid(barrier, grid, background = 0)

  # aggregate rasters to make them the size of the overlay raster
  coarse_raster <- terra::aggregate(barrier_raster * 0, aggregation_factor)
  coarse_template <- terra::disagg(coarse_raster, aggregation_factor)

  habitat_raster_final <- terra::extend(habitat_raster, coarse_template)
  barrier_raster_final <- terra::extend(barrier_raster, coarse_template)

  list(
    habitat_raster = habitat_raster_final,
    barrier_raster = barrier_raster_final
  )
}

#' Create barrier mask
#'
#' Converts a barrier layer into a multiplier mask for connectivity analysis.
#'   Takes a raster where barriers are coded as 1 (and non-barriers as NA), and
#'   inverts it to produce a mask with NA values where barriers exist and 1
#'   elsewhere. This format allows barriers to be applied by multiplying the
#'   mask with connectivity surfaces, effectively blocking movement through
#'   barrier cells.
#'
#' @param barrier Terra SpatRaster. Barrier layer with 1 = barrier,
#'   NA = no barrier.
#' @returns Terra SpatRaster. Mask with 1 where movement is allowed, NA where
#'   barriers exist.
#' @export
#' @examples
#' lizard_barrier <- example_barrier()
#' create_barrier_mask(lizard_barrier)
create_barrier_mask <- function(barrier) {
  # convert barrier layer (1s and NAs) to a multiplier (NA where barrier is)
  barrier_multiplier <- barrier
  barrier_multiplier[is.na(barrier_multiplier)] <- 0
  barrier_multiplier[barrier_multiplier == 1] <- NA
  barrier_multiplier <- barrier_multiplier + 1
  barrier_multiplier
}

#' Remove habitat under barriers
#'
#' Performs a [terra::mask()] operation, to remove the habitat parts that are
#'   under the mask. Habitat is any cell that is neither `NA` nor `0`, whatever
#'   value it is coded with.
#'
#' @param habitat Terra SpatRaster. Habitat layer.
#' @param barrier_mask Terra SpatRaster. Barrier mask.
#' @returns Terra SpatRaster with habitat remaining after barrier removal,
#'   coded 1 for habitat and `NA` everywhere else.
#' @export
#' @examples
#' lizard_habitat <- example_habitat()
#' lizard_barrier <- example_barrier()
#' barrier_mask <- create_barrier_mask(lizard_barrier)
#' remaining_habitat <- drop_habitat_under_barrier(
#'   habitat = lizard_habitat,
#'   barrier_mask = barrier_mask
#'   )
#' remaining_habitat
drop_habitat_under_barrier <- function(habitat, barrier_mask) {
  barrier_mask <- align_to(barrier_mask, habitat)
  terra::mask(as_habitat_mask(habitat), barrier_mask)
}

#' Fragment habitat
#'
#' Takes a barrier mask (created with [create_barrier_mask()]) and fragments
#'   up the habitat where they intersect.
#'
#' @param buffered_habitat Terra SpatRaster. Buffered habitat, one layer (one
#'   radius of [habitat_buffer()]).
#' @param barrier_mask Terra SpatRaster. Barrier mask.
#' @returns Terra SpatRaster with fragmented habitat.
#' @export
#' @examples
#' lizard_habitat <- example_habitat()
#' lizard_barrier <- example_barrier()
#' buffered_habitat <- habitat_buffer(lizard_habitat, 5)
#' barrier_mask <- create_barrier_mask(lizard_barrier)
#' fragmented <- fragment_habitat(buffered_habitat, barrier_mask)
fragment_habitat <- function(buffered_habitat, barrier_mask) {
  check_single_layer(buffered_habitat)
  barrier_mask <- align_to(barrier_mask, buffered_habitat)
  buffered_habitat * barrier_mask
}

#' Assign patches to fragments
#'
#' @param remaining_habitat Terra SpatRaster. Remaining habitat.
#' @param fragment Terra SpatRaster. Fragment geometry.
#' @returns Terra SpatRaster with patch IDs.
#' @export
#' @examples
#' lizard_habitat <- example_habitat()
#' lizard_barrier <- example_barrier()
#' buffered_habitat <- habitat_buffer(lizard_habitat, 5)
#' barrier_mask <- create_barrier_mask(lizard_barrier)
#' fragmented <- fragment_habitat(buffered_habitat, barrier_mask)
#' remaining_habitat <- drop_habitat_under_barrier(
#'   habitat = lizard_habitat,
#'   barrier_mask = barrier_mask
#'   )
#' fragment_patches <- assign_patches_to_fragments(
#'   remaining_habitat = remaining_habitat,
#'   fragment = fragmented
#'   )
#' library(terra)
#' plot(fragment_patches)
assign_patches_to_fragments <- function(remaining_habitat, fragment) {
  patch_id_raster <- terra::patches(fragment)
  patch_id_raster <- align_to(patch_id_raster, remaining_habitat)
  # patch ids don't depend on how habitat is coded
  terra::mask(patch_id_raster, remaining_habitat, maskvalues = c(NA, 0))
}

#' Add patch area layer
#'
#' Adds an area layer to the raster of the area of each patch.
#'
#' @param raster terra SpatRaster with one layer. In the workflow, this is the
#'   patch ID raster.
#' @returns terra SpatRaster with two layers: patch_id and area.
#' @export
#' @examples
#' lizard_habitat <- example_habitat()
#' lizard_barrier <- example_barrier()
#' buffered_habitat <- habitat_buffer(lizard_habitat, 5)
#' barrier_mask <- create_barrier_mask(lizard_barrier)
#' fragmented <- fragment_habitat(buffered_habitat, barrier_mask)
#' remaining_habitat <- drop_habitat_under_barrier(
#'   habitat = lizard_habitat,
#'   barrier_mask = barrier_mask
#'   )
#' fragment_patches <- assign_patches_to_fragments(
#'   remaining_habitat = remaining_habitat,
#'   fragment = fragmented
#'   )
#' library(terra)
#' add_patch_area(fragment_patches)
add_patch_area <- function(raster) {
  check_single_layer(raster)
  with_cell_area(raster, terra::cellSize(raster))
}

#' @noRd
with_cell_area <- function(raster, area) {
  raster_with_area <- c(raster, area)
  names(raster_with_area) <- c("patch_id", "area")
  raster_with_area
}


#' Aggregate connected patch areas
#'
#' Aggregate a raster with connected patch areas into a data frame where
#' each row is a unique patch, and its area.
#'
#' @param raster terra SpatRaster. Raster with patch_id and area layers.
#' @returns Data frame with `patch_id` and `area` columns.
#' @export
#' @examples
#' lizard_habitat <- example_habitat()
#' lizard_barrier <- example_barrier()
#' buffered_habitat <- habitat_buffer(lizard_habitat, 5)
#' barrier_mask <- create_barrier_mask(lizard_barrier)
#' fragmented <- fragment_habitat(buffered_habitat, barrier_mask)
#' remaining_habitat <- drop_habitat_under_barrier(
#'   habitat = lizard_habitat,
#'   barrier_mask = barrier_mask
#'   )
#' fragment_patches <- assign_patches_to_fragments(
#'   remaining_habitat = remaining_habitat,
#'   fragment = fragmented
#'   )
#' library(terra)
#' patch_areas <- add_patch_area(fragment_patches)
#' aggregate_connected_patches(patch_areas)
aggregate_connected_patches <- function(raster) {
  ## TODO check that this raster has the correct names
  summed <- tibble::tibble(
    patch_id = as.numeric(terra::values(raster$patch_id)),
    area = as.numeric(terra::values(raster$area))
  ) |>
    dplyr::filter(
      !is.na(patch_id)
    ) |>
    dplyr::group_by(
      patch_id
    ) |>
    dplyr::summarise(
      area = sum(area)
    ) |>
    dplyr::mutate(area = round(area, 3))

  summed
}

#' Calculate habitat connectivity using terra
#'
#' This performs the entire connectivity workflow, returning a dataframe output.
#'   The steps are:
#'   * [create_barrier_mask()]: Creating barrier mask.
#'   * [drop_habitat_under_barrier()]: Removes Habitat underneath barrier.
#'   * [habitat_buffer()]: Buffers the habitat layer by the interpatch distance (m).
#'   * [fragment_habitat()]: Fragments habitat layer along barrier intersection.
#'   * [assign_patches_to_fragments()]: Assign patch ID to fragments.
#'   * [aggregate_connected_patches()]: Summarise area in each patch.
#'
#' @param habitat Terra SpatRaster. Habitat raster. Habitat is any cell that is
#'   neither `NA` nor `0`, whatever value it is coded with.
#' @param barrier Terra SpatRaster. Barrier raster.
#' @param species Species name. E.g., "Blue-tongued Lizard".
#' @param interpatch_distance Numeric. The distance (in meters) where habitat
#'   patches are considered connected. E.g., if set to 500, patches 498m apart
#'   are connected, those 501m apart are not connected. This is passed
#'   internally to a spatial operation known as "buffering", where this
#'   distance is used as a radius from the edge of the habitat zone. This means
#'   the specified `interpatch_distance` is halved exactly. So an interpatch
#'   distance of 500 will be converted to 250. For the buffer to be
#'   representable on the raster, keep `resolution <= interpatch_distance / 2`;
#'   below that the buffer is a no-op and a warning is raised. See
#'   `vignette("interpatch-distance-and-resolution")`.
#'
#'   May be a vector, which gives one row per distance, in the order given.
#'   The work that does not depend on the distance, including the distance
#'   surface every buffer is cut from, is done once for the whole vector.
#' @param verbose Logical. Display progress messages (default: TRUE).
#' @returns A `connectivity` object: a tibble of landscape-level connectivity
#'  metrics (patch count, effective mesh size, probability of connectedness,
#'  mean and total patch area), one row per interpatch distance, in the order
#'  the distances were given. The per-patch areas each summary is built from
#'  are stored in a list column, "patch_size" -- retrieve them with
#'  [patch_sizes()].
#' @seealso `vignette("interpatch-distance-and-resolution")` for the
#'   relationship between interpatch distance, buffer radius, and resolution.
#' @export
#' @examples
#' lizard_habitat <- example_habitat()
#' lizard_barrier <- example_barrier()
#' connectivity <- habitat_connectivity(
#'     habitat = lizard_habitat,
#'     barrier = lizard_barrier,
#'     species = "Blue-tongued Lizard",
#'     interpatch_distance = 12
#'   )
#' connectivity
#'
#' # get the patch size:
#' patch_sizes(connectivity)[[1]]
#'
#' # several distances at once
#' habitat_connectivity(
#'   habitat = lizard_habitat,
#'   barrier = lizard_barrier,
#'   species = "Blue-tongued Lizard",
#'   interpatch_distance = c(12, 24, 48),
#'   verbose = FALSE
#' )
habitat_connectivity <- function(
  habitat,
  barrier,
  species,
  interpatch_distance,
  verbose = TRUE
) {
  check_scalar_character(species)
  # validated up front, so an error names this function
  buffer_radius <- buffer_radius_from(interpatch_distance)

  layers <- connectivity_layers_quietly(
    habitat,
    barrier,
    buffer_radius,
    verbose,
    # only the summary is wanted here, so each radius's rasters can go
    keep_layers = FALSE
  )

  summarise_runs(
    runs = layers$at_radius,
    species = species,
    interpatch_distance = interpatch_distance,
    res = terra::res(habitat)
  )
}

#' Summarise the per-radius runs into one `connectivity` row per distance
#'
#' @param runs One list per distance, each holding `areas_connected`.
#' @noRd
summarise_runs <- function(runs, species, interpatch_distance, res) {
  purrr::map2(
    purrr::map(runs, "areas_connected"),
    interpatch_distance,
    function(areas, distance) {
      patch_size_tbl(
        data = areas,
        species = species,
        interpatch_distance = distance,
        res = res
      ) |>
        summarise_connectivity()
    }
  ) |>
    dplyr::bind_rows() |>
    new_connectivity()
}

#' `connectivity_layers()`, silenced when the caller asked for quiet
#'
#' @noRd
connectivity_layers_quietly <- function(
  habitat,
  barrier,
  buffer_radius,
  verbose,
  keep_layers = TRUE
) {
  run <- \() connectivity_layers(habitat, barrier, buffer_radius, keep_layers)
  if (verbose) run() else purrr::quietly(run)()$result
}

#' Run the connectivity pipeline at every buffer radius
#'
#' The engine behind [habitat_connectivity()] and
#' [habitat_connectivity_full()]. The barrier mask, remaining habitat, distance
#' surface and cell areas do not depend on the radius, so they are made once;
#' only the buffer threshold, fragmenting, patch and aggregation steps run per
#' radius.
#'
#' @param keep_layers Whether to keep each radius's (large) rasters too.
#' @returns A list of `barrier_mask`, `remaining_habitat` and `at_radius`, which
#'   holds one list per radius with its `areas_connected` and, if `keep_layers`,
#'   its `buffered_habitat` and `patch_id_raster`.
#' @noRd
connectivity_layers <- function(
  habitat,
  barrier,
  buffer_radius,
  keep_layers = TRUE
) {
  cli::cli_progress_step("Creating barrier mask")
  barrier_mask <- create_barrier_mask(barrier = barrier)

  cli::cli_progress_step("Removing habitat underneath barrier")
  remaining_habitat <- drop_habitat_under_barrier(
    habitat = habitat,
    barrier_mask = barrier_mask
  )

  cli::cli_progress_step(
    "Measuring the distance to the nearest habitat"
  )
  surface <- buffer_surface(remaining_habitat, buffer_radius)

  # the grid decides the cell areas, so one call covers every radius
  cell_area <- terra::cellSize(remaining_habitat)

  at_radius <- purrr::map(seq_along(buffer_radius), function(i) {
    cli::cli_progress_step(
      "Buffering habitat for an interpatch distance of {2 * buffer_radius[[i]]}m"
    )
    buffered_habitat <- habitat_within(surface, buffer_radius[[i]])

    cli::cli_progress_step(
      "Fragmenting habitat layer along barrier intersection"
    )
    fragmentation_raster <- fragment_habitat(
      buffered_habitat,
      barrier_mask
    )

    cli::cli_progress_step("Assigning patches ID to fragments")
    patch_id_raster <- assign_patches_to_fragments(
      remaining_habitat = remaining_habitat,
      fragment = fragmentation_raster
    ) |>
      with_cell_area(cell_area)

    cli::cli_progress_step("Summarising area in each patch")
    areas_connected <- aggregate_connected_patches(patch_id_raster)

    out <- list(areas_connected = areas_connected)
    if (keep_layers) {
      out <- c(
        list(
          buffered_habitat = buffered_habitat,
          patch_id_raster = patch_id_raster
        ),
        out
      )
    }
    out
  })

  list(
    barrier_mask = barrier_mask,
    remaining_habitat = remaining_habitat,
    at_radius = at_radius
  )
}

# TODO revist this - is this needed for the shiny app?
#' Calculate habitat connectivity with visualization data
#'
#' Like [habitat_connectivity()], but also returns the intermediate rasters
#' (buffered habitat, patch ID raster, barrier mask, remaining habitat) useful
#' for mapping and reporting.
#'
#' @inheritParams habitat_connectivity
#' @param interpatch_distance Numeric. One distance (in metres), unlike
#'   [habitat_connectivity()], which takes a vector of them: this returns the
#'   layers one distance produced, and there is only one set of them. See
#'   [habitat_connectivity()] for what the distance means.
#' @returns Named list with elements: `buffered_habitat`, `patch_id_raster`,
#'   `areas_connected`, `barrier_mask`, `remaining_habitat`.
#' @examples
#' lizard_habitat <- example_habitat()
#' lizard_barrier <- example_barrier()
#' result <- habitat_connectivity_full(
#'   lizard_habitat,
#'   lizard_barrier,
#'   interpatch_distance = 10,
#'   verbose = FALSE
#' )
#' names(result)
#' @export
habitat_connectivity_full <- function(
  habitat,
  barrier,
  interpatch_distance,
  verbose = TRUE
) {
  buffer_radius <- buffer_radius_from(interpatch_distance, scalar = TRUE)

  layers <- connectivity_layers_quietly(
    habitat,
    barrier,
    buffer_radius,
    verbose
  )

  c(
    layers$at_radius[[1]],
    layers[c("barrier_mask", "remaining_habitat")]
  )
}
