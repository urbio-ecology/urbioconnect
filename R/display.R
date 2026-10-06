#' Prepare a result for display
#'
#' Labels the columns and says how precisely each should be shown, so a table
#'   on screen and the same table in a report agree. Values come back
#'   **numeric**: the rounding is described rather than applied, because
#'   [DT::datatable()] needs numbers to stay numbers to sort them, while
#'   [knitr::kable()] wants them already rounded. [round_by()] applies the
#'   rounding when that is what you want.
#'
#' @param x A `connectivity`, `patch_size_tbl` or `compare_connectivity`
#'   object.
#' @param wide For a comparison, one row per metric and a column per measure,
#'   which is the shape a reader wants. `FALSE` keeps the object's own shape:
#'   one row per measure, a column per metric.
#' @param ... Passed to methods.
#'
#' @returns A list of
#'   * `data`, a tibble with display labels and numeric values
#'   * `digits`, a tibble of `column`, `kind` (`"round"` or `"signif"`) and
#'     `digits`, one row per column that needs rounding
#' @seealso [round_by()] to apply the rounding.
#' @export
#'
#' @examples
#' lizard <- habitat_connectivity(
#'   habitat = example_habitat(),
#'   barrier = example_barrier(),
#'   species = "Blue Tongue Lizard",
#'   interpatch_distance = 20,
#'   verbose = FALSE
#' )
#'
#' display <- connectivity_display(lizard)
#' display$digits
#' round_by(display)
connectivity_display <- function(x, ...) {
  UseMethod("connectivity_display")
}

#' @rdname connectivity_display
#' @export
connectivity_display.connectivity <- function(x, ...) {
  spec <- connectivity_columns()

  data <- x |>
    dplyr::select(-dplyr::any_of("patch_size")) |>
    dplyr::mutate(
      dplyr::across(
        dplyr::any_of("data_resolution"),
        format_resolution
      )
    )

  display_result(data, spec)
}

#' @rdname connectivity_display
#' @export
connectivity_display.patch_size_tbl <- function(x, ...) {
  display_result(
    tibble::as_tibble(x)[c("patch_id", "area")],
    patch_columns()
  )
}

#' @rdname connectivity_display
#' @export
connectivity_display.compare_connectivity <- function(x, wide = TRUE, ...) {
  if (wide) {
    return(display_result(comparison_wide(x), comparison_columns()))
  }

  data <- tibble::as_tibble(x) |>
    dplyr::select(-dplyr::any_of(c("scenario_name", "patch_size"))) |>
    dplyr::mutate(
      dplyr::across(dplyr::any_of("data_resolution"), format_resolution)
    )

  # one column holds every metric's worth of magnitudes once the measures are
  # rows, so significant figures per cell, not decimals per column
  display_result(data, connectivity_columns(), signif_digits = 3)
}

#' Apply the rounding a display describes
#'
#' [round_by()] rounds and leaves the values numeric, which is right when each
#'   column holds one metric. [format_by()] formats each value to a string
#'   instead, which is what a column of several metrics needs: a numeric
#'   column spanning 1e-5 to 1e4 prints wholly in scientific notation, so a
#'   count of 3 reads as `3.00e+00`. [DT::datatable()] formats cell by cell
#'   and so needs neither; [knitr::kable()] formats by column and so needs
#'   `format_by()` for a comparison.
#'
#' @param display A list from [connectivity_display()].
#'
#' @returns The `data` tibble: numeric from [round_by()], character from
#'   [format_by()].
#' @seealso [connectivity_display()]
#' @export
#'
#' @examples
#' lizard <- habitat_connectivity(
#'   habitat = example_habitat(),
#'   barrier = example_barrier(),
#'   species = "Blue Tongue Lizard",
#'   interpatch_distance = 20,
#'   verbose = FALSE
#' )
#'
#' round_by(connectivity_display(lizard))
round_by <- function(display) {
  apply_digits(display, function(values, round_fn, digits) {
    round_fn(values, digits)
  })
}

#' @rdname round_by
#' @export
format_by <- function(display) {
  apply_digits(display, function(values, round_fn, digits) {
    # one value at a time, so each picks its own notation
    vapply(
      round_fn(values, digits),
      function(value) format(value, trim = TRUE),
      character(1)
    )
  })
}

#' @noRd
apply_digits <- function(display, apply) {
  check_display(display)

  purrr::reduce(
    seq_len(nrow(display$digits)),
    function(data, i) {
      rule <- display$digits[i, ]
      round_fn <- switch(rule$kind, round = base::round, signif = base::signif)
      data[[rule$column]] <- apply(data[[rule$column]], round_fn, rule$digits)
      data
    },
    .init = display$data
  )
}

