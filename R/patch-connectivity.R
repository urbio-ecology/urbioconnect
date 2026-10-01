#' A set of connected habitat patches
#'
#' A [tibble][tibble::tibble] of connected patch areas (one row per patch)
#' that also carries the `species` and `interpatch_distance` the analysis
#' was run with as attributes. [habitat_connectivity()] builds one of these
#' internally for each call; retrieve it from the returned `connectivity`
#' summary with [patch_sizes()].
#'
#' Because it is a tibble subclass it behaves like a data frame directly --
#' `$`, `[`, [DT::datatable()], [utils::write.csv()] and ggplot2 all work
#' without ceremony. Read the metadata back with [pc_species()] and
#' [pc_interpatch_distance()].
#'
#' @param data Data frame of connected patches. Must contain an `area` column.
#' @param species Character of length 1. Species the analysis was run for.
#' @param res resolution in pixels - defaults to NA (numeric), not required for
#'   vector based approaches.
#' @param interpatch_distance Numeric of length 1. The interpatch distance (m)
#'   the analysis used.
#' @returns A `patch_size_tbl` object: a tibble with `species` and
#'   `interpatch_distance` attributes.
#' @export
new_patch_size_tbl <- function(
  data,
  species,
  interpatch_distance,
  res = NA_real_
) {
  check_scalar_character(species)
  check_scalar_numeric(interpatch_distance)
  check_numeric(res)
  check_names(data, "area")
  check_names(data, "patch_id")

  res <- res %||% NA

  vctrs::new_data_frame(
    # tibble::as_tibble(data),
    x = list(
      patch_id = data$patch_id,
      area = data$area
    ),
    species = species,
    interpatch_distance = interpatch_distance,
    res = res,
    n = nrow(data),
    class = c("patch_size_tbl", "tbl_df", "tbl")
  )
}

validate_patch_size_tbl <- function(x) {
  species <- pc_species(x)
  check_scalar_character(species)

  interpatch_distance <- pc_interpatch_distance(x)
  check_scalar_numeric(interpatch_distance)

  res <- pc_res(x)
  check_character(res)

  check_names(x, "area")
  check_names(x, "patch_id")

  invisible(x)
}

#' @rdname new_patch_size_tbl
#' @export
patch_size_tbl <- function(
  data,
  species,
  interpatch_distance,
  res = NA_real_
) {
  pc <- new_patch_size_tbl(
    data = data,
    species = species,
    interpatch_distance = interpatch_distance,
    res = res
  )
  validate_patch_size_tbl(pc)
  pc
}

# using approaches from https://epiverse-trace.github.io/posts/extend-dataframes/
# Gate on *structural* prerequisites that exist on the bare data dplyr hands us
# (the required columns), not on metadata attributes -- those live on the
# template and are restored by df_reconstruct(), not validated here.
patch_size_tbl_can_reconstruct <- function(data) {
  all(c("patch_id", "area") %in% names(data))
}

df_reconstruct <- function(x, to) {
  attrs <- attributes(to)
  attrs$names <- names(x)
  attrs$row.names <- .row_names_info(x, type = 0L)
  attributes(x) <- attrs
  x
}

patch_size_tbl_reconstruct <- function(x, to) {
  if (patch_size_tbl_can_reconstruct(x)) {
    df_reconstruct(x, to)
  } else {
    x <- as.data.frame(x)
    cli::cli_inform(
      "Removing attributes in {.cls patch_size_tbl}",
      "Returning {.cls data.frame}"
    )
    x
  }
}

#' @exportS3Method dplyr::dplyr_reconstruct
dplyr_reconstruct.patch_size_tbl <- function(data, template) {
  patch_size_tbl_reconstruct(data, template)
}

#' @export
`[.patch_size_tbl` <- function(x, ...) {
  out <- NextMethod()
  patch_size_tbl_reconstruct(out, x)
}

#' @export
`names<-.patch_size_tbl` <- function(x, value) {
  out <- NextMethod()
  patch_size_tbl_reconstruct(out, x)
}

#' @export
print.patch_size_tbl <- function(x, ..., n = NULL) {
  NextMethod(n = n %||% 5)
}

#' @exportS3Method tibble::tbl_sum
tbl_sum.patch_size_tbl <- function(x) {
  c(
    "patch_size_tbl" = "data.frame",
    "Species" = pc_species(x),
    "Patches" = pc_patches(x),
    "Resolution" = pc_res(x),
    "Interpatch Distance" = paste(pc_interpatch_distance(x), "m")
  )
}

#' Metadata from a `patch_size_tbl` object
#'
#' @param x A [patch_size_tbl()] object.
#' @returns
#'  * `pc_species()` Returns the species (character, length 1).
#'  * `pc_interpatch_distance()` returns the interpatch distance (numeric,
#'   length 1).
#'  * `pc_res()` returns the resolution (character, length 1 - e.g., "2x2").
#'  * `pc_patches()` returns the number of patches - computed live from the
#'  number of rows (numeric, length 1).
#' @name pc-getters
#' @export
pc_species <- function(x) {
  attr(x, "species")
}

#' @rdname pc-getters
#' @export
pc_patches <- function(x) {
  nrow(x)
}

#' @rdname pc-getters
#' @export
pc_res <- function(x) {
  x_res <- attr(x, "res")
  if (is.null(x_res)) {
    return(NA)
  }
  paste(round(x_res, 5), collapse = "x")
}

#' Format a raster resolution for reading
#'
#' A reprojected raster rarely has round cells: a nominally 10m grid comes out
#'   as `9.99673 x 10.00151`. That precision matters in the data and reads as
#'   noise on a screen, so round it for display.
#'
#' @param res Either the numeric pair [terra::res()] returns, or the
#'   `"9.99673x10.00151"` string carried in a `connectivity` object's
#'   `data_resolution` column.
#' @param digits Decimal places to round to. Default 1.
#'
#' @returns A character vector, e.g. `"10 x 10"`.
#' @export
#'
#' @examples
#' format_resolution(c(9.99673, 10.00151))
#' format_resolution("9.99673x10.00151")
format_resolution <- function(res, digits = 1) {
  sides <- if (is.character(res)) {
    strsplit(res, "x", fixed = TRUE)
  } else {
    list(res)
  }

  purrr::map_chr(sides, function(side) {
    paste(round(as.numeric(side), digits), collapse = " x ")
  })
}

#' @rdname pc-getters
#' @export
pc_interpatch_distance <- function(x) {
  attr(x, "interpatch_distance")
}

#' Extract the per-patch tables from a `connectivity` object
#'
#' A `connectivity` object (from [habitat_connectivity()] or
#' [summarise_connectivity()]) carries the underlying per-patch areas in a
#' `patch_size` list-column. `patch_sizes()` returns them.
#'
#' @param x A `connectivity` object.
#' @returns A list of [patch_size_tbl()] objects, one per row of `x` (always a
#'   list, even for a single-row summary).
#' @export
patch_sizes <- function(x) {
  check_connectivity(x)
  x[["patch_size"]]
}
