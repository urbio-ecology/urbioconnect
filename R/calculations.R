#' Calculate effective mesh size
#'
#' Computes the effective mesh size metric for habitat connectivity. This is
#'   the expected area of habitat reachable from a randomly chosen point in
#'   habitat without crossing a barrier. Intended for usage from objects
#'   created by [habitat_connectivity()]. See examples below.
#'
#' @param area Numeric vector. Area of each connected patch, in square metres.
#' @param area_baseline Optional. Defaults to `area` if not specified.
#'   Numeric vector of the baseline's connected patch areas, in square metres.
#'   This is to allow for comparing the effective mesh size when comparing
#'   different scenarios.
#'
#' @returns Numeric. Effective mesh size, in hectares.
#'
#' @examples
#' effective_mesh_size(lizard_areas_connected$area)
#' @export
effective_mesh_size <- function(area, area_baseline = area) {
  effective_mesh <- sum(area^2) / sum(area_baseline)
  effective_mesh_ha <- effective_mesh * 0.0001
  effective_mesh_ha
}

#' Calculate mean patch size
#'
#' This is just a wrapper around `mean()`, however it is written to clearly
#'   identify it's usage in the context of the area data. Intended for usage
#'   from objects created by [habitat_connectivity()]. See examples below.
#'
#' @param area Numeric vector. Area of a connected patch.
#' @param ... extra arguments to pass to `mean()`.
#'
#' @returns Numeric. Mean patch size.
#' @examples
#' mean_patch_size(lizard_areas_connected$area)
#' @export
mean_patch_size <- function(area, ...) {
  mean_size <- mean(area, ...)
  mean_size
}

#' Count number of habitat patches
#'
#' Identify the number of habitat patches. A wrapper around `length()`, but
#'   named to establish its context. Intended for usage from objects created by
#'   [habitat_connectivity()]. See examples below.
#'
#' @param area Numeric vector. Area of a connected patch.
#'
#' @returns Integer. Number of patches.
#' @examples
#' n_patches(lizard_areas_connected$area)
#' @export
n_patches <- function(area) {
  n_areas <- length(area)
  n_areas
}

#' Calculate total habitat area
#'
#' Calculate the total habitat area in hectares. A wrapper around summing the
#'   area and multiplying by 0.0001 to give the units in hectares. Intended
#'   for usage from objects created by [habitat_connectivity()]. See examples
#'   below.
#'
#' @param area Numeric vector. Area of each connected patch, in square metres.
#'
#' @returns Numeric. Total habitat area in hectares.
#' @examples
#' total_habitat_area(lizard_areas_connected$area)
#' @export
total_habitat_area <- function(area) {
  total <- sum(area)
  total_hectares <- total * 0.0001
  total_hectares
}

#' Calculate connectivity probability
#'
#' Computes the probability that two randomly chosen points within habitat are
#' connected, accounting for fragmentation. This is the effective mesh size
#' divided by the total habitat area, both in hectares.
#'
#' To compare a design scenario against a baseline, pass the scenario's
#' effective mesh size, measured against the baseline areas, and the
#' baseline's total habitat area. A scenario that adds habitat can then score
#' above 1.
#'
#' @param effective_mesh_ha Number. Effective mesh size in hectares, as
#'   returned by [effective_mesh_size()].
#' @param area_baseline_ha Number. Total habitat area of the baseline landscape
#'   in hectares, as returned by [total_habitat_area()].
#'
#' @returns Numeric. Probability of connectedness: between 0 and 1 for a
#'   landscape measured against itself.
#' @examples
#' area <- lizard_areas_connected$area
#' connectivity_probability(
#'   effective_mesh_ha = effective_mesh_size(area),
#'   area_baseline_ha = total_habitat_area(area)
#' )
#' # a scenario that loses the first patch, measured against the baseline
#' scenario_area <- area[-1]
#' scenario_mesh_ha <- effective_mesh_size(scenario_area, area_baseline = area)
#' connectivity_probability(
#'   effective_mesh_ha = scenario_mesh_ha,
#'   area_baseline_ha = total_habitat_area(area)
#' )
#' @export
connectivity_probability <- function(effective_mesh_ha, area_baseline_ha) {
  check_scalar_numeric(effective_mesh_ha)
  check_scalar_numeric(area_baseline_ha)
  prob_connect <- effective_mesh_ha / area_baseline_ha
  prob_connect
}


#' @noRd
connectivity_metrics <- function(area, area_baseline) {
  metrics <- tibble::tibble(
    n_patches = n_patches(area),
    effective_mesh_ha = effective_mesh_size(
      area = area,
      area_baseline = area_baseline
    ),
    prob_connectedness = connectivity_probability(
      effective_mesh_ha = effective_mesh_ha,
      area_baseline_ha = total_habitat_area(area_baseline)
    )
  )

  metrics
}

#' Build the shared connectivity metric columns
#'
#' The single source of truth for the metric set and column order shared by
#' [summarise_connectivity()] and [compare_connectivity()]. Computes the metrics
#' for `area` against the `area_baseline` reference denominator.
#'
#' Values are deliberately returned at full precision. [compare_connectivity()]
#' subtracts two of these rows to build its `change` row, and rounding before
#' that subtraction quantises the delta to the rounding step - a scenario can
#' move `prob_connectedness` by less than 1e-06, so the delta collapses to zero.
#' Round at display time instead, never here.
#'
#' @param area,area_baseline Numeric vectors of connected patch areas.
#' @returns A one-row tibble of metrics at full precision.
#' @noRd
connectivity_metric_row <- function(area, area_baseline) {
  metrics <- connectivity_metrics(area = area, area_baseline = area_baseline)
  tibble::tibble(
    n_patches = metrics$n_patches,
    effective_mesh_ha = metrics$effective_mesh_ha,
    prob_connectedness = metrics$prob_connectedness,
    patch_area_mean = mean_patch_size(area),
    patch_area_total_ha = total_habitat_area(area)
  )
}
