#' The buffer radius for an interpatch distance
#'
#' Two patches are connected when their edge-to-edge gap is at most the
#' interpatch distance, which happens when each is buffered by half of it. The
#' radius is an implementation detail of the buffering: `habitat_buffer()` takes
#' one, nothing above it does.
#'
#' @noRd
buffer_radius_from <- function(
  interpatch_distance,
  arg = rlang::caller_arg(interpatch_distance),
  call = rlang::caller_env()
) {
  check_distance(interpatch_distance, arg, call)
  interpatch_distance / 2
}

#' Run the connectivity pipeline at one distance
#'
#' @noRd
connectivity_at_distance <- function(
  habitat,
  barrier,
  species,
  interpatch_distance,
  directions,
  verbose
) {
  habitat_connectivity(
    habitat = habitat,
    barrier = barrier,
    species = species,
    interpatch_distance = interpatch_distance,
    directions = directions,
    verbose = verbose
  )
}

#' The interpatch distance a grid can represent
#'
#' Buffering grows habitat a whole cell at a time, by half the interpatch
#' distance from each side, so a distance is rounded down to a multiple of
#' twice the cell size. Below twice the cell size nothing is buffered, and only
#' patches that touch are joined. [habitat_connectivity()] warns when either
#' happens; this says which distance you get, before you run anything.
#'
#' @param interpatch_distance Numeric vector of distances, in metres.
#' @param resolution Cell size in metres, a single positive number.
#'
#' @returns A numeric vector the length of `interpatch_distance`: the distance
#'   each is treated as. `0` where it can't be represented, which includes a
#'   negative distance. `NA` stays `NA`.
#' @seealso `vignette("interpatch-distance-and-resolution")`
#' @export
#'
#' @examples
#' representable_distance(c(100, 250, 15), resolution = 10)
representable_distance <- function(interpatch_distance, resolution) {
  check_numeric(interpatch_distance)
  check_scalar_numeric(resolution)
  if (!is.finite(resolution) || resolution <= 0) {
    cli::cli_abort(
      "{.arg resolution} must be a positive number, not {resolution}."
    )
  }

  buffer_radius <- interpatch_distance / 2
  # whole cells along a row or column whose centres the buffer reaches
  cells <- floor(allow_for_rounding(buffer_radius) / resolution)
  pmax(0, 2 * cells * resolution)
}

#' Allow for rounding at the edge of a buffer
#'
#' A cell exactly one radius away is within the buffer, but floating point can
#' put it just past: 3 * 0.1 is past 0.3. `habitat_buffer()` and
#' `representable_distance()` both measure against this, so the warning
#' describes the cells the buffer keeps.
#'
#' @param radius Numeric, the buffer radius in metres.
#' @param tolerance The room left past `radius`, as a fraction of it.
#' @returns `radius`, stretched by `tolerance`.
#' @noRd
allow_for_rounding <- function(radius, tolerance = 1e-9) {
  radius * (1 + tolerance)
}

# warn if the distance can't be represented at this res
#' @noRd
warn_buffer_resolution <- function(buffer_radius, resolution) {
  # the radius is internal: these warnings reach users through
  # habitat_connectivity(), so they talk in interpatch distances
  interpatch_distance <- buffer_radius * 2

  # One per side of the cell, across and then up and down. The buffer reaches
  # a whole number of cells along each, so on cells that aren't square the two
  # differ.
  snapped_distances <- purrr::map_dbl(resolution, function(side) {
    representable_distance(interpatch_distance, side)
  })

  if (all(snapped_distances == 0)) {
    smaller_side <- signif(min(resolution), 4)
    cli::cli_warn(c(
      "Can't represent an {.arg interpatch_distance} of \\
      {interpatch_distance}m at a resolution of {smaller_side}m.",
      "x" = "Half that distance ({buffer_radius}m) is smaller than one raster \\
      cell.",
      "i" = "Gaps between patches aren't bridged; only touching patches are \\
      linked.",
      "i" = "Rule of thumb: keep resolution <= interpatch_distance / 2 (use \\
      finer cells, or a larger interpatch distance).",
      "i" = "See {.vignette urbioconnect::interpatch-distance-and-resolution}."
    ))
    return(invisible())
  }

  snaps <- !purrr::map_lgl(snapped_distances, function(distance) {
    isTRUE(all.equal(distance, interpatch_distance))
  })
  if (any(snaps)) {
    multiples <- unique(signif(2 * resolution[snaps], 4))
    snapped <- signif(snapped_distances, 4)
    snaps_to <- if (length(unique(snapped)) == 1) {
      glue::glue("{snapped[1]} m")
    } else {
      glue::glue("{snapped[1]} m across and {snapped[2]} m up and down")
    }
    cli::cli_warn(c(
      "{.arg interpatch_distance} doesn't align with the raster resolution.",
      "x" = "{interpatch_distance} m isn't a multiple of {.or {multiples}} m.",
      "i" = "It snaps to {snaps_to}.",
      "i" = "Connectivity may shift for patches near the cut-off.",
      "i" = "See {.vignette urbioconnect::interpatch-distance-and-resolution}."
    ))
  }
  invisible()
}
