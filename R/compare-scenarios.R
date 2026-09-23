#' Compare several scenarios against one baseline
#'
#' Where [compare_connectivity()] compares a single scenario against a
#'   baseline, this compares as many as you like, and labels each one. Give it a
#'   named list of `connectivity` objects: the names become the
#'   `scenario_name` column, so a scenario can be identified in the result.
#'
#'   If you have raster or vector layers rather than `connectivity` objects,
#'   run [habitat_connectivity()] on each one first, as in the second example
#'   below.
#'
#' @param baseline A `connectivity` object (from [habitat_connectivity()] or
#'   [summarise_connectivity()]) that every scenario is compared against. Must
#'   be a single row.
#' @param scenarios A named list of `connectivity` objects, one per scenario.
#'   Names must be present and unique, and each scenario must match `baseline`
#'   on species, interpatch_distance, and resolution.
#'
#' @returns A `compare_connectivity` object with four rows per scenario
#'   (`baseline`, `scenario`, `change`, `pct_change`), labelled in the
#'   `scenario_name` column. See [compare_connectivity()] for the columns.
#' @seealso [compare_connectivity()] for a single scenario, and
#'   [habitat_connectivity_comparison()], which starts from habitat and barrier
#'   layers instead of `connectivity` objects.
#' @export
#'
#' @examples
#' baseline <- summarise_connectivity(lizard_areas_connected)
#'
#' compare_scenarios(
#'   baseline = baseline,
#'   scenarios = list(
#'     "Bentley Project" = summarise_connectivity(lizard_areas_connected[-1, ]),
#'     "Barrier upgrade" = summarise_connectivity(
#'       lizard_areas_connected[-(1:5), ]
#'     )
#'   )
#' )
#'
#' \donttest{
#' # starting from layers: build a `connectivity` object for each first
#' wren_habitat <- example_wren_habitat()
#' wren_barrier <- example_wren_barrier()
#'
#' wren_baseline <- habitat_connectivity(
#'   habitat = wren_habitat,
#'   barrier = wren_barrier,
#'   species = "Superb Fairy Wren",
#'   interpatch_distance = 200,
#'   verbose = FALSE
#' )
#'
#' bentley_project <- habitat_connectivity(
#'   habitat = example_wren_habitat_scenario(),
#'   barrier = wren_barrier,
#'   species = "Superb Fairy Wren",
#'   interpatch_distance = 200,
#'   verbose = FALSE
#' )
#'
#' compare_scenarios(
#'   baseline = wren_baseline,
#'   scenarios = list("Bentley Project" = bentley_project)
#' )
#' }
compare_scenarios <- function(baseline, scenarios) {
  check_connectivity(baseline)
  check_scenarios(scenarios)

  # imap passes each scenario's name as the label
  comparisons <- purrr::imap(
    scenarios,
    function(scenario, scenario_name) {
      compare_connectivity(
        scenario = scenario,
        baseline = baseline,
        scenario_name = scenario_name
      )
    }
  )

  new_compare_connectivity(dplyr::bind_rows(comparisons))
}

