#' Compare habitat connectivity of a scenario against a baseline
#'
#' Starts from habitat and barrier layers, rather than the `connectivity`
#'   objects [compare_connectivity()] takes. Give it the baseline's habitat and
#'   barrier, and the layers a planned change replaces, and it runs the full
#'   connectivity pipeline (via [habitat_connectivity()]) on the baseline and
#'   on the scenario and compares them. `interpatch_distance` may be a vector,
#'   in which case the comparison is run once per distance and the
#'   per-distance results are stacked.
#'
#' @details
#' A scenario is the landscape after a planned change. Give the layers the plan
#' changes, and the function takes the rest from the baseline:
#'
#' | You give | The scenario's habitat | The scenario's barrier |
#' |---|---|---|
#' | `habitat_scenario` | `habitat_scenario` | `barrier_baseline` |
#' | `barrier_scenario` | `habitat_baseline` | `barrier_scenario` |
#' | both | `habitat_scenario` | `barrier_scenario` |
#'
#' Each layer you give must be the whole layer after the change, not just the
#' part that changes: a barrier scenario holding only a new road drops every
#' existing road. If you give both, the comparison shows their combined effect,
#' not how much came from each; to see each one's share, run it again with one
#' layer at a time. The shares won't add up exactly, because changes interact: a
#' new road beside new habitat matters more than either alone.
#'
#' A scenario layer must be on the same grid as the layer it replaces, or this
#' gives an error: put it there with [onto_grid()]. A scenario identical to the
#' baseline gives a warning, since every `change` value will be zero.
#'
#' This runs the full connectivity pipeline `2 * length(interpatch_distance)`
#' times (buffering is the slow step), so a long vector of distances will take
#' proportionally longer.
#'
#' @param habitat_baseline Terra SpatRaster. The baseline habitat layer: the
#'   landscape as it is today.
#' @param barrier_baseline Terra SpatRaster. The baseline barrier layer.
#' @param species Species name. E.g., "Superb Fairy Wren".
#' @param interpatch_distance Numeric. The distance (in metres) at which habitat
#'   patches are considered connected. May be a scalar or a vector; a vector
#'   runs the comparison once per distance. See [habitat_connectivity()].
#' @param habitat_scenario Terra SpatRaster, or `NULL`. The whole habitat layer
#'   after the planned change, on the same grid as `habitat_baseline`.
#' @param barrier_scenario Terra SpatRaster, or `NULL`. The whole barrier layer
#'   after the planned change, on the same grid as `barrier_baseline`.
#' @inheritParams habitat_connectivity
#' @param scenario_name Character. An optional label for the scenario, for
#'   example "Bentley Project". Passed to [compare_connectivity()], and appears
#'   in the `scenario_name` column on every row. Defaults to `NULL`, which
#'   gives `NA`.
#' @param verbose Logical. Display progress messages (default: TRUE).
#'
#' @returns A `compare_connectivity` object: a tibble with four rows
#'   (`baseline`, `scenario`, `change`, `pct_change`) per interpatch distance. A
#'   scalar `interpatch_distance` gives four rows; a length-3 vector gives
#'   twelve rows (four per distance). See [compare_connectivity()] for the
#'   columns.
#' @seealso [habitat_connectivity_scenarios()] for several scenarios at once,
#'   [compare_connectivity()], [habitat_connectivity()], and
#'   `vignette("scenario-comparison")`.
#' @export
#'
#' @examples
#' # a new road changes the barrier; the habitat stays as it is today
#' lizard_road_comparison <- habitat_connectivity_comparison(
#'   habitat_baseline = example_habitat(),
#'   barrier_baseline = example_barrier(),
#'   species = "Blue-tongued Lizard",
#'   interpatch_distance = 20,
#'   barrier_scenario = example_barrier_scenario(),
#'   scenario_name = "New road",
#'   verbose = FALSE
#' )
#'
#' lizard_road_comparison
#'
#' # a row per metric, the baseline and scenario side by side
#' summary(lizard_road_comparison)
habitat_connectivity_comparison <- function(
  habitat_baseline,
  barrier_baseline,
  species,
  interpatch_distance,
  habitat_scenario = NULL,
  barrier_scenario = NULL,
  scenario_name = NULL,
  directions = 4,
  verbose = TRUE
) {
  check_scenario_name(scenario_name)
  check_distances(interpatch_distance)
  check_directions(directions)
  check_scenario_given(habitat_scenario, barrier_scenario)

  # Before anything is computed: layers on different grids compare as a change
  # of place, and the result looks like an answer.
  check_layers_comparable(habitat_scenario, habitat_baseline)
  check_layers_comparable(barrier_scenario, barrier_baseline)

  scenario_habitat <- habitat_scenario %||% habitat_baseline
  scenario_barrier <- barrier_scenario %||% barrier_baseline

  scenario_is_baseline <- !layers_differ(scenario_habitat, habitat_baseline) &&
    !layers_differ(scenario_barrier, barrier_baseline)

  if (scenario_is_baseline) {
    cli::cli_warn(
      c(
        "The scenario is identical to the baseline.",
        "i" = "Every {.field change} value will be zero."
      )
    )
  }

  # Distance sweep. Written as a plain purrr::map() (no for loop) so it can
  # later swap to a parallel backend without restructuring. Each inner call
  # gets a scalar, so habitat_connectivity() validates it as usual.
  comparisons <- purrr::map(interpatch_distance, function(distance) {
    base_conn <- connectivity_at_distance(
      habitat_baseline,
      barrier_baseline,
      species,
      distance,
      directions,
      verbose
    )
    # identical layers give an identical result, so don't run the pipeline
    # (~5s on a real landscape) a second time to produce it
    scen_conn <- if (scenario_is_baseline) {
      base_conn
    } else {
      connectivity_at_distance(
        scenario_habitat,
        scenario_barrier,
        species,
        distance,
        directions,
        verbose
      )
    }

    compare_connectivity(
      scenario = scen_conn,
      baseline = base_conn,
      scenario_name = scenario_name
    )
  })

  new_compare_connectivity(dplyr::bind_rows(comparisons))
}
