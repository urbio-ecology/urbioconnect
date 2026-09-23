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
