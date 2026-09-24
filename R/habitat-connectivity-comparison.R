#' Compare habitat connectivity of a scenario against a baseline
#'
#' Starts from habitat and barrier layers, rather than the `connectivity`
#'   objects [compare_connectivity()] takes. Give it a scenario
#'   habitat/barrier pair and a baseline habitat/barrier pair and it runs the
#'   full connectivity pipeline on each (via [habitat_connectivity()]) and
#'   compares them. Provide either an `interpatch_distance` or a `buffer_radius`
#'   (as with [habitat_connectivity()]); `interpatch_distance` may be a vector,
#'   in which case the comparison is run once per distance and the per-distance
#'   results are stacked.
#'
#' @details
#' Change exactly one layer between baseline and scenario so the difference is
#'   attributable to a single variable. To assess a barrier change, pass the
#'   same habitat to both `habitat_baseline` and `habitat_scenario`; to assess a
#'   habitat change, pass the same barrier to both `barrier_baseline` and
#'   `barrier_scenario`. If both the habitat *and* the barrier differ the
#'   function aborts; if neither differs it warns (the scenario equals the
#'   baseline, so every `change` value is zero).
#'
#'   Note that this runs the full connectivity pipeline `2 *
#'   length(interpatch_distance)` times (buffering is the slow step), so a long
#'   vector of distances will take proportionally longer.
#'
#' @param habitat_scenario Terra SpatRaster. The scenario habitat layer.
#' @param barrier_scenario Terra SpatRaster. The scenario barrier layer.
#' @param habitat_baseline Terra SpatRaster. The baseline habitat layer.
#' @param barrier_baseline Terra SpatRaster. The baseline barrier layer.
#' @param species Species name. E.g., "Superb Fairy Wren".
#' @param interpatch_distance Numeric. The distance (in metres) at which habitat
#'   patches are considered connected. May be a scalar or a vector; a vector
#'   runs the comparison once per distance. Provide exactly one of
#'   `interpatch_distance` or `buffer_radius`. See [habitat_connectivity()] for
#'   the interpatch distance / buffer radius relationship.
#' @param buffer_radius Numeric. The radius in metres around the habitat, an
#'   alternative to `interpatch_distance`. Provide exactly one of
#'   `interpatch_distance` or `buffer_radius`. See [habitat_connectivity()].
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
#' @seealso [compare_connectivity()], [habitat_connectivity()]
#' @export
#'
#' @examples
#' \donttest{
#' habitat_connectivity_comparison(
#'   habitat_scenario = example_wren_habitat(),
#'   barrier_scenario = example_wren_barrier_scenario(),
#'   habitat_baseline = example_wren_habitat(),
#'   barrier_baseline = example_wren_barrier(),
#'   species = "Superb Fairy Wren",
#'   interpatch_distance = 200,
#'   verbose = FALSE
#' )
#' }
habitat_connectivity_comparison <- function(
  habitat_scenario,
  barrier_scenario,
  habitat_baseline,
  barrier_baseline,
  species,
  interpatch_distance = NULL,
  buffer_radius = NULL,
  scenario_name = NULL,
  verbose = TRUE
) {
  check_scenario_name(scenario_name)

  # Require exactly one of interpatch_distance / buffer_radius (length-aware, so
  # numeric(0) counts as "not supplied"). Shared with resolve_buffer_radius().
  # The return value names whichever argument was supplied, which the sweep
  # below uses to pass it back to habitat_connectivity() under that same name.
  supplied <- check_distance_arg(
    interpatch_distance,
    buffer_radius,
    require_length = TRUE
  )

  # One variable at a time: compute both layer differences once, then guard.
  hab_diff <- layers_differ(habitat_scenario, habitat_baseline)
  bar_diff <- layers_differ(barrier_scenario, barrier_baseline)

  # Both-changed guard: only one variable may change at a time so the
  # difference is attributable to a single layer.
  if (hab_diff && bar_diff) {
    cli::cli_abort(
      c(
        "Both habitat and barrier differ from baseline.",
        "i" = "Change only one at a time so the difference is attributable."
      )
    )
  }

  # Identical-inputs warning: the scenario matches the baseline, so the
  # comparison is valid but every `change` value will be zero.
  scenario_is_baseline <- !hab_diff && !bar_diff

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
  distances <- distance_values(supplied, interpatch_distance, buffer_radius)

  comparisons <- purrr::map(distances, function(distance) {
    base_conn <- connectivity_at_distance(
      habitat_baseline,
      barrier_baseline,
      species,
      distance,
      supplied,
      verbose
    )
    # identical layers give an identical result, so don't run the pipeline
    # (~5s on a real landscape) a second time to produce it
    scen_conn <- if (scenario_is_baseline) {
      base_conn
    } else {
      connectivity_at_distance(
        habitat_scenario,
        barrier_scenario,
        species,
        distance,
        supplied,
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
