#' Distance along each row to the nearest habitat cell in that row
#'
#' Measured in cells, and `Inf` for a row with no habitat in it. Two running
#' extremes over the column index do it: the nearest habitat column at or to
#' the left, and the nearest at or to the right.
#'
#' @param habitat_cells Logical matrix, `TRUE` where there is habitat, holding
#'   one **column** per raster row (see `distance_to_nearest_habitat()`), so a
#'   scan along a raster row runs down a column.
#' @returns Numeric matrix shaped like `habitat_cells`.
#' @noRd
cells_to_nearest_habitat_in_row <- function(habitat_cells) {
  cells_per_row <- nrow(habitat_cells)
  no_habitat <- cells_per_row + 1L
  column <- seq_len(cells_per_row)

  # apply() drops to a bare vector when the matrix is one cell wide or tall
  along_each_row <- \(x, f) array(apply(x, 2, f), dim(x))

  # `column` recycles down each matrix column. 0 marks a cell with no habitat,
  # and no column index is ever 0.
  habitat_column <- column * habitat_cells
  habitat_column_or_end <- habitat_column
  habitat_column_or_end[habitat_column == 0L] <- no_habitat

  cummin_from_right <- \(v) rev(cummin(rev(v)))
  nearest_left <- along_each_row(habitat_column, cummax)
  nearest_right <- along_each_row(habitat_column_or_end, cummin_from_right)
  rm(habitat_column, habitat_column_or_end)

  cells_to_left <- column - nearest_left
  cells_to_left[nearest_left == 0L] <- Inf
  cells_to_right <- nearest_right - column
  cells_to_right[nearest_right == no_habitat] <- Inf

  pmin(cells_to_left, cells_to_right)
}

#' Widen the search for the nearest habitat by one row up and down
#'
#' One step of the fold in `distance_to_nearest_habitat()`. It takes each
#' cell's squared distance to the nearest habitat within `offset - 1` rows of
#' it, and returns the nearest within `offset` rows, by also counting the
#' habitat `offset` rows above and below.
#'
#' @param squared_distance Squared distance to the nearest habitat found so
#'   far, one column per raster row.
#' @param offset How many rows up and down the search now reaches, from 1 to
#'   one less than the number of rows.
#' @param squared_along_row Squared distance along each row, laid out as
#'   `squared_distance`.
#' @param cell_height Cell height in metres.
#' @returns `squared_distance`, updated, or in `purrr::done()` to stop the fold.
#' @noRd
widen_search <- function(
  squared_distance,
  offset,
  squared_along_row,
  cell_height
) {
  squared_offset <- (offset * cell_height)^2

  # An offset can only improve a cell whose best so far is further than the
  # offset's height, so the fold stops early
  if (max(squared_distance) <= squared_offset) {
    return(purrr::done(squared_distance))
  }

  # Each cell lined up against the row `offset` above it, then below it, with
  # Inf where that row is off the grid
  n_rows <- ncol(squared_distance)
  off_grid <- matrix(Inf, nrow(squared_distance), offset)
  rows_above <- seq_len(n_rows - offset)
  rows_below <- (offset + 1L):n_rows
  from_above <- cbind(off_grid, squared_along_row[, rows_above, drop = FALSE]) +
    squared_offset
  from_below <- cbind(squared_along_row[, rows_below, drop = FALSE], off_grid) +
    squared_offset

  # Assigning into `squared_distance` would copy it at every offset, since
  # reduce() still holds it
  pmin(squared_distance, from_above, from_below)
}

#' Distance from every cell to the nearest habitat cell
#'
#' `terra::focal()` with a circular window visits every cell of the window at
#' every cell of the raster, O(cells * radius^2). This is O(cells * radius):
#' a pass along the rows, then one row offset at a time.
#'
#' Not `terra::distance()`, which on non-square cells measures rows at the
#' column width.
#'
#' @param habitat A `SpatRaster` habitat layer, with one layer.
#' @param distance_within Numeric. How far out the answer has to be right.
#'   This is what bounds the work: only row offsets that could land within
#'   `distance_within` are considered.
#' @returns A `SpatRaster`, exact out to `distance_within`. Further out it may
#'   overstate the distance, which no radius up to `distance_within` can see.
#' @noRd
distance_to_nearest_habitat <- function(habitat, distance_within) {
  cell_width <- terra::xres(habitat)
  cell_height <- terra::yres(habitat)
  n_rows <- terra::nrow(habitat)

  # One column per raster row. terra::values() is row major, so giving it
  # this shape transposes it for free, and that is the layout the rest of
  # this wants: a row offset then shifts whole columns.
  habitat_cells <- is_habitat(terra::values(habitat, mat = FALSE))
  dim(habitat_cells) <- c(terra::ncol(habitat), n_rows)

  # squared throughout, so the row offsets add without a square root
  cells_along_row <- cells_to_nearest_habitat_in_row(habitat_cells)
  squared_along_row <- (cells_along_row * cell_width)^2
  rm(cells_along_row)

  # +1 because floor() can drop an exact multiple (4.3 / 0.1 is 42.99...),
  # and allow_for_rounding() keeps a cell exactly one radius away
  rows_in_reach <- floor(distance_within / cell_height) + 1L
  n_offsets <- min(rows_in_reach, n_rows - 1L)

  # Start from the nearest habitat in each cell's own row, then widen the
  # search one row up and down at a time
  squared_distance <- purrr::reduce(
    seq_len(n_offsets),
    function(squared_distance, offset) {
      widen_search(squared_distance, offset, squared_along_row, cell_height)
    },
    .init = squared_along_row
  )

  distance <- sqrt(as.vector(squared_distance))
  terra::rast(habitat, vals = distance)
}
