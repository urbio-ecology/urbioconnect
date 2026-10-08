#' Everything one connectivity analysis produces
#'
#' Runs the connectivity pipeline once per distance and keeps both the summary
#'   and the spatial layers the maps need. [habitat_connectivity()] returns the
#'   summary alone; this also keeps the buffered habitat and the patch-ID
#'   raster for each distance, which is what the downloadable assets and the
#'   report are built from.
#'
#' @param habitat Terra SpatRaster. The habitat layer.
#' @param barrier Terra SpatRaster. The barrier layer.
#' @param species Species name. E.g., "Superb Fairy Wren".
#' @param interpatch_distance Numeric. The distance (in metres) at which
#'   habitat patches are considered connected. May be a scalar or a vector; a
#'   vector runs the pipeline once per distance.
#' @param scenario Optional layer to compare against the baseline: an `sf`,
#'   `SpatVector` or `SpatRaster` standing in for one of `habitat` and
#'   `barrier`. It is put on the baseline's own grid with [onto_grid()], so it
#'   does not have to arrive on one. Supplying it runs the pipeline a second
#'   time, on the scenario landscape, and fills the `scenario_*` fields and
#'   `comparison` below.
#' @param scenario_kind Which layer `scenario` replaces, `"habitat"` or
#'   `"barrier"`. Required with `scenario`. Only one layer may change at a
#'   time, so that the difference in connectivity is attributable to it.
#' @param scenario_name Optional name for the scenario, carried in the
#'   comparison so several can be stacked.
#' @param verbose Logical. Display progress messages (default: TRUE).
#'
#' @returns A `connectivity_report_data` object: a list of
#'   * `connectivity`, a `connectivity` summary with one row per distance
#'   * `habitat` and `barrier`, the layers as supplied
#'   * `buffered_habitat` and `patch_id_raster`, lists of `SpatRaster`, one per
#'     distance and named by it
#'   * `species` and `interpatch_distance`
#'
#'   and, when a `scenario` was given, the same view of the scenario
#'   landscape: `scenario_kind`, `scenario_habitat`, `scenario_barrier`,
#'   `scenario_buffered_habitat`, and `comparison`. Without one these are all
#'   `NULL`. [scenario_layer()] returns whichever layer the scenario changed.
#' @seealso [habitat_connectivity()] when only the summary is wanted, and
#'   [habitat_connectivity_comparison()] to compare two landscapes you have
#'   already assembled yourself.
#' @export
#'
#' @examples
#' \donttest{
#' report_data <- connectivity_report_data(
#'   habitat = example_wren_habitat(),
#'   barrier = example_wren_barrier(),
#'   species = "Superb Fairy Wren",
#'   interpatch_distance = 200,
#'   verbose = FALSE
#' )
#'
#' report_data$connectivity
#' names(report_data$patch_id_raster)
#'
#' # with a scenario, the baseline and the scenario are each run once and
#' # the comparison is built from the two
#' with_scenario <- connectivity_report_data(
#'   habitat = example_wren_habitat(),
#'   barrier = example_wren_barrier(),
#'   species = "Superb Fairy Wren",
#'   interpatch_distance = 200,
#'   scenario = example_wren_barrier_scenario(),
#'   scenario_kind = "barrier",
#'   verbose = FALSE
#' )
#'
#' with_scenario$comparison
#' }
connectivity_report_data <- function(
  habitat,
  barrier,
  species,
  interpatch_distance,
  scenario = NULL,
  scenario_kind = NULL,
  scenario_name = NULL,
  verbose = TRUE
) {
  check_distances(interpatch_distance)
  check_scalar_character(species)
  check_scenario_name(scenario_name)

  scenario_kind <- check_scenario_pair(scenario, scenario_kind)

  baseline <- connectivity_runs(
    habitat,
    barrier,
    species,
    interpatch_distance,
    verbose
  )

  if (is.null(scenario)) {
    return(new_connectivity_report_data(
      connectivity = baseline$connectivity,
      habitat = habitat,
      barrier = barrier,
      buffered_habitat = baseline$buffered_habitat,
      patch_id_raster = baseline$patch_id_raster,
      species = species,
      interpatch_distance = interpatch_distance
    ))
  }

  # onto the grid of the layer it stands in for, so a scenario does not have
  # to arrive already aligned, and cannot be compared against a landscape
  # somewhere else
  replaced <- if (scenario_kind == "habitat") habitat else barrier
  changed <- onto_grid(
    scenario,
    grid = replaced,
    background = if (scenario_kind == "habitat") NA else 0
  )

  if (!layers_differ(changed, replaced)) {
    cli::cli_warn(c(
      "The scenario is identical to the baseline {scenario_kind}.",
      "i" = "Every {.field change} value will be zero."
    ))
  }

  scenario_habitat <- if (scenario_kind == "habitat") changed else habitat
  scenario_barrier <- if (scenario_kind == "habitat") barrier else changed

  scenario_run <- connectivity_runs(
    scenario_habitat,
    scenario_barrier,
    species,
    interpatch_distance,
    verbose
  )

  new_connectivity_report_data(
    connectivity = baseline$connectivity,
    habitat = habitat,
    barrier = barrier,
    buffered_habitat = baseline$buffered_habitat,
    patch_id_raster = baseline$patch_id_raster,
    species = species,
    interpatch_distance = interpatch_distance,
    scenario_kind = scenario_kind,
    scenario_habitat = scenario_habitat,
    scenario_barrier = scenario_barrier,
    scenario_buffered_habitat = scenario_run$buffered_habitat,
    comparison = rows_to_comparison(
      scenario = scenario_run$connectivity,
      baseline = baseline$connectivity,
      scenario_name = scenario_name
    )
  )
}

