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

#' Prepare habitat and barrier rasters
#'
#' Convert vector (shapefile) SF habitat and barrier objects into rasters.
#'
#' @param habitat SF object. Habitat spatial data.
#' @param barrier SF object. Barrier spatial data.
#' @param data_resolution Numeric. Fine resolution in meters. Default, 10.
#' @param target_resolution Numeric. Coarse resolution in meters. Default, 500.
#' @returns List with `habitat_raster` and `barrier_raster` elements.
#' @examples
#' lizard_habitat_sf <- terra::as.polygons(example_habitat(), dissolve = TRUE) |>
#'   sf::st_as_sf()
#' lizard_barrier_shp <- example_barrier_shp()
#' prepare_rasters(lizard_habitat_sf, lizard_barrier_shp)
#' @export
prepare_rasters <- function(
  habitat,
  barrier,
  data_resolution = 10,
  target_resolution = 500
) {
  aggregation_factor <- target_resolution / data_resolution

  grid <- empty_grid(habitat, resolution = data_resolution)

  # convert the vector format into a raster
  habitat_raster <- terra::rasterize(habitat, grid, background = NA)
  barrier_raster <- terra::rasterize(barrier, grid, background = 0)

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


#' Buffer habitat raster
#'
#' Buffer around the habitat a given distance in metres using
#'   `terra::focalMat(d = buffer_radius, type = "circle")`. This operation is
#'   used to identify connected patches of habitat. Two patches will connect
#'   when their edge-to-edge gap is <= 2 * `buffer radius`. So, we recommend
#'   you specify the `buffer_radius` value to be half the interpatch distance,
#'   which is the distance past which habitat patches are no longer considered
#'   connected. For example, if your interpatch distance is 500m, set
#'   `buffer_radius = 250`.
#'
#' @param habitat Terra SpatRaster. Habitat raster.
#' @param buffer_radius Numeric. The radius in metres around the habitat.
#'   Since patches of habitat will be connected when their edge-to-edge gap is
#'   <= 2 * `buffer radius`, we recommend you specify `buffer_radius` to be
#'   half the "interpatch distance". This is the distance past which habitat
#'   patches are no longer considered connected. For example, if your
#'   interpatch distance is 500m, set `buffer_radius = 250`. The buffer can only
#'   be represented if it is at least one raster cell, i.e. keep
#'   `resolution <= interpatch_distance / 2`. Below that the buffer is a no-op:
#'   `habitat_buffer()` warns and returns the habitat unchanged. See
#'   `vignette("interpatch-distance-and-resolution")`.
#' @returns Terra SpatRaster with buffered habitat.
#' @seealso `vignette("interpatch-distance-and-resolution")` for the
#'   relationship between interpatch distance, buffer radius, and resolution.
#' @export
#' @examples
#' lizard_habitat <- example_habitat()
#' library(terra)
#' plot(lizard_habitat, col = "darkgreen", legend = FALSE)
#' # run with a small buffer radius
#' lizard_buff <- habitat_buffer(lizard_habitat, buffer_radius = 10)
#' plot(lizard_buff, col = "lightgreen", legend = FALSE)
#' plot(lizard_habitat, col = "darkgreen", legend = FALSE, add = TRUE)
habitat_buffer <- function(habitat, buffer_radius) {
  resolution <- terra::res(habitat)[1]
  warn_buffer_resolution(
    buffer_radius = buffer_radius,
    resolution = resolution
  )
  # A sub-cell radius rounds to zero rings: terra::focalMat() returns a 1x1
  # window and terra::focal() errors ("not a meaningful window"). The buffer is a
  # no-op at this resolution, so return the habitat unchanged - the warning above
  # has already explained the consequence (only touching patches are linked).
  if (buffer_radius < resolution) {
    return(habitat)
  }
  buffer_window <- terra::focalMat(
    x = habitat,
    d = buffer_radius,
    type = "circle"
  )
  buffer_window <- buffer_window / max(buffer_window)
  buffered_habitat <- terra::focal(
    x = habitat,
    w = buffer_window,
    fun = max,
    na.rm = TRUE
  )
  buffered_habitat[buffered_habitat != 1] <- NA
  buffered_habitat
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
#' Essentially just performs a [terra::mask()] operation, to remove the habitat
#'   parts that are under the mask.
#'
#' @param habitat Terra SpatRaster. Habitat layer.
#' @param barrier_mask Terra SpatRaster. Barrier mask.
#' @returns Terra SpatRaster with habitat remaining after barrier removal.
#' @export
#' @examples
#' lizard_habitat <- example_habitat()
#' lizard_barrier <- example_barrier()
#' barrier_mask <- create_barrier_mask(lizard_barrier)
#' remaining_habitat <- drop_habitat_under_barrier(
#'   habitat = lizard_habitat,
#'   barrier = lizard_barrier
#'   )
#' remaining_habitat
drop_habitat_under_barrier <- function(habitat, barrier_mask) {
  barrier_mask <- align_to(barrier_mask, habitat)
  habitat_no_barriers <- terra::mask(habitat, barrier_mask)
  habitat_no_barriers
}

#' Fragment habitat
#'
#' Takes a barrier mask (created with [create_barrier_mask()]) and fragments
#'   up the habitat where they intersect.
#'
#' @param buffered_habitat Terra SpatRaster. Buffered habitat.
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
#'   barrier = lizard_barrier
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
  patch_id_raster <- remaining_habitat * patch_id_raster
  patch_id_raster
}

#' Add patch area layer
#'
#' Adds an area layer to the raster of the area of each patch.
#'
#' @param raster terra SpatRaster. In the workflow, this is the patch ID raster.
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
#'   barrier = lizard_barrier
#'   )
#' fragment_patches <- assign_patches_to_fragments(
#'   remaining_habitat = remaining_habitat,
#'   fragment = fragmented
#'   )
#' library(terra)
#' add_patch_area(fragment_patches)
add_patch_area <- function(raster) {
  raster_with_area <- c(raster, terra::cellSize(raster))
  names(raster_with_area) <- c("patch_id", "area")
  raster_with_area
}


#' Aggregate connected patch areas
#'
#' Aggregate a raster with connected patch areas into a data frame where
#' each row is a unique patch, and its area and area squared.
#'
#' @param raster terra SpatRaster. Raster with patch_id and area layers.
#' @returns Data frame with patch areas and areas squared.
#' @export
#' @examples
#' lizard_habitat <- example_habitat()
#' lizard_barrier <- example_barrier()
#' buffered_habitat <- habitat_buffer(lizard_habitat, 5)
#' barrier_mask <- create_barrier_mask(lizard_barrier)
#' fragmented <- fragment_habitat(buffered_habitat, barrier_mask)
#' remaining_habitat <- drop_habitat_under_barrier(
#'   habitat = lizard_habitat,
#'   barrier = lizard_barrier
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
    dplyr::mutate(area_squared = area^2) |>
    dplyr::mutate(dplyr::across(dplyr::starts_with("area"), \(x) round(x, 3)))

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
#' @param habitat Terra SpatRaster. Habitat raster.
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
#' @param verbose Logical. Display progress messages (default: TRUE).
#' @returns A `connectivity` object (one row): a tibble of landscape-level
#'  connectivity metrics (patch count, effective mesh size, probability of
#'  connectedness, mean and total patch area) for the species and
#'  interpatch distance supplied. The per-patch areas the summary is built
#'  from are stored in a list column, "patch_size" -- retrieve them with
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
habitat_connectivity <- function(
  habitat,
  barrier,
  species,
  interpatch_distance,
  verbose = TRUE
) {
  buffer_radius <- buffer_radius_from(interpatch_distance)
  if (verbose) {
    habitat_connectivity <- .habitat_connectivity(
      habitat,
      barrier,
      buffer_radius = buffer_radius
    )
  } else {
    quiet_habitat_connectivity <- purrr::quietly(
      .habitat_connectivity
    )
    habitat_connectivity <- quiet_habitat_connectivity(
      habitat,
      barrier,
      buffer_radius
    )$result
  }

  habitat_connectivity <- patch_size_tbl(
    data = habitat_connectivity,
    species = species,
    interpatch_distance = interpatch_distance,
    res = terra::res(habitat)
  )

  connectivity <- summarise_connectivity(connectivity = habitat_connectivity)

  connectivity
}

#' @noRd
#' @note internal
.habitat_connectivity <- function(habitat, barrier, buffer_radius) {
  cli::cli_progress_step("Creating barrier mask")
  barrier_mask <- create_barrier_mask(barrier = barrier)

  cli::cli_progress_step("Removing habitat underneath barrier")
  remaining_habitat <- drop_habitat_under_barrier(
    habitat = habitat,
    barrier_mask = barrier_mask
  )

  cli::cli_progress_step(
    "Buffering habitat for an interpatch distance of {2 * buffer_radius}m"
  )
  buffered_habitat <- habitat_buffer(
    habitat = remaining_habitat,
    buffer_radius = buffer_radius
  )

  cli::cli_progress_step("Fragmenting habitat layer along barrier intersection")
  fragmentation_raster <- fragment_habitat(
    buffered_habitat,
    barrier_mask
  )

  cli::cli_progress_step("Assigning patches ID to fragments")
  patch_id_raster <- assign_patches_to_fragments(
    remaining_habitat = remaining_habitat,
    fragment = fragmentation_raster
  ) |>
    add_patch_area()

  cli::cli_progress_step("Summarising area in each patch")
  areas_connected <- aggregate_connected_patches(patch_id_raster)
  areas_connected
}

# TODO revist this - is this needed for the shiny app?
#' Calculate habitat connectivity with visualization data
#'
#' Like [habitat_connectivity()], but also returns the intermediate rasters
#' (buffered habitat, patch ID raster, barrier mask, remaining habitat) useful
#' for mapping and reporting.
#'
#' @inheritParams habitat_connectivity
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
  buffer_radius <- buffer_radius_from(interpatch_distance)
  if (!verbose) {
    quiet_fun <- purrr::quietly(.habitat_connectivity_full)
    res <- quiet_fun(habitat, barrier, buffer_radius)
    return(res$result)
  }

  .habitat_connectivity_full(habitat, barrier, buffer_radius)
}

