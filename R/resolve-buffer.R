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

# warn if the distance can't be represented at this res
#' @noRd
warn_buffer_resolution <- function(buffer_radius, resolution) {
  # A cell counts as within the radius when its CENTRE is, so the reachable
  # distances are whole cells. Callers pass the smaller cell side.
  n_rings <- floor(buffer_radius / resolution)

  # the radius is internal: these warnings reach users through
  # habitat_connectivity(), so they talk in interpatch distances
  interpatch_distance <- buffer_radius * 2

  if (n_rings < 1) {
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

  effective_radius <- n_rings * resolution
  if (!isTRUE(all.equal(effective_radius, buffer_radius))) {
    cli::cli_warn(c(
      "{.arg interpatch_distance} doesn't align with the raster resolution.",
      "x" = "{interpatch_distance} m isn't a multiple of {2 * resolution} m.",
      "i" = "It snaps to {2 * effective_radius} m.",
      "i" = "Connectivity may shift for patches near the cut-off.",
      "i" = "See {.vignette urbioconnect::interpatch-distance-and-resolution}."
    ))
  }
  invisible()
}
