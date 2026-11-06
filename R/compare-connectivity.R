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
#'   If you have habitat and barrier rasters rather than `connectivity` objects,
#'   use [habitat_connectivity_comparison()], which runs
#'   [habitat_connectivity()] on each scenario for you and then calls this
#'   function. Put vector layers on a grid first, with [prepare_rasters()] and
#'   [onto_grid()].
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
#'   `100 * change / baseline`, which puts every metric on the same scale.
#'   The scenario's `effective_mesh_ha` and `prob_connectedness` are measured
#'   against the baseline's habitat area, so they can differ from what
#'   [habitat_connectivity()] gives the scenario on its own. Metric
#'   values are held at full precision - they are not rounded - so `change` is
#'   exact.
#' @seealso [habitat_connectivity_comparison()], which starts from habitat and
#'   barrier layers instead of `connectivity` objects,
#'   [habitat_connectivity()], and [summarise_connectivity()].
#' @export
#'
#' @examples
#' # the lizard's landscape today
#' lizard_today <- habitat_connectivity(
#'   habitat = example_habitat(),
#'   barrier = example_barrier(),
#'   species = "Blue-tongued Lizard",
#'   interpatch_distance = 20,
#'   verbose = FALSE
#' )
#'
#' lizard_today
#'
#' # and with a new road through the habitat
#' lizard_new_road <- habitat_connectivity(
#'   habitat = example_habitat(),
#'   barrier = example_barrier_scenario(),
#'   species = "Blue-tongued Lizard",
#'   interpatch_distance = 20,
#'   verbose = FALSE
#' )
#'
#' lizard_new_road
#'
#' # against today's habitat, so mesh and connectedness differ from above
#' lizard_road_comparison <- compare_connectivity(
#'   scenario = lizard_new_road,
#'   baseline = lizard_today,
#'   scenario_name = "New road"
#' )
#'
#' lizard_road_comparison
#'
#' # a row per metric, the baseline and scenario side by side
#' summary(lizard_road_comparison)
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
  # are kept at full precision so the subtraction below is exact, and rounding
  # is left to `round_by()` when they are shown.
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
#' value: `100 * change / baseline`, column-wise. This puts metrics on
#' different scales side by side.
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

#' Summarise a comparison for reading
#'
#' A `compare_connectivity` object has a column per metric, so printed in the
#'   console it hides the metrics that don't fit. `summary()` turns it round:
#'   one row per metric, with the baseline, the scenario, the change and the
#'   per cent change side by side, rounded as [connectivity_display()]
#'   describes.
#'
#' @param object A `compare_connectivity` object, from [compare_connectivity()],
#'   [compare_scenarios()], [habitat_connectivity_comparison()] or
#'   [habitat_connectivity_scenarios()].
#' @param ... Not used. Must be empty.
#'
#' @returns A `summary_compare_connectivity` object: a tibble with one row per
#'   metric for each scenario and interpatch distance. Its columns are
#'   `Scenario` (only when a scenario is named), `Distance (m)`, `Metric`,
#'   `Baseline`, `Scenario value`, `Change` and `% change`. The values are
#'   rounded but stay numeric, so they can be filtered, sorted or plotted.
#'
#'   It prints one table per scenario and interpatch distance, each under a
#'   line naming the scenario and a line giving the distance, with the
#'   scenarios in the order given and then by distance. An unnamed scenario
#'   has the distance line only. Since the heading names the scenario, the
#'   printed table heads its values "Scenario" rather than "Scenario value".
#' @seealso [compare_connectivity()], and `round_by(connectivity_display(x))`,
#'   which gives the same table as a plain tibble.
#' @export
#'
#' @examples
#' # a new road through the lizard's habitat, against the landscape today
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
#' lizard_road_summary <- summary(lizard_road_comparison)
#'
#' lizard_road_summary
#'
#' # the values are still numbers
#' lizard_road_summary[["% change"]]
summary.compare_connectivity <- function(object, ...) {
  rlang::check_dots_empty()

  rounded <- round_by(connectivity_display(object))

  tibble::new_tibble(rounded, class = "summary_compare_connectivity")
}

#' @export
print.summary_compare_connectivity <- function(x, ...) {
  spec <- connectivity_columns()
  scenario_column <- display_labels("scenario_name", spec)
  distance_column <- display_labels("interpatch_distance", spec)

  ids <- intersect(c(scenario_column, distance_column), names(x))
  values <- setdiff(names(x), ids)

  # `[` and dplyr verbs keep the class, so a summary cut down past what a
  # table needs prints as the tibble it has become
  tabulable <- nrow(x) > 0 &&
    distance_column %in% ids &&
    length(values) > 0

  if (!tabulable) {
    return(NextMethod())
  }

  plain <- tibble::as_tibble(x)

  # each heading names its scenario, so in the table its values are just
  # "Scenario" rather than "Scenario value"
  short_label <- rlang::set_names(
    display_labels("scenario", spec),
    scenario_column
  )
  shown <- dplyr::rename(plain[values], dplyr::any_of(short_label))

  tables <- vctrs::vec_split(
    x = shown,
    by = plain[ids]
  )

  # connectivity_display() drops the column when no scenario is named
  scenario_names <- tables$key[[scenario_column]] %||% NA_character_
  distance <- tables$key[[distance_column]]
  # an unnamed scenario's line is NA, and is dropped: there is nothing to name
  scenario_lines <- glue::glue(
    "{cli::style_bold('Scenario:')} {scenario_names}",
    .na = NULL
  )
  distance_lines <- glue::glue(
    "{cli::style_bold('Interpatch distance:')} {distance} m"
  )
  headings <- purrr::map2(
    scenario_lines,
    distance_lines,
    \(scenario, distance) purrr::discard(c(scenario, distance), is.na)
  )

  sections <- purrr::map2(
    headings,
    tables$val,
    \(heading, table) c(heading, summary_table_lines(table))
  )

  lines <- purrr::reduce(sections, \(above, below) c(above, "", below))
  cli::cat_line(lines)

  invisible(x)
}

#' One summary table as lines of text, numbers right-aligned
#'
#' Each value is formatted on its own, as [format_by()] does, so a tiny change
#' in one row doesn't put the whole column into scientific notation. The
#' header row is bold, as a tibble's is.
#'
#' @noRd
summary_table_lines <- function(table) {
  numeric <- names(table)[purrr::map_lgl(table, is.numeric)]
  formatted <- format_columns(table, numeric)

  columns <- purrr::imap(
    formatted,
    function(values, heading) {
      justify <- if (heading %in% numeric) "right" else "left"
      format(c(heading, values), justify = justify)
    }
  )

  rows <- purrr::reduce(columns, paste)
  header <- cli::style_bold(rows[1])
  glue::glue("  {c(header, rows[-1])}")
}
