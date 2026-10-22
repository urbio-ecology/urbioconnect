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
  if (rlang::is_missing(rlang::maybe_missing(interpatch_distance))) {
    cli::cli_abort(
      "{.arg {arg}} is absent but must be supplied.",
      call = call
    )
  }

  check_scalar_numeric(interpatch_distance, arg, call)
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
  verbose
) {
  habitat_connectivity(
    habitat = habitat,
    barrier = barrier,
    species = species,
    interpatch_distance = interpatch_distance,
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

  # terra::focalMat() includes a cell when its centre is within the radius, so
  # the number of rings is floor(radius / resolution). Verified empirically:
  # d = 350 at 500 m cells is 1x1; d = 500 and d = 600 are 3x3. A negative
  # distance has no rings either.
  pmax(0, 2 * floor(interpatch_distance / 2 / resolution) * resolution)
}

# warn if the distance can't be represented at this res
#' @noRd
warn_buffer_resolution <- function(buffer_radius, resolution) {
  # the radius is internal: these warnings reach users through
  # habitat_connectivity(), so they talk in interpatch distances
  interpatch_distance <- buffer_radius * 2

  # Assumes square cells (callers pass terra::res(habitat)[1]).
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