#' Name, label and rounding for every column of a `connectivity`
#'
#' The one place that decides what a metric is called and how precisely to
#' show it. A column missing here is shown unrounded under its own name, so a
#' new metric is visible rather than hidden.
#'
#' @noRd
connectivity_columns <- function() {
  dplyr::bind_rows(
    display_column("species", "Species"),
    display_column("scenario_name", "Scenario"),
    display_column("measure", "Measure"),
    display_column("interpatch_distance", "Distance (m)"),
    display_column("n_patches", "Patches"),
    display_column("effective_mesh_ha", "Mesh (ha)", "round", 2),
    display_column("prob_connectedness", "P(connected)", "signif", 3),
    display_column("patch_area_mean", "Mean area (m2)", "round", 1),
    display_column("patch_area_total_ha", "Total area (ha)", "round", 2),
    display_column("data_resolution", "Resolution (m)")
  )
}

#' One row of a column spec, so a name sits next to its label
#'
#' @noRd
display_column <- function(name, label, kind = NA_character_, digits = NA) {
  tibble::tibble(name = name, label = label, kind = kind, digits = digits)
}

#' @noRd
patch_columns <- function() {
  dplyr::bind_rows(
    display_column("patch_id", "Patch ID"),
    display_column("area", "Area (m2)", "round", 1)
  )
}

#' Columns of the wide comparison
#'
#' Each row is one metric, so a column holds every magnitude the metrics span.
#' Significant figures, not decimals. `pct_change` is already a percentage, so
#' it gets decimals of its own.
#'
#' @noRd
comparison_columns <- function() {
  dplyr::bind_rows(
    display_column("interpatch_distance", "Distance (m)"),
    display_column("metric", "Metric"),
    display_column("baseline", "Baseline", "signif", 3),
    display_column("scenario", "Scenario", "signif", 3),
    display_column("change", "Change", "signif", 3),
    display_column("pct_change", "% change", "round", 1)
  )
}

#' Turn a comparison inside out: metrics down, measures across
#'
#' @noRd
comparison_wide <- function(x) {
  metrics <- connectivity_columns() |>
    dplyr::filter(!is.na(.data$kind))

  tibble::as_tibble(x) |>
    dplyr::select(dplyr::any_of(c(
      "measure",
      "interpatch_distance",
      "n_patches",
      metrics$name
    ))) |>
    tidyr::pivot_longer(
      cols = -dplyr::all_of(c("measure", "interpatch_distance")),
      names_to = "metric",
      values_to = "value"
    ) |>
    tidyr::pivot_wider(names_from = "measure", values_from = "value") |>
    # kept in the spec's order, then labelled: these are row values now, so
    # they need the same names the column headings would have had
    dplyr::mutate(
      metric = factor(.data$metric, levels = connectivity_columns()$name)
    ) |>
    dplyr::arrange(.data$interpatch_distance, .data$metric) |>
    dplyr::mutate(
      metric = display_labels(
        as.character(.data$metric),
        connectivity_columns()
      )
    )
}

#' Apply labels, and describe the rounding for what is left numeric
#'
#' `signif_digits` overrides the per-column rules, for a table whose rows are
#' measures rather than metrics.
#'
#' @noRd
display_result <- function(data, spec, signif_digits = NULL) {
  spec <- spec[spec$name %in% names(data), ]

  labelled <- data
  names(labelled) <- display_labels(names(data), spec)

  numeric <- names(labelled)[purrr::map_lgl(labelled, is.numeric)]

  digits <- if (is.null(signif_digits)) {
    spec |>
      dplyr::filter(!is.na(.data$kind)) |>
      dplyr::transmute(
        column = .data$label,
        kind = .data$kind,
        digits = .data$digits
      )
  } else {
    tibble::tibble(
      column = numeric,
      kind = "signif",
      digits = signif_digits
    )
  }

  # a metric with no rule still has to be a column DT can format
  digits <- digits[digits$column %in% numeric, ]

  list(data = labelled, digits = digits)
}

#' @noRd
display_labels <- function(names, spec) {
  matched <- match(names, spec$name)
  ifelse(is.na(matched), to_sentence(names), spec$label[matched])
}

#' @noRd
check_display <- function(
  x,
  arg = rlang::caller_arg(x),
  call = rlang::caller_env()
) {
  if (!is.list(x) || !all(c("data", "digits") %in% names(x))) {
    cli::cli_abort(
      c(
        "{.arg {arg}} must be a list with {.field data} and {.field digits}.",
        "i" = "Build one with {.fn connectivity_display}."
      ),
      call = call
    )
  }
  invisible(x)
}
