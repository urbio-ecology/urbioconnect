#' Summarise connectivity metrics
#'
#' Calculates habitat connectivity metrics including effective mesh size,
#' probability of connectedness, and patch statistics. [habitat_connectivity()]
#' runs the analysis and calls this for you, so you only need it to summarise
#' patch areas you already have.
#'
#' A `patch_size_tbl` carries its own species, interpatch distance and
#' resolution. For a vector of patch areas, give those three yourself, each a
#' single value.
#'
#' @name summarise-connectivity
#'
#' @param connectivity A `patch_size_tbl`, such as an element of
#'   [patch_sizes()] (`patch_sizes(x)[[1]]`) or the result of
#'   [sf_habitat_connectivity()], whose resolution is `"NA"` as it has no
#'   cells. Or a numeric vector of connected patch areas, in square metres.
#' @param ... extra arguments to pass through for default method.
#'
#' @returns A tibble with connectivity metrics including number of patches,
#'   probability of connectedness, effective mesh size, mean and total patch
#'   areas.
#' @examples
#' # dispatch on `patch_size_tbl` class - `lizard_areas_connected`
#' summarise_connectivity(
#'   connectivity = lizard_areas_connected
#' )
#'
#' # default method
#' # manually passing area, interpatch distance, resolution, and species
#' summarise_connectivity(
#'   connectivity = lizard_areas_connected$area,
#'   interpatch_distance = 10,
#'   data_resolution = 10,
#'   species = "Blue-tongued Lizard"
#' )
#' @export
summarise_connectivity <- function(
  connectivity,
  ...
) {
  UseMethod("summarise_connectivity")
}

#' Construct a `connectivity` summary object
#'
#' Internal constructor shared by the `summarise_connectivity()` methods. Takes
#' the assembled results tibble (which must already contain every summary
#' column plus the `patch_size` list-column) and returns the classed
#' `connectivity` object with a stable column order.
#'
#' @param x Tibble with the summary columns and `patch_size`
#'   list-column.
#' @returns A `connectivity` object (a tibble subclass).
#' @noRd
new_connectivity <- function(x) {
  vctrs::new_data_frame(
    x = list(
      species = x$species,
      interpatch_distance = x$interpatch_distance,
      n_patches = x$n_patches,
      effective_mesh_ha = x$effective_mesh_ha,
      prob_connectedness = x$prob_connectedness,
      patch_area_mean = x$patch_area_mean,
      patch_area_total_ha = x$patch_area_total_ha,
      data_resolution = x$data_resolution,
      patch_size = x$patch_size
    ),
    class = c("connectivity", "tbl_df", "tbl")
  )
}

#' Shared body for the `summarise_connectivity()` methods
#'
#' Builds the one-row `connectivity` summary from an `area` vector and its
#' descriptors. The two methods differ only in where `area` and the descriptors
#' come from; both delegate here so the metric/rounding logic lives in one place
#' (via `connectivity_metric_row()`) and the column order in `new_connectivity()`.
#'
#' @param area Numeric vector of connected patch areas.
#' @param interpatch_distance,data_resolution,species Scalars describing the run.
#' @param patch_size The `patch_size_tbl` stored in the `patch_size`
#'   list-column. Both methods store one: the `patch_size_tbl` method passes
#'   its input through, the default method builds one from the area vector.
#' @returns A `connectivity` object.
#' @noRd
summarise_connectivity_impl <- function(
  area,
  interpatch_distance,
  data_resolution,
  species,
  patch_size
) {
  full_results <- connectivity_metric_row(area = area, area_baseline = area) |>
    dplyr::mutate(
      species = species,
      interpatch_distance = interpatch_distance,
      data_resolution = data_resolution,
      patch_size = list(patch_size)
    )

  new_connectivity(full_results)
}

#' @export
summarise_connectivity.patch_size_tbl <- function(
  connectivity,
  ...
) {
  summarise_connectivity_impl(
    area = connectivity$area,
    interpatch_distance = pc_interpatch_distance(connectivity),
    data_resolution = pc_res(connectivity),
    species = pc_species(connectivity),
    patch_size = connectivity
  )
}

#' @rdname summarise-connectivity
#' @param interpatch_distance Numeric. The interpatch distance, in metres, the
#'   areas were found with. It is recorded in the summary, not used to
#'   calculate it.
#' @param data_resolution Numeric. The cell size, in metres, the areas were
#'   found at. Recorded in the summary, like `interpatch_distance`.
#' @param species Character. Name of species analysed.
#' @export
summarise_connectivity.default <- function(
  connectivity,
  interpatch_distance,
  data_resolution,
  species,
  ...
) {
  # Store areas as patch_size_tbl so `patch_sizes()` returns one shape
  # regardless of method, else compare_connectivity() fails looking for `$area`
  patch_size <- patch_size_tbl(
    data = tibble::tibble(
      patch_id = seq_along(connectivity),
      area = connectivity
    ),
    species = species,
    interpatch_distance = interpatch_distance,
    res = data_resolution
  )

  summarise_connectivity_impl(
    area = connectivity,
    interpatch_distance = interpatch_distance,
    data_resolution = data_resolution,
    species = species,
    patch_size = patch_size
  )
}
