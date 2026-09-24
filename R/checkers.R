check_class <- function(
  x,
  class_predicate,
  class_name,
  arg = rlang::caller_arg(x),
  call = rlang::caller_env()
) {
  if (!class_predicate(x)) {
    cli::cli_abort(
      message = c(
        "{.arg {arg}} must be {.cls {class_name}}, not {.cls {class(x)}}.",
        "i" = "You supplied: {.obj_type_friendly {x}}"
      ),
      call = call
    )
  }
  invisible(x)
}

check_numeric <- function(
  x,
  arg = rlang::caller_arg(x),
  call = rlang::caller_env()
) {
  check_class(x, is.numeric, "numeric", arg, call)
}

check_character <- function(
  x,
  arg = rlang::caller_arg(x),
  call = rlang::caller_env()
) {
  check_class(x, is.character, "character", arg, call)
}

check_scalar <- function(
  x,
  arg = rlang::caller_arg(x),
  call = rlang::caller_env()
) {
  if (length(x) != 1) {
    cli::cli_abort(
      message = c(
        "{.arg {arg}} must be a scalar (length 1), not length {length(x)}.",
        "i" = "Did you mean to pass a single value?"
      ),
      call = call
    )
  }
  invisible(x)
}

#' @noRd
check_scalar_numeric <- function(
  x,
  arg = rlang::caller_arg(x),
  call = rlang::caller_env()
) {
  check_numeric(x, arg, call)
  check_scalar(x, arg, call)

  invisible(x)
}

check_scalar_character <- function(
  x,
  arg = rlang::caller_arg(x),
  call = rlang::caller_env()
) {
  check_character(x, arg, call)
  check_scalar(x, arg, call)
  invisible(x)
}

#' Check a scenario label
#'
#' `NULL` means "no label", and becomes `NA_character_` in the output. Anything
#' else must be a single string.
#'
#' @noRd
check_scenario_name <- function(
  x,
  arg = rlang::caller_arg(x),
  call = rlang::caller_env()
) {
  if (is.null(x)) {
    return(invisible(x))
  }

  check_scalar_character(x, arg, call)
  invisible(x)
}

#' Check scenario names
#'
#' The names become the `scenario_name` column, so every scenario needs one,
#' and two scenarios sharing a name would be indistinguishable in the output.
#' Shared by `check_scenarios()` (a list of `connectivity` objects) and
#' `check_scenario_layers()` (lists of habitat and barrier layers). `x` is the
#' names themselves, so the layer version can check both its lists at once.
#'
#' @noRd
check_scenario_names <- function(
  x,
  arg,
  call = rlang::caller_env()
) {
  unnamed <- x == ""
  if (any(unnamed)) {
    cli::cli_abort(
      c(
        "Every scenario in {.arg {arg}} must be named.",
        "x" = "No name at position {.val {which(unnamed)}}.",
        "i" = "Names become the {.field scenario_name} column."
      ),
      call = call
    )
  }

  duplicates <- unique(x[duplicated(x)])
  if (length(duplicates) > 0) {
    cli::cli_abort(
      c(
        "Scenario names in {.arg {arg}} must be unique.",
        "x" = "Duplicated: {.val {duplicates}}."
      ),
      call = call
    )
  }

  invisible(x)
}

#' Check a named list of `connectivity` scenarios
#'
#' Checking the elements here, rather than leaving it to
#' `compare_connectivity()`, means the error can say which scenario is at
#' fault.
#'
#' @noRd
check_scenarios <- function(
  x,
  arg = rlang::caller_arg(x),
  call = rlang::caller_env()
) {
  check_scenario_list(x, arg = arg, call = call)

  if (length(x) == 0) {
    cli::cli_abort(
      "{.arg {arg}} must contain at least one {.cls connectivity} object.",
      call = call
    )
  }

  scenario_names <- rlang::names2(x)
  check_scenario_names(scenario_names, arg = arg, call = call)

  is_connectivity <- purrr::map_lgl(x, inherits, "connectivity")
  if (!all(is_connectivity)) {
    cli::cli_abort(
      c(
        "Every scenario in {.arg {arg}} must be a {.cls connectivity} object.",
        "x" = "Not connectivity: {.val {scenario_names[!is_connectivity]}}."
      ),
      call = call
    )
  }

  invisible(x)
}

#' Check one scenario layer argument
#'
#' A list, or `NULL` for "none supplied". A single layer passed bare is the
#' likely mistake, so the message says how to wrap it.
#'
#' @noRd
check_scenario_list <- function(
  x,
  arg,
  call = rlang::caller_env()
) {
  if (is.null(x) || is.list(x)) {
    return(invisible(x))
  }

  cli::cli_abort(
    c(
      "{.arg {arg}} must be a named list, one element per scenario.",
      "i" = "You supplied: {.obj_type_friendly {x}}.",
      "i" = "For a single scenario: {.code {arg} = list(\"name\" = x)}."
    ),
    call = call
  )
}