#' Run the pipeline once per distance, and summarise each run
#'
#' `habitat_connectivity_full()` returns everything `habitat_connectivity()`
#' does and the intermediate layers besides, so one call per distance per
#' landscape is all any of this needs.
#'
#' @noRd
connectivity_runs <- function(
  habitat,
  barrier,
  species,
  interpatch_distance,
  verbose
) {
  runs <- purrr::map(interpatch_distance, function(distance) {
    habitat_connectivity_full(
      habitat = habitat,
      barrier = barrier,
      interpatch_distance = distance,
      verbose = verbose
    )
  }) |>
    rlang::set_names(as.character(interpatch_distance))

  connectivity <- purrr::map2(
    runs,
    interpatch_distance,
    function(run, interpatch_distance) {
      patch_size_tbl(
        data = run$areas_connected,
        species = species,
        interpatch_distance = interpatch_distance,
        res = terra::res(habitat)
      ) |>
        summarise_connectivity()
    }
  ) |>
    dplyr::bind_rows()

  list(
    connectivity = connectivity,
    buffered_habitat = purrr::map(runs, "buffered_habitat"),
    patch_id_raster = purrr::map(runs, "patch_id_raster")
  )
}

#' Pair up two already-computed summaries, a distance at a time
#'
#' [habitat_connectivity_comparison()] runs the pipeline to get these; here
#' they have been run already, so only the arithmetic is left.
#'
#' @noRd
rows_to_comparison <- function(scenario, baseline, scenario_name) {
  purrr::map(seq_len(nrow(baseline)), function(i) {
    compare_connectivity(
      scenario = dplyr::slice(scenario, i),
      baseline = dplyr::slice(baseline, i),
      scenario_name = scenario_name
    )
  }) |>
    dplyr::bind_rows() |>
    new_compare_connectivity()
}

#' A scenario needs to say which layer it replaces, and nothing else may
#'
#' @noRd
check_scenario_pair <- function(
  scenario,
  scenario_kind,
  call = rlang::caller_env()
) {
  if (is.null(scenario)) {
    if (!is.null(scenario_kind)) {
      cli::cli_abort(
        "{.arg scenario_kind} needs a {.arg scenario} to describe.",
        call = call
      )
    }
    return(NULL)
  }

  if (is.null(scenario_kind)) {
    cli::cli_abort(
      c(
        "{.arg scenario_kind} must say which layer {.arg scenario} replaces.",
        "i" = "Either {.val habitat} or {.val barrier}."
      ),
      call = call
    )
  }

  rlang::arg_match0(
    scenario_kind,
    c("habitat", "barrier"),
    arg_nm = "scenario_kind",
    error_call = call
  )
}

