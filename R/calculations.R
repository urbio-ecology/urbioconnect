#' Calculate effective mesh size
#'
#' Computes the effective mesh size metric for habitat connectivity, This
#'   represents the probability that two randomly chosen points within habitat
#'   remain connected. Intended for usage from objects created by
#'   [habitat_connectivity()]. See examples below.
#'
#' @param area Numeric vector. Area of connected patches.
#' @param area_baseline Optional. Defaults to `area` if not specified.
#'   Numeric vector of connected patches of a baseline area. This is to allow
#'   for comparing the effective mesh size when comparing different scenarios.
#'   See future vignette on this topic (TODO).
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
#' Calculate the total habitat area in hectars. A wrapper around summing the
#'   area and multiplying by 0.0001 to give the units in hectares. Intended
#'   for usage from objects created by [habitat_connectivity()]. See examples
#'   below.
#'
#' @param area Numeric vector. Area of a connected patch.
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
#' Computes the probability two randomly chosen points within habitat
#' are connected, accounting for fragmentation. This requires the effective
#' mesh size (via [effective_mesh_size()]), and the area of patches. This means
#' that you can calculate the change in connectivity if you calculate the
#' effective mesh size of a new habitat/barrier plan, and then use the baseline
#'
#' @param effective_mesh_size As calculated by [effective_mesh_size()]
#' @param area_baseline Numeric vector. Area of a connected patch. This
#'  argument is called "baseline" as when you are doing design scenarios you
#'  must refer to the baseline area when calculating connectivity probability.
#'  See vignette, TODO.
#'
#' @returns Numeric. Probability of connectedness (0-1).
#' @examples
#' effective_mesh <- effective_mesh_size(
#'   area = lizard_areas_connected$area
#'   )
#' connectivity_probability(
#'   effective_mesh_size = effective_mesh,
#'   area_baseline = lizard_areas_connected$area
#'   )
#' # if you wanted to compare to a scenario, you would consider the effective
#' # mesh size to be the new scenario level, and the baseline as so:
#' connectivity_probability(
#' # scenario 1
#'   effective_mesh_size = effective_mesh,
#'   area_baseline = lizard_areas_connected$area
#'   )
#' @export
connectivity_probability <- function(effective_mesh_size, area_baseline) {
  total_habitat <- sum(area_baseline)
  prob_connect <- effective_mesh_size / total_habitat
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
      effective_mesh_size = effective_mesh_ha,
      area_baseline = area_baseline
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
#' that subtraction quantises the delta to the rounding step — for
#' `prob_connectedness` (~1e-05) that step is larger than the changes being
#' measured, so the delta collapses to zero or overshoots by an order of
#' magnitude. Round at display time instead, never here.
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
