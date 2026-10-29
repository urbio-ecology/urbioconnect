#' Is a cell habitat?
#'
#' A habitat layer marks absence either with `NA`, which is what
#' [onto_grid()] writes, or with `0`, which is what a habitat GeoTIFF read
#' straight off disk often uses. Anything else present is habitat, whatever
#' value it is coded with.
#'
#' @noRd
is_habitat <- function(values) {
  !is.na(values) & values != 0
}

#' Distance along each row to the nearest habitat cell in that row
#'
#' Measured in cells, and `Inf` for a row with no habitat in it. Two running
#' extremes over the column index do it: the nearest habitat column at or to
#' the left, and the nearest at or to the right.
#'
#' @param present Logical matrix, `TRUE` where there is habitat, holding one
#'   **column** per raster row (see `nearest_habitat_distance()`), so a scan
#'   along a raster row runs down a column.
#' @returns Numeric matrix shaped like `present`.
#' @noRd
row_gap_cells <- function(present) {
  n_cols <- nrow(present)
  absent <- n_cols + 1L
  here <- seq_len(n_cols)

  # apply() drops to a bare vector when the matrix is one cell wide or tall
  scan_rows <- \(x, f) array(apply(x, 2, f), dim(x))

  # `here` recycles down each column; 0 marks a cell with no habitat, and no
  # column index is ever 0
  at_or_left <- here * present
  at_or_right <- at_or_left
  at_or_right[at_or_left == 0L] <- absent

  nearest_left <- scan_rows(at_or_left, cummax)
  nearest_right <- scan_rows(at_or_right, \(v) rev(cummin(rev(v))))
  rm(at_or_left, at_or_right)

  to_left <- here - nearest_left
  to_left[nearest_left == 0L] <- Inf
  to_right <- nearest_right - here
  to_right[nearest_right == absent] <- Inf

  pmin(to_left, to_right)
}

#' Distance from every cell to the nearest habitat cell
#'
#' A circular buffer of radius `r` is the set of cells lying within `r` of
#' some habitat cell, so it is a threshold of this one surface. The surface is
#' measured once, out to the largest radius wanted, and each radius is a
#' comparison against it.
#'
#' `terra::focal()` with a circular window visits every cell of the window at
#' every cell of the raster, O(cells * radius^2). This is O(cells * radius):
#' a pass along the rows, then one row offset at a time.
#'
#' Not `terra::distance()`: it is faster but approximate, and on the lizard
#' landscape puts 20 cells the wrong side of a 10 m radius.
#'
#' @param habitat A `SpatRaster` habitat layer, with one layer.
#' @param max_distance Numeric. How far out the answer has to be right. This
#'   is what bounds the work: only row offsets that could land within
#'   `max_distance` are considered.
#' @returns A `SpatRaster`, exact out to `max_distance`. Further out it may
#'   overstate the distance, which no radius up to `max_distance` can see.
#' @noRd
nearest_habitat_distance <- function(habitat, max_distance) {
  resolution <- terra::res(habitat)
  n_rows <- terra::nrow(habitat)

  # One column per raster row. terra::values() is row major, so filling a
  # matrix of this shape column by column transposes it for free, and that is
  # the layout the rest of this wants: a row offset then shifts whole columns.
  present <- matrix(
    is_habitat(terra::values(habitat, mat = FALSE)),
    nrow = terra::ncol(habitat),
    ncol = n_rows
  )

  # squared throughout, so the row offsets add without a square root
  within_row <- (row_gap_cells(present) * resolution[1])^2

  # +1 because floor() can drop an exact multiple (4.3 / 0.1 is 42.99...);
  # habitat_within() makes the comparison
  offsets <- min(floor(max_distance / resolution[2]) + 1L, n_rows - 1L)

  # An offset can only improve a cell whose best so far is further than that
  # offset's vertical distance, so the loop stops early.
  squared <- within_row

  for (rows_away in seq_len(offsets)) {
    vertical <- (rows_away * resolution[2])^2

    if (max(squared) <= vertical) {
      break
    }

    up <- (rows_away + 1L):n_rows
    down <- seq_len(n_rows - rows_away)
    squared[, up] <- pmin(
      squared[, up, drop = FALSE],
      within_row[, down, drop = FALSE] + vertical
    )
    squared[, down] <- pmin(
      squared[, down, drop = FALSE],
      within_row[, up, drop = FALSE] + vertical
    )
  }

  terra::rast(habitat, vals = as.vector(sqrt(squared)))
}