#' Compare several scenarios against one baseline, starting from layers
#'
#' The layer-level counterpart to [compare_scenarios()]. Give it one baseline
#'   habitat/barrier pair and named lists of scenario layers, and it runs the
#'   connectivity pipeline on each and compares them all against that baseline.
#'
#'   A scenario changes exactly one layer: habitat scenarios are run against
#'   the baseline barrier, and barrier scenarios against the baseline habitat.
#'   There's no way to write a scenario that changes both, which is what
#'   [habitat_connectivity_comparison()] has to check for.
#'
#'   The baseline is run once per distance and reused by every scenario, so
#'   comparing three scenarios at one distance runs the pipeline four times,
#'   not six.
#'
#' @param habitat_baseline Terra SpatRaster. The baseline habitat layer.
#' @param barrier_baseline Terra SpatRaster. The baseline barrier layer.
#' @param species Species name. E.g., "Superb Fairy Wren".
#' @param habitat_scenarios A named list of habitat layers, one per scenario,
#'   each compared against `habitat_baseline` with the barrier held at
#'   `barrier_baseline`. Names become the `scenario_name` column.
#' @param barrier_scenarios A named list of barrier layers, the mirror of
#'   `habitat_scenarios`. Supply either list, or both; names must be unique
#'   across the two.
#' @param interpatch_distance Numeric. The distance (in metres) at which
#'   habitat patches are considered connected. May be a scalar or a vector; a
#'   vector runs every scenario once per distance. Provide exactly one of
#'   `interpatch_distance` or `buffer_radius`.
#' @param buffer_radius Numeric. The radius in metres around the habitat, an
#'   alternative to `interpatch_distance`.
#' @param verbose Logical. Display progress messages (default: TRUE).
#'
#' @returns A `compare_connectivity` object with four rows per scenario per
#'   distance, labelled in the `scenario_name` column. Habitat scenarios come
#'   first, then barrier scenarios, in the order given.
#' @seealso [compare_scenarios()] when you already have `connectivity` objects,
#'   and [habitat_connectivity_comparison()] for a single scenario.
#' @export
#'
#' @examples
#' \donttest{
#' wren_habitat <- example_wren_habitat()
#' wren_barrier <- example_wren_barrier()
#'
#' habitat_connectivity_scenarios(
#'   habitat_baseline = wren_habitat,
#'   barrier_baseline = wren_barrier,
#'   species = "Superb Fairy Wren",
#'   habitat_scenarios = list(
#'     "Bentley Project" = example_wren_habitat_scenario()
#'   ),
#'   barrier_scenarios = list(
#'     "Barrier upgrade" = example_wren_barrier_scenario()
#'   ),
#'   interpatch_distance = 200,
#'   verbose = FALSE
#' )
#' }
habitat_connectivity_scenarios <- function(
  habitat_baseline,
  barrier_baseline,
  species,
  habitat_scenarios = NULL,
  barrier_scenarios = NULL,
  interpatch_distance = NULL,
  buffer_radius = NULL,
  verbose = TRUE
) {
  supplied <- check_distance_arg(
    interpatch_distance,
    buffer_radius,
    require_length = TRUE
  )
  check_scenario_layers(habitat_scenarios, barrier_scenarios)

  # Each scenario swaps exactly one layer; the other comes from the baseline.
  # Pairing them up here means the sweep below doesn't care which kind it has.
  scenario_layers <- c(
    purrr::map(
      habitat_scenarios,
      \(habitat) list(habitat = habitat, barrier = barrier_baseline)
    ),
    purrr::map(
      barrier_scenarios,
      \(barrier) list(habitat = habitat_baseline, barrier = barrier)
    )
  )

  warn_unchanged_scenarios(
    habitat_scenarios,
    barrier_scenarios,
    habitat_baseline,
    barrier_baseline
  )

  distances <- distance_values(supplied, interpatch_distance, buffer_radius)

  comparisons <- purrr::map(distances, function(distance) {
    # Computed once per distance, then reused by every scenario below.
    base_conn <- connectivity_at_distance(
      habitat_baseline,
      barrier_baseline,
      species,
      distance,
      supplied,
      verbose
    )

    # map() keeps the names, so compare_scenarios() does the labelling and
    # stacking rather than this function repeating it
    scenario_connectivity <- purrr::map(scenario_layers, function(layers) {
      connectivity_at_distance(
        layers$habitat,
        layers$barrier,
        species,
        distance,
        supplied,
        verbose
      )
    })

    compare_scenarios(baseline = base_conn, scenarios = scenario_connectivity)
  })

  new_compare_connectivity(dplyr::bind_rows(comparisons))
}

#' Warn about scenarios identical to their baseline layer
#'
#' The comparison is still valid, but every `change` value will be zero, which
#' is worth saying out loud rather than leaving the user to notice.
#'
#' @noRd
warn_unchanged_scenarios <- function(
  habitat_scenarios,
  barrier_scenarios,
  habitat_baseline,
  barrier_baseline
) {
  unchanged <- c(
    purrr::map_lgl(habitat_scenarios, \(x) !layers_differ(x, habitat_baseline)),
    purrr::map_lgl(barrier_scenarios, \(x) !layers_differ(x, barrier_baseline))
  )

  if (!any(unchanged)) {
    return(invisible(NULL))
  }

  cli::cli_warn(
    c(
      "Scenarios identical to the baseline: {.val {names(unchanged)[unchanged]}}.",
      "i" = "Every {.field change} value will be zero for them."
    )
  )
}
