#' Buffer habitat by distance
#'
#' Creates a buffer around habitat polygons and unions overlapping areas into
#' a single polygon, using [sf::st_buffer()]. Unlike the raster
#' [habitat_buffer()], this works in continuous coordinate space, so there is
#' **no resolution constraint**: any `buffer_radius` produces an exact buffer
#' and the sub-cell "no buffer" problem of the raster path does not apply. The
#' buffer arc is approximated by `nQuadSegs` straight segments per quarter
#' circle (here 5, i.e. a 20-sided polygon), which affects the *smoothness* of
#' the outline, not whether the buffer forms. See
#' `vignette("interpatch-distance-and-resolution")`.
#'
#' @param habitat SF object. Habitat spatial data.
#' @param buffer_radius Numeric. The radius in metres around the habitat.
#'   Specify it as half the interpatch distance (see [habitat_buffer()]).
#'   Because vector buffering is done in continuous space, there is no minimum
#'   representable radius - unlike the raster path, there is no resolution below
#'   which the buffer becomes a no-op.
#'
#' @returns SF object with buffered and unioned habitat geometry.
#' @examples
#' lizard_habitat_sf <- terra::as.polygons(example_habitat(), dissolve = TRUE) |>
#'   sf::st_as_sf()
#' \dontrun{
#' sf_habitat_buffer(lizard_habitat_sf, buffer_radius = 10)
#' }
#' @export
sf_habitat_buffer <- function(habitat, buffer_radius) {
  # buffer by the required buffer_radius
  habitat_buffer <- sf::st_buffer(
    x = habitat,
    dist = buffer_radius,
    nQuadSegs = 5
  )
  # union creates one large polygon rather than multiple small ones
  habitat_union <- sf::st_union(habitat_buffer, by_feature = FALSE)
  habitat_union
}

#' Fragment habitat along barriers
#'
#' Removes barrier areas from buffered habitat and splits the result into
#' individual polygon fragments.
#'
#' @param habitat_buffered SF object. Buffered habitat geometry.
#' @param barrier SF object. Barrier geometry (e.g., roads).
#'
#' @returns SF object with individual habitat fragments, each with a unique ID.
#' @examples
#' lizard_habitat_sf <- terra::as.polygons(example_habitat(), dissolve = TRUE) |>
#'   sf::st_as_sf()
#' lizard_barrier_shp <- example_barrier_shp()
#' \dontrun{
#' buffered <- sf_habitat_buffer(lizard_habitat_sf, interpatch_distance = 10)
#' sf_fragment_habitat(buffered, lizard_barrier_shp)
#' }
#' @export
sf_fragment_habitat <- function(habitat_buffered, barrier) {
  # Remove road polygon areas from buffered habitat polygon, creating gaps
  habitat_buffered_no_roads <- sf::st_difference(habitat_buffered, barrier)
  # creates individual polygons, rather than one mega polygon
  fragmented_geometry <- habitat_buffered_no_roads |>
    sf::st_cast("POLYGON") |>
    sf::st_sf(fg = _) |>
    # sequentially number the ID
    tibble::rowid_to_column(var = "id")

  fragmented_geometry
}

#' Remove habitat underneath barriers
#'
#' Removes all habitat areas that intersect with barriers and splits
#' multipolygons into individual patches.
#'
#' @param habitat SF object. Original habitat geometry.
#' @param barrier SF object. Barrier geometry.
#'
#' @returns SF object with habitat patches that don't intersect barriers.
#' @examples
#' lizard_habitat_sf <- terra::as.polygons(example_habitat(), dissolve = TRUE) |>
#'   sf::st_as_sf()
#' lizard_barrier_shp <- example_barrier_shp()
#' sf_drop_habitat_under_barrier(lizard_habitat_sf, lizard_barrier_shp)
#' @export
sf_drop_habitat_under_barrier <- function(habitat, barrier) {
  # remove all habitat under barriers
  habitat_no_barriers <- sf::st_difference(habitat, barrier)
  # split multipolygon into the original number of separate polygons
  remaining_patches <- sf::st_cast(habitat_no_barriers, "POLYGON")
  remaining_patches
}

#' Assign habitat patches to fragment IDs
#'
#' Determines which connected fragment each remaining habitat patch belongs to
#' based on spatial intersection.
#'
#' @param remaining SF object. Remaining habitat patches after barrier removal.
#' @param fragment_id SF object. Fragment geometries with IDs.
#'
#' @returns SF object with habitat patches labeled by their fragment ID.
#' @examples
#' lizard_habitat_sf <- terra::as.polygons(example_habitat(), dissolve = TRUE) |>
#'   sf::st_as_sf()
#' lizard_barrier_shp <- example_barrier_shp()
#' \dontrun{
#' buffered <- sf_habitat_buffer(lizard_habitat_sf, buffer_radius = 10)
#' fragments <- sf_fragment_habitat(buffered, lizard_barrier_shp)
#' remaining <- sf_drop_habitat_under_barrier(lizard_habitat_sf, lizard_barrier_shp)
#' sf_assign_patches_to_fragments(remaining, fragments)
#' }
#' @export
sf_assign_patches_to_fragments <- function(remaining, fragment_id) {
  intersects <- sf::st_intersects(remaining, fragment_id)
  membership <- vapply(intersects, dplyr::first, FUN.VALUE = numeric(1))
  habitat_id <- sf::st_sf(geometry = remaining) |>
    dplyr::mutate(patch_id = membership)
  habitat_id
}