#' Check the two scenario layer lists
#'
#' At least one list must be supplied, and names must be unique across both,
#' since a name identifies a scenario in the output whichever layer it changed.
#'
#' @noRd
check_scenario_layers <- function(
  habitat_scenarios,
  barrier_scenarios,
  call = rlang::caller_env()
) {
  # Check each argument before combining them: c() on a SpatRaster binds layers
  # rather than erroring, so a bare layer passed instead of a list would
  # otherwise pass every check below and be labelled with its terra layer name.
  check_scenario_list(habitat_scenarios, arg = "habitat_scenarios", call = call)
  check_scenario_list(barrier_scenarios, arg = "barrier_scenarios", call = call)

  if (length(habitat_scenarios) + length(barrier_scenarios) == 0) {
    cli::cli_abort(
      c(
        "Supply {.arg habitat_scenarios}, {.arg barrier_scenarios}, or both.",
        "i" = "Each is a named list of layers, one element per scenario."
      ),
      call = call
    )
  }

  # each list by its own name, so the message points at the right argument
  check_scenario_names(
    rlang::names2(habitat_scenarios),
    arg = "habitat_scenarios",
    call = call
  )
  check_scenario_names(
    rlang::names2(barrier_scenarios),
    arg = "barrier_scenarios",
    call = call
  )

  used_twice <- intersect(names(habitat_scenarios), names(barrier_scenarios))
  if (length(used_twice) > 0) {
    cli::cli_abort(
      c(
        "Scenario names must be unique across {.arg habitat_scenarios} and
         {.arg barrier_scenarios}.",
        "x" = "Used in both: {.val {used_twice}}."
      ),
      call = call
    )
  }

  invisible(NULL)
}

#' @noRd
check_report_data <- function(
  x,
  arg = rlang::caller_arg(x),
  call = rlang::caller_env()
) {
  if (!inherits(x, "connectivity_report_data")) {
    cli::cli_abort(
      c(
        "{.arg {arg}} must be a {.cls connectivity_report_data} object, not
         {.cls {class(x)}}.",
        "i" = "Build one with {.fn connectivity_report_data}."
      ),
      call = call
    )
  }
  invisible(x)
}

#' @noRd
check_connectivity <- function(
  x,
  arg = rlang::caller_arg(x),
  call = rlang::caller_env()
) {
  if (!inherits(x, "connectivity")) {
    cli::cli_abort(
      "{.arg {arg}} must be a {.cls connectivity} object, not {.cls {class(x)}}.",
      call = call
    )
  }
  invisible(x)
}

make_bullets <- function(
  category,
  new,
  baseline,
  arg = "connectivity",
  arg_baseline = "connectivity_baseline"
) {
  c(
    paste0("{.strong ", category, "}"),
    "*" = paste0(arg, " = {.val ", new, "}"),
    "*" = paste0(arg_baseline, " = {.val ", baseline, "}")
  )
}

# check distance, species, and res match. `arg`/`arg_baseline` are the display
# names used in the error message, so callers (e.g. compare_connectivity()) can
# surface their own public argument names rather than the internal ones.
check_pc_match <- function(
  connectivity,
  connectivity_baseline,
  arg = "connectivity",
  arg_baseline = "connectivity_baseline",
  call = rlang::caller_env()
) {
  if (is.null(connectivity_baseline)) {
    return(invisible())
  }
  connectivity_dist <- pc_interpatch_distance(connectivity)
  baseline_dist <- pc_interpatch_distance(connectivity_baseline)
  connectivity_res <- pc_res(connectivity)
  baseline_res <- pc_res(connectivity_baseline)
  connectivity_species <- pc_species(connectivity)
  baseline_species <- pc_species(connectivity_baseline)

  dist_match <- isTRUE(all.equal(connectivity_dist, baseline_dist))
  res_match <- isTRUE(all.equal(connectivity_res, baseline_res))
  species_match <- isTRUE(all.equal(connectivity_species, baseline_species))

  if (dist_match && res_match && species_match) {
    return(invisible())
  }

  cli::cli_abort(
    message = c(
      "{.arg {arg}} and {.arg {arg_baseline}} must have the same
       resolution, species, and interpatch_distance.",
      "!" = "One or more of these do not match:",
      if (!res_match) {
        make_bullets(
          "resolution",
          connectivity_res,
          baseline_res,
          arg,
          arg_baseline
        )
      },
      if (!species_match) {
        make_bullets(
          "species",
          connectivity_species,
          baseline_species,
          arg,
          arg_baseline
        )
      },
      if (!dist_match) {
        make_bullets(
          "interpatch_distance",
          connectivity_dist,
          baseline_dist,
          arg,
          arg_baseline
        )
      }
    ),
    call = call
  )
}

#' Determine whether two spatial layers differ
#'
#' Robust equality check for spatial layers. `terra::SpatRaster` objects are
#' external pointers, so `identical()` on them is unreliable; this helper
#' branches on class to compare geometry and values appropriately.
#'
#' @param a,b spatial layers to compare (`SpatRaster`, `sf`, or `SpatVector`).
#' @return `TRUE` when the layers differ, otherwise `FALSE`. Note that a change of
#'   CRS counts as "differs" (for rasters, `terra::compareGeom()` checks the CRS;
#'   for vectors, `all.equal()` does), so reprojecting a layer reads as a change.
#' @noRd
layers_differ <- function(a, b) {
  # Different classes -> treat as differing.
  if (!identical(class(a), class(b))) {
    return(TRUE)
  }

  # terra objects: terra::identical() compares geometry, values, and CRS, and
  # treats NA cells as equal. We use it rather than all.equal(), which does not
  # detect SpatVector geometry differences. It emits a diagnostic message on a
  # mismatch (e.g. "different geometry"), so silence that.
  if (inherits(a, "SpatRaster") || inherits(a, "SpatVector")) {
    return(!suppressMessages(terra::identical(a, b)))
  }

  # sf / sfc branch: sf's all.equal() compares geometry and attributes reliably.
  !isTRUE(all.equal(a, b))
}

check_names <- function(
  x,
  name,
  arg = rlang::caller_arg(x),
  call = rlang::caller_env()
) {
  name_exists <- rlang::has_name(x, name)
  if (!name_exists) {
    cli::cli_abort(
      message = "{.arg x} must contain a {.field {name}} column.",
      call = call
    )
  }
}
