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

# warn if the distance can't be represented at this res
#' @noRd
warn_buffer_resolution <- function(buffer_radius, resolution) {
  # terra::focalMat() includes a cell when its CENTRE is within `buffer_radius`,
  # so the number of usable rings is floor(buffer_radius / resolution).
  # (Verified empirically: d=350/res=500 -> 1x1; d=500 -> 3x3; d=600 -> 3x3.)
  # Assumes square cells (callers pass terra::res(habitat)[1]).
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
