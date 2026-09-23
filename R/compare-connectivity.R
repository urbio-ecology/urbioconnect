#' Compare the connectivity of two scenarios
#'
#' We can measure the connectivity of a given habitat and barrier with
#'   [habitat_connectivity()]. We can also compare the connectivity, say for
#'   example if you have the same area habitat and barrier, but you want to
#'   understand what the change in connectedness is when you remove, or add
#'   some habitat, or some barrier(s). This function helps you do that, by
#'   comparing a "scenario" `connectivity` object against a "baseline"
#'   `connectivity` object (both created by [habitat_connectivity()] or
#'   [summarise_connectivity()]).
#'
#'   If you have raster or vector layers rather than `connectivity` objects, use
#'   [habitat_connectivity_comparison()], which runs [habitat_connectivity()] on
#'   each scenario for you and then calls this function.
#'
#' @param scenario A `connectivity` object (from [habitat_connectivity()] or
#'   [summarise_connectivity()]). The scenario to compare against `baseline`.
#'   Must be a single row.
#' @param baseline A `connectivity` object (from [habitat_connectivity()] or
#'   [summarise_connectivity()]). The reference the `scenario` is compared
#'   against. Must be a single row, and match `scenario` on species,
#'   interpatch_distance, and resolution.
#' @param scenario_name Character. An optional label for the scenario, for
#'   example "Bentley Project". Appears in the `scenario_name` column on every
#'   row. Defaults to `NULL`, which gives `NA`.
#'
#' @returns A `compare_connectivity` object: a tibble with four rows
#'   (`baseline`, `scenario`, `change`, `pct_change`, in the `measure` column)
#'   and the same metric columns as [summarise_connectivity()] output:
#'   `scenario_name`, `measure`, `species`, `interpatch_distance`, `n_patches`,
#'   `effective_mesh_ha`, `prob_connectedness`, `patch_area_mean`,
#'   `patch_area_total_ha`, and `data_resolution`. The `change` row is
#'   `scenario - baseline`, so a positive value means the scenario is higher
#'   than the baseline; the `pct_change` row expresses that same change as
#'   `100 * change / baseline`, which is the readable form for metrics whose
#'   absolute deltas are very small. Metric values are held at full precision —
#'   they are not rounded — so `change` is exact.
#' @seealso [habitat_connectivity_comparison()], which starts from habitat and
#'   barrier layers instead of `connectivity` objects,
#'   [habitat_connectivity()], and [summarise_connectivity()].
#' @export
#'
#' @examples
#' # build `connectivity` objects cheaply (no spatial pipeline) and compare them
#' baseline <- summarise_connectivity(lizard_areas_connected)
#' # a scenario in which one connected patch (the first row) is lost
#' scenario <- summarise_connectivity(lizard_areas_connected[-1, ])
#' compare_connectivity(scenario = scenario, baseline = baseline)
#'
#' # label the scenario so it can be told apart from others
#' compare_connectivity(
#'   scenario = scenario,
#'   baseline = baseline,
#'   scenario_name = "Bentley Project"
#' )
compare_connectivity <- function(scenario, baseline, scenario_name = NULL) {
  check_connectivity(scenario)
  check_connectivity(baseline)
  check_scenario_name(scenario_name)

  if (!(nrow(scenario) == 1L && nrow(baseline) == 1L)) {
    cli::cli_abort(
      c(
        "{.arg scenario} and {.arg baseline} must each be a single-row
         {.cls connectivity} object.",
        "i" = "{.arg scenario} has {nrow(scenario)} row{?s};
               {.arg baseline} has {nrow(baseline)} row{?s}."
      )
    )
  }

  scen_pst <- patch_sizes(scenario)[[1]]
  base_pst <- patch_sizes(baseline)[[1]]

  check_pc_match(
    scen_pst,
    base_pst,
    arg = "scenario",
    arg_baseline = "baseline"
  )

  scen_area <- scen_pst$area
  base_area <- base_pst$area

  # Each row's metrics use the baseline's total area as the shared reference
  # denominator, which makes `change` a valid apples-to-apples delta. The rows
  # are kept at full precision so the subtraction below is exact; rounding is a
  # display concern, handled in print.compare_connectivity().
  baseline_row <- connectivity_metric_row(
    area = base_area,
    area_baseline = base_area
  )
  scenario_row <- connectivity_metric_row(
    area = scen_area,
    area_baseline = base_area
  )
  # column-wise subtraction; positive = scenario higher than baseline
  change_row <- scenario_row - baseline_row
  pct_row <- pct_change_row(change_row, baseline_row)

  species <- scenario$species
  interpatch_distance <- scenario$interpatch_distance
  data_resolution <- scenario$data_resolution

  results <- dplyr::bind_rows(
    baseline = baseline_row,
    scenario = scenario_row,
    change = change_row,
    pct_change = pct_row,
    .id = "measure"
  ) |>
    dplyr::mutate(
      # NULL becomes NA so the column is always present, and labelled and
      # unlabelled comparisons stack without any reshaping
      scenario_name = scenario_name %||% NA_character_,
      species = species,
      interpatch_distance = interpatch_distance,
      data_resolution = data_resolution
    ) |>
    dplyr::relocate(
      scenario_name,
      measure,
      species,
      interpatch_distance,
      n_patches,
      effective_mesh_ha,
      prob_connectedness,
      patch_area_mean,
      patch_area_total_ha,
      data_resolution
    )

  new_compare_connectivity(results)
}

#' Build the `pct_change` row
#'
#' Expresses each metric's absolute change as a percentage of its baseline
#' value: `100 * change / baseline`, column-wise. This is the readable form of
#' the change for metrics whose absolute deltas are tiny —
#' `prob_connectedness` moves by around 1e-08, which reads as nothing, but the
#' same move is a legible -0.29%.
#'
#' A zero baseline yields `NA` rather than `Inf` or `NaN`, since a percentage of
#' nothing has no meaning.
#'
#' @param change_row,baseline_row One-row tibbles of metrics with identical
#'   columns, as built by `connectivity_metric_row()`.
#' @returns A one-row tibble of percentages.
#' @noRd
pct_change_row <- function(change_row, baseline_row) {
  purrr::map2(
    change_row,
    baseline_row,
    \(change, baseline) {
      dplyr::if_else(baseline == 0, NA_real_, 100 * change / baseline)
    }
  ) |>
    tibble::as_tibble()
}

#' Construct a `compare_connectivity` object
#'
#' Internal constructor shared by `compare_connectivity()` and
#' `habitat_connectivity_comparison()`. Applies the class idempotently, so it is
#' safe to call on a tibble that `dplyr::bind_rows()` has already carried the
#' class through (as happens when stacking per-distance comparisons).
#'
#' @param x A tibble of comparison rows.
#' @returns A `compare_connectivity` object.
#' @noRd
new_compare_connectivity <- function(x) {
  if (!inherits(x, "compare_connectivity")) {
    class(x) <- c("compare_connectivity", class(x))
  }
  x
}

#' @export
print.compare_connectivity <- function(x, ...) {
  cat("# Connectivity comparison: baseline / scenario / change / pct_change\n")
  # print as a plain tibble with every column visible (as_tibble drops the
  # compare_connectivity class, avoiding infinite recursion)
  print(tibble::as_tibble(x), width = Inf, ...)
  cat("# change = scenario - baseline (positive = scenario is higher)\n")
  cat("# pct_change = 100 * change / baseline\n")
  invisible(x)
}