#' Add patch area column
#'
#' @param patches SF object. Habitat patches.
#'
#' @returns SF object with added `area` column in square meters.
#' @examples
#' lizard_habitat_sf <- terra::as.polygons(example_habitat(), dissolve = TRUE) |>
#'   sf::st_as_sf()
#' \dontrun{
#' lizard_barrier_shp <- example_barrier_shp()
#' buffered <- sf_habitat_buffer(lizard_habitat_sf, buffer_radius = 10)
#' fragments <- sf_fragment_habitat(buffered, lizard_barrier_shp)
#' remaining <- sf_drop_habitat_under_barrier(lizard_habitat_sf, lizard_barrier_shp)
#' patches <- sf_assign_patches_to_fragments(remaining, fragments)
#' sf_add_patch_area(patches)
#' }
#' @export
sf_add_patch_area <- function(patches) {
  patches |>
    dplyr::mutate(area = sf::st_area(geometry))
}
#' Aggregate connected patch areas
#'
#' Groups habitat patches by their connected fragment ID and calculates total
#' and squared areas for connectivity metrics.
#'
#' @param patch_areas SF object. Habitat patches with area column.
#'
#' @returns Data frame with `patch_id`, `area`, and `area_squared` columns.
#' @examples
#' lizard_habitat_sf <- terra::as.polygons(example_habitat(), dissolve = TRUE) |>
#'   sf::st_as_sf()
#' lizard_barrier_shp <- example_barrier_shp()
#' \dontrun{
#' buffered <- sf_habitat_buffer(lizard_habitat_sf, buffer_radius = 10)
#' fragments <- sf_fragment_habitat(buffered, lizard_barrier_shp)
#' remaining <- sf_drop_habitat_under_barrier(lizard_habitat_sf, lizard_barrier_shp)
#' patches <- sf_assign_patches_to_fragments(remaining, fragments) |>
#'   sf_add_patch_area()
#' sf_aggregate_connected_patches(patches)
#' }
#' @export
sf_aggregate_connected_patches <- function(patch_areas) {
  summed <- patch_areas |>
    sf::st_drop_geometry() |>
    dplyr::group_by(patch_id) |>
    dplyr::summarise(area = as.numeric(sum(area))) |>
    dplyr::mutate(area_squared = as.numeric(area^2))
  summed
}

#' Calculate habitat connectivity
#'
#' Performs complete habitat connectivity analysis using vector-based spatial
#' operations. Buffers habitat, fragments it along barriers, and calculates
#' areas of connected patches.
#'
#' @param habitat SF object. Original habitat spatial data.
#' @param barrier SF object. Barrier spatial data (e.g., roads, waterways).
#' @param species character. Species name.
#' @param interpatch_distance Numeric. The distance (in meters) where habitat
#'   patches are considered connected. E.g., if set to 500, patches 498m apart
#'   are connected, those 501m apart are not connected. This is passed
#'   internally to a spatial operation known as "buffering", where this
#'   distance is used as a radius from the edge of the habitat zone. This means
#'   the specified `interpatch_distance` is halved exactly. So an interpatch
#'   distance of 500 will be converted to 250. Note that
#'   `interpatch_distance` is mutually exclusive to `habitat_buffer`, so you
#'    can only specify either `interpatch_distance` or  `habitat_buffer`, and
#'    never both.
#' @param buffer_radius Numeric. The radius in metres around the habitat.
#'   Since patches of habitat will be connected when their edge-to-edge gap is
#'   <= 2 * `buffer radius`, we recommend you specify `buffer_radius` to be
#'   half the "interpatch distance". This is the distance past which habitat
#'   patches are no longer considered connected. For example, if your
#'   interpatch distance is 500m, set `buffer_radius = 250`. Note that
#'   `interpatch_distance` is mutually exclusive to `habitat_buffer`, so you
#'    can only specify either `interpatch_distance` or  `habitat_buffer`, and
#'    never both.

#'
#' @returns Data frame with connectivity metrics for each connected patch,
#'   including `patch_id`, `area`, and `area_squared`.
#'
#' @examples
#' lizard_barrier_shp <- example_barrier_shp()
#' lizard_habitat_sf <- terra::as.polygons(
#'   example_habitat(),
#'   dissolve = TRUE
#'   ) |>
#'   sf::st_as_sf()
#' result <- sf_habitat_connectivity(
#'   habitat = lizard_habitat_sf,
#'   barrier = lizard_barrier_shp,
#'   species = "Blue-tongued lizard",
#'   interpatch_distance = 10
#'   )
#' result
#' @export
sf_habitat_connectivity <- function(
  habitat,
  barrier,
  species,
  interpatch_distance = NULL,
  buffer_radius = NULL
) {
  buffer_radius <- resolve_buffer_radius(interpatch_distance, buffer_radius)
  # buffer the habitat layer by the buffer_radius
  buffer <- sf_habitat_buffer(habitat, buffer_radius)
  # create fragmentation geometry
  fragment <- sf_fragment_habitat(buffer, barrier)
  # remove all habitat under barriers
  habitat_remaining <- sf_drop_habitat_under_barrier(habitat, barrier)
  # identify remaining habitat patches according to their connected area
  habitat_remaining_id <- sf_assign_patches_to_fragments(
    habitat_remaining,
    fragment
  ) |>
    # calculate area of each habitat patch
    sf_add_patch_area()
  # group the patches by connected area ID
  areas_connected <- sf_aggregate_connected_patches(habitat_remaining_id)
  areas_connected <- patch_size_tbl(
    data = areas_connected,
    species = species,
    # store the FULL distance
    interpatch_distance = buffer_radius * 2
  )
  areas_connected
}
