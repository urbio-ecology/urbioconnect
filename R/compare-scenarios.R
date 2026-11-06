#' Compare several scenarios against one baseline
#'
#' Where [compare_connectivity()] compares a single scenario against a
#'   baseline, this compares as many as you like, and labels each one. Give it a
#'   named list of `connectivity` objects: the names become the
#'   `scenario_name` column, so a scenario can be identified in the result.
#'
#'   If you have habitat and barrier rasters rather than `connectivity` objects,
#'   run [habitat_connectivity()] on each one first, as in the example below,
#'   or give the rasters to [habitat_connectivity_scenarios()]. Put vector
#'   layers on a grid first, with [prepare_rasters()] and [onto_grid()].
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
#' # a `connectivity` object for the baseline, the lizard's landscape today
#' lizard_today <- habitat_connectivity(
#'   habitat = example_habitat(),
#'   barrier = example_barrier(),
#'   species = "Blue-tongued Lizard",
#'   interpatch_distance = 20,
#'   verbose = FALSE
#' )
#'
#' # and one for each scenario, here a new road through the habitat
#' lizard_new_road <- habitat_connectivity(
#'   habitat = example_habitat(),
#'   barrier = example_barrier_scenario(),
#'   species = "Blue-tongued Lizard",
#'   interpatch_distance = 20,
#'   verbose = FALSE
#' )
#'
#' # each scenario is compared against the baseline and labelled by its name
#' lizard_scenarios <- compare_scenarios(
#'   baseline = lizard_today,
#'   scenarios = list("New road" = lizard_new_road)
#' )
#'
#' lizard_scenarios
#'
#' # a row per metric, the baseline and scenario side by side
#' summary(lizard_scenarios)
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
#' Each layer in `habitat_scenarios` or `barrier_scenarios` is its own scenario
#'   that changes that one layer; the lists are never combined. A habitat
#'   scenario runs against `barrier_baseline`, and a barrier scenario against
#'   `habitat_baseline`. For a scenario that changes both layers, use
#'   [habitat_connectivity_comparison()].
#'
#'   The layer-level counterpart to [compare_scenarios()]: it runs the
#'   connectivity pipeline on each scenario and compares them all against the
#'   baseline. The baseline is run once per distance and reused by every
#'   scenario, so comparing three scenarios at one distance runs the pipeline
#'   four times, not six.
#'
#'   Each scenario layer must be the whole layer after the change, on the same
#'   grid as the layer it replaces, or this gives an error: put it there with
#'   [onto_grid()].
#'
#' @param habitat_baseline Terra SpatRaster. The baseline habitat layer: the
#'   landscape as it is today.
#' @param barrier_baseline Terra SpatRaster. The baseline barrier layer.
#' @param species Species name. E.g., "Superb Fairy Wren".
#' @param interpatch_distance Numeric. The distance (in metres) at which
#'   habitat patches are considered connected. May be a scalar or a vector; a
#'   vector runs every scenario once per distance.
#' @param habitat_scenarios A named list of habitat layers, one per scenario.
#'   Names become the `scenario_name` column.
#' @param barrier_scenarios A named list of barrier layers, the mirror of
#'   `habitat_scenarios`. Give either list, or both; names must be unique
#'   across the two.
#' @inheritParams habitat_connectivity
#' @param verbose Logical. Display progress messages (default: TRUE).
#'
#' @returns A `compare_connectivity` object with four rows per scenario per
#'   distance, labelled in the `scenario_name` column. Habitat scenarios come
#'   first, then barrier scenarios, in the order given.
#' @seealso [compare_scenarios()] when you already have `connectivity` objects,
#'   [habitat_connectivity_comparison()] for one scenario, including one that
#'   changes both layers, and `vignette("scenario-comparison")`.
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
#'   interpatch_distance = 200,
#'   habitat_scenarios = list(
#'     "Bentley Project" = example_wren_habitat_scenario()
#'   ),
#'   barrier_scenarios = list(
#'     "Barrier upgrade" = example_wren_barrier_scenario()
#'   ),
#'   verbose = FALSE
#' )
#' }
habitat_connectivity_scenarios <- function(
  habitat_baseline,
  barrier_baseline,
  species,
  interpatch_distance,
  habitat_scenarios = NULL,
  barrier_scenarios = NULL,
  directions = 4,
  verbose = TRUE
) {
  check_distances(interpatch_distance)
  check_directions(directions)
  check_scenario_layers(habitat_scenarios, barrier_scenarios)
  check_scenario_grids(habitat_scenarios, habitat_baseline)
  check_scenario_grids(barrier_scenarios, barrier_baseline)

  # Each scenario swaps exactly one layer; the other comes from the baseline.
  # Pairing them up here means the sweep below doesn't care which kind it has.
  scenario_layers <- c(
    purrr::map(habitat_scenarios, function(habitat_scenario) {
      list(habitat = habitat_scenario, barrier = barrier_baseline)
    }),
    purrr::map(barrier_scenarios, function(barrier_scenario) {
      list(habitat = habitat_baseline, barrier = barrier_scenario)
    })
  )

  warn_unchanged_scenarios(
    habitat_scenarios,
    barrier_scenarios,
    habitat_baseline,
    barrier_baseline
  )

  comparisons <- purrr::map(interpatch_distance, function(distance) {
    # Computed once per distance, then reused by every scenario below.
    base_conn <- connectivity_at_distance(
      habitat_baseline,
      barrier_baseline,
      species,
      distance,
      directions,
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
        directions,
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
    purrr::map_lgl(
      habitat_scenarios,
      \(x) !layers_differ(x, habitat_baseline)
    ),
    purrr::map_lgl(
      barrier_scenarios,
      \(x) !layers_differ(x, barrier_baseline)
    )
  )

  if (any(unchanged)) {
    cli::cli_warn(
      c(
        "Scenarios identical to the baseline: {.val {names(unchanged)[unchanged]}}.",
        "i" = "Every {.field change} value will be zero for them."
      )
    )
  }
}