#' The cells within a given radius of habitat
#'
#' @param habitat_distance A surface from `nearest_habitat_distance()`, measured
#'   out to at least `buffer_radius`.
#' @param buffer_radius Numeric. The radius in metres.
#' @returns A `SpatRaster`, 1 within the radius and `NA` outside it.
#' @noRd
habitat_within <- function(habitat_distance, buffer_radius) {
  # the tolerance keeps a cell exactly one radius away: 3 * 0.1 is past 0.3
  within <- terra::ifel(
    habitat_distance <= buffer_radius * (1 + 1e-9),
    1,
    NA
  )
  names(within) <- paste0("radius_", buffer_radius)
  within
}

#' Measure the one distance surface the radii share
#'
#' @returns A surface from `nearest_habitat_distance()`, reaching the largest
#'   radius.
#' @noRd
buffer_surface <- function(habitat, buffer_radius) {
  # the smaller cell side: below it no other cell centre is in reach
  resolution <- min(terra::res(habitat))
  purrr::walk(buffer_radius, \(radius) {
    warn_buffer_resolution(radius, resolution)
  })
  nearest_habitat_distance(habitat, max(buffer_radius))
}

#' Buffer habitat raster
#'
#' Buffer around the habitat a given distance in metres. Every cell lying
#'   within `buffer_radius` of a habitat cell is kept. This operation is
#'   used to identify connected patches of habitat. Two patches will connect
#'   when their edge-to-edge gap is <= 2 * `buffer radius`. So, we recommend
#'   you specify the `buffer_radius` value to be half the interpatch distance,
#'   which is the distance past which habitat patches are no longer considered
#'   connected. For example, if your interpatch distance is 500m, set
#'   `buffer_radius = 250`.
#'
#' Habitat is any cell that is neither `NA` nor `0`, whatever value it is
#'   coded with. A cell is within the radius when its centre is.
#'
#' @param habitat Terra SpatRaster. Habitat raster, with one layer.
#' @param buffer_radius Numeric. The radius in metres around the habitat, or a
#'   vector of radii. Since patches of habitat will be connected when their
#'   edge-to-edge gap is <= 2 * `buffer radius`, we recommend you specify
#'   `buffer_radius` to be half the "interpatch distance". This is the
#'   distance past which habitat patches are no longer considered connected.
#'   For example, if your interpatch distance is 500m, set
#'   `buffer_radius = 250`. The buffer can only be represented if it is at
#'   least one raster cell, i.e. keep `resolution <= interpatch_distance / 2`.
#'   Below that the buffer is a no-op: `habitat_buffer()` warns and keeps only
#'   the habitat itself. See `vignette("interpatch-distance-and-resolution")`.
#' @returns Terra SpatRaster with one layer per radius, in the order given and
#'   named `radius_<radius>` (for example `radius_250`). Each layer is 1 within
#'   the radius of habitat and `NA` elsewhere. All layers are cut from one
#'   distance surface, measured out to the largest radius.
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
#'
#' # several radii give one layer each
#' habitat_buffer(lizard_habitat, buffer_radius = c(10, 20))
habitat_buffer <- function(habitat, buffer_radius) {
  check_single_layer(habitat)
  check_distances(buffer_radius)
  surface <- buffer_surface(habitat, buffer_radius)
  purrr::map(buffer_radius, \(radius) habitat_within(surface, radius)) |>
    terra::rast()
}
