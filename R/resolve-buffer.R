#' The buffer radius for each interpatch distance
#'
#' Two patches are connected when their edge-to-edge gap is at most the
#' interpatch distance, which happens when each is buffered by half of it. The
#' radius is an implementation detail of the buffering: `habitat_buffer()` takes
#' them, nothing above it does.
#'
#' Vectorised, because [habitat_connectivity()] sweeps. `scalar = TRUE` is for
#' the callers that take one distance only, and adds the length constraint on
#' top of the same checks rather than running a parallel set of them.
#'
#' @noRd
buffer_radius_from <- function(
  interpatch_distance,
  scalar = FALSE,
  arg = rlang::caller_arg(interpatch_distance),
  call = rlang::caller_env()
) {
  check_distances(interpatch_distance, arg, call)

  if (scalar) {
    check_scalar(interpatch_distance, arg, call)
  }

  interpatch_distance / 2
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

  # habitat_buffer() keeps a cell when its centre is within the radius, so a
  # buffer reaches floor(radius / resolution) whole cells along a row or a
  # column. A negative distance reaches none.
  pmax(0, 2 * floor(interpatch_distance / 2 / resolution) * resolution)
}

# warn if the distance can't be represented at this res
#' @noRd
warn_buffer_resolution <- function(buffer_radius, resolution) {
  # the radius is internal: these warnings reach users through
  # habitat_connectivity(), so they talk in interpatch distances
  interpatch_distance <- buffer_radius * 2

  # Callers pass the smaller cell side.
  treated_as <- representable_distance(interpatch_distance, resolution)

  if (treated_as == 0) {
    cli::cli_warn(c(
      "Can't represent an {.arg interpatch_distance} of \\
      {interpatch_distance}m at a resolution of {resolution}m.",
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

  if (!isTRUE(all.equal(treated_as, interpatch_distance))) {
    cli::cli_warn(c(
      "{.arg interpatch_distance} doesn't align with the raster resolution.",
      "x" = "{interpatch_distance} m isn't a multiple of {2 * resolution} m.",
      "i" = "It snaps to {treated_as} m.",
      "i" = "Connectivity may shift for patches near the cut-off.",
      "i" = "See {.vignette urbioconnect::interpatch-distance-and-resolution}."
    ))
  }
  invisible()
}