#' @noRd
#' @note internal
.habitat_connectivity_full <- function(habitat, barrier, buffer_radius) {
  cli::cli_progress_step("Creating barrier mask")
  barrier_mask <- create_barrier_mask(barrier = barrier)

  cli::cli_progress_step("Removing habitat underneath barrier")
  remaining_habitat <- drop_habitat_under_barrier(
    habitat = habitat,
    barrier_mask = barrier_mask
  )

  cli::cli_progress_step(
    "Buffering habitat for an interpatch distance of {2 * buffer_radius}m"
  )
  buffered_habitat <- habitat_buffer(
    habitat = remaining_habitat,
    buffer_radius = buffer_radius
  )

  cli::cli_progress_step("Fragmenting habitat layer along barrier intersection")
  fragmentation_raster <- fragment_habitat(
    buffered_habitat,
    barrier_mask
  )

  cli::cli_progress_step("Assigning patches ID to fragments")
  patch_id_raster <- assign_patches_to_fragments(
    remaining_habitat = remaining_habitat,
    fragment = fragmentation_raster
  ) |>
    add_patch_area()

  cli::cli_progress_step("Summarising area in each patch")
  areas_connected <- aggregate_connected_patches(patch_id_raster)

  # Return all intermediate results
  list(
    buffered_habitat = buffered_habitat,
    patch_id_raster = patch_id_raster,
    areas_connected = areas_connected,
    barrier_mask = barrier_mask,
    remaining_habitat = remaining_habitat
  )
}