#' Save and reload a connectivity analysis
#'
#' Writes a `connectivity_report_data` object to an `.rds` file, and reads it
#'   back. The summary, the habitat and barrier layers, and the patch raster
#'   for each distance all travel together in the one file.
#'
#'   [base::saveRDS()] on its own isn't enough. A `SpatRaster` points at
#'   memory or at a file on disk rather than carrying its own values, so it
#'   saves as a null pointer and comes back unusable. [terra::wrap()] packs
#'   the values into the object on the way out, and [terra::unwrap()] restores
#'   them on the way in.
#'
#'   This is also how an analysis reaches the separate R session that Quarto
#'   renders the report in.
#'
#' @param x A `connectivity_report_data` object from
#'   [connectivity_report_data()].
#' @param path File to write to, or read from.
#'
#' @returns `write_report_data()` returns `path` invisibly;
#'   `read_report_data()` returns the `connectivity_report_data`.
#' @seealso [connectivity_report_data()]
#' @export
#'
#' @examples
#' \donttest{
#' report_data <- connectivity_report_data(
#'   habitat = example_habitat(),
#'   barrier = example_barrier(),
#'   species = "Blue Tongue Lizard",
#'   interpatch_distance = 20,
#'   verbose = FALSE
#' )
#'
#' path <- write_report_data(report_data, tempfile(fileext = ".rds"))
#' read_report_data(path)$connectivity
#' }
write_report_data <- function(x, path) {
  check_report_data(x)
  report_rasters <- map_report_rasters(x, terra::wrap)
  saveRDS(report_rasters, path)
  invisible(path)
}

#' @rdname write_report_data
#' @export
read_report_data <- function(path) {
  # checked before unwrapping, which would otherwise fail inside terra
  x <- readRDS(path)

  if (!is_report_data(x)) {
    cli::cli_abort(c(
      "{.path {basename(path)}} doesn't hold a
       {.cls connectivity_report_data} object.",
      "x" = "It holds {.obj_type_friendly {x}}.",
      "i" = "Write one with {.fn write_report_data}."
    ))
  }

  map_report_rasters(x, terra::unwrap)
}

#' Is this a `connectivity_report_data` object?
#'
#' @noRd
is_report_data <- function(x) {
  inherits(x, "connectivity_report_data")
}

#' Is there more than one distance to compare?
#'
#' A single distance is a single point, so there is nothing to plot. Asked by
#' both the manifest and the writer, so the rule has one home.
#'
#' @noRd
has_over_distance_plot <- function(x) {
  length(x$interpatch_distance) > 1
}

#' The layer a scenario changed
#'
#' An analysis carrying a scenario holds both of its landscapes, so the layer
#' that actually changed is whichever of them the scenario stood in for. Ask
#' rather than branching on `scenario_kind` at every call site.
#'
#' @param x A `connectivity_report_data`, from [connectivity_report_data()].
#'
#' @returns The scenario's `SpatRaster`, or `NULL` when there is no scenario.
#' @seealso [connectivity_report_data()], and [gg_layer()] to draw it.
#' @export
#'
#' @examples
#' \donttest{
#' analysis <- connectivity_report_data(
#'   habitat = example_wren_habitat(),
#'   barrier = example_wren_barrier(),
#'   species = "Superb Fairy Wren",
#'   interpatch_distance = 200,
#'   scenario = example_wren_barrier_scenario(),
#'   scenario_kind = "barrier",
#'   verbose = FALSE
#' )
#'
#' scenario_layer(analysis)
#' }
scenario_layer <- function(x) {
  check_report_data(x)

  if (is.null(x$scenario_kind)) {
    return(NULL)
  }

  if (x$scenario_kind == "habitat") x$scenario_habitat else x$scenario_barrier
}

#' Does this analysis carry a scenario comparison?
#'
#' Asked by the manifest and the writers, so the rule lives with the analysis
#' rather than in each of them. The report template can't: it renders in a
#' session that sees only exported functions.
#'
#' @noRd
has_comparison <- function(x) {
  !is.null(x$comparison)
}

#' Apply a function to every raster in a `connectivity_report_data`
#'
#' @noRd
map_report_rasters <- function(x, f) {
  x$habitat <- f(x$habitat)
  x$barrier <- f(x$barrier)
  x$buffered_habitat <- purrr::map(x$buffered_habitat, f)
  x$patch_id_raster <- purrr::map(x$patch_id_raster, f)
  x
}

#' Construct a `connectivity_report_data` object
#'
#' @noRd
new_connectivity_report_data <- function(
  connectivity,
  habitat,
  barrier,
  buffered_habitat,
  patch_id_raster,
  species,
  interpatch_distance,
  scenario_kind = NULL,
  scenario_habitat = NULL,
  scenario_barrier = NULL,
  scenario_buffered_habitat = NULL,
  comparison = NULL
) {
  structure(
    list(
      connectivity = connectivity,
      habitat = habitat,
      barrier = barrier,
      buffered_habitat = buffered_habitat,
      patch_id_raster = patch_id_raster,
      species = species,
      interpatch_distance = interpatch_distance,
      scenario_kind = scenario_kind,
      scenario_habitat = scenario_habitat,
      scenario_barrier = scenario_barrier,
      scenario_buffered_habitat = scenario_buffered_habitat,
      comparison = comparison
    ),
    class = "connectivity_report_data"
  )
}
