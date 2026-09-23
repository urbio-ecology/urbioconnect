#' Require exactly one of interpatch_distance / buffer_radius
#'
#' Shared guard for the "one of these two distance arguments" rule, used by
#' `resolve_buffer_radius()` and `habitat_connectivity_comparison()`. Aborts if
#' zero or both are supplied, otherwise returns the name of the supplied
#' argument. With `require_length = TRUE`, a zero-length value (e.g.
#' `numeric(0)`) counts as *not* supplied.
#'
#' @param interpatch_distance,buffer_radius The two candidate arguments.
#' @param require_length Logical. Treat zero-length values as not supplied.
#' @param call Environment used for the error call.
#' @returns `"interpatch_distance"` or `"buffer_radius"`.
#' @noRd
check_distance_arg <- function(
  interpatch_distance = NULL,
  buffer_radius = NULL,
  require_length = FALSE,
  call = rlang::caller_env()
) {
  has_id <- !is.null(interpatch_distance) &&
    (!require_length || length(interpatch_distance) >= 1)
  has_br <- !is.null(buffer_radius) &&
    (!require_length || length(buffer_radius) >= 1)

  if (has_id && has_br) {
    cli::cli_abort(
      c(
        "Specify exactly one of {.arg interpatch_distance} or \\
         {.arg buffer_radius}.",
        "x" = "Both were supplied."
      ),
      call = call
    )
  }
  if (!has_id && !has_br) {
    cli::cli_abort(
      c(
        "Specify exactly one of {.arg interpatch_distance} or \\
         {.arg buffer_radius}.",
        "x" = "Neither was supplied."
      ),
      call = call
    )
  }

  if (has_id) "interpatch_distance" else "buffer_radius"
}

#' The distances to sweep over
#'
#' `supplied` is `check_distance_arg()`'s return value, naming whichever of the
#' two arguments the caller used. This picks that one's values.
#'
#' @noRd
distance_values <- function(supplied, interpatch_distance, buffer_radius) {
  switch(
    supplied,
    interpatch_distance = interpatch_distance,
    buffer_radius = buffer_radius
  )
}

#' Run the connectivity pipeline at one distance
#'
#' Passes `distance` back to [habitat_connectivity()] under the name the caller
#' used, so a sweep doesn't have to branch on which argument that was.
#'
#' @noRd
connectivity_at_distance <- function(
  habitat,
  barrier,
  species,
  distance,
  supplied,
  verbose
) {
  rlang::exec(
    habitat_connectivity,
    habitat,
    barrier,
    species = species,
    verbose = verbose,
    !!!rlang::set_names(list(distance), supplied)
  )
}

#' @noRd
resolve_buffer_radius <- function(
  interpatch_distance = NULL,
  buffer_radius = NULL
) {
  supplied <- check_distance_arg(interpatch_distance, buffer_radius)
  buffer_radius <- switch(
    supplied,
    interpatch_distance = {
      check_scalar_numeric(interpatch_distance)
      interpatch_distance / 2
    },
    buffer_radius = {
      check_scalar_numeric(buffer_radius)
      buffer_radius
    }
  )
  buffer_radius
}

# warn if the radius can't be represented at this res
#' @noRd
warn_buffer_resolution <- function(buffer_radius, resolution) {
  # terra::focalMat() includes a cell when its CENTRE is within `buffer_radius`,
  # so the number of usable rings is floor(buffer_radius / resolution).
  # (Verified empirically: d=350/res=500 -> 1x1; d=500 -> 3x3; d=600 -> 3x3.)
  # Assumes square cells (callers pass terra::res(habitat)[1]).
  n_rings <- floor(buffer_radius / resolution)

  if (n_rings < 1) {
    cli::cli_warn(c(
      "Can't represent the buffer at a resolution of {resolution}m.",
      "x" = "Buffer radius ({buffer_radius}m) is smaller than one raster \\
      cell.",
      "i" = "This radius corresponds to an {.arg interpatch_distance} of \\
      {buffer_radius * 2}m.",
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
      "Buffer radius doesn't align with the raster resolution.",
      "x" = "{buffer_radius} m isn't a multiple of {resolution} m.",
      "i" = "It snaps to {effective_radius} m (interpatch distance \\
      {2 * effective_radius} m).",
      "i" = "Connectivity may shift for patches near the cut-off.",
      "i" = "See {.vignette urbioconnect::interpatch-distance-and-resolution}."
    ))
  }
  invisible()
}
