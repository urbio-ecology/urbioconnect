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
  display_result(display_data(x))
}

#' @rdname connectivity_display
#' @export
connectivity_display.patch_size_tbl <- function(x, ...) {
  display_result(display_data(x))
}

#' @rdname connectivity_display
#' @export
connectivity_display.compare_connectivity <- function(x, wide = TRUE, ...) {
  if (wide) {
    return(display_result(comparison_wide(x)))
  }

  # once the measures are rows, one column holds every metric's worth of
  # magnitudes, so significant figures per cell rather than decimals per
  # column. Identifiers keep their own rules: signif would turn a 1234m
  # distance into 1230.
  display_result(display_data(x), metric_digits = 3)
}

#' @rdname connectivity_display
#' @export
connectivity_display.default <- function(x, ...) {
  cli::cli_abort(c(
    "Can't display {.obj_type_friendly {x}}.",
    "i" = "{.arg x} must be a {.cls connectivity}, {.cls patch_size_tbl} or
           {.cls compare_connectivity} object."
  ))
}

#' Drop what can't be displayed, and format what needs it
#'
#' @noRd
display_data <- function(x) {
  tibble::as_tibble(x) |>
    dplyr::select(-dplyr::any_of("patch_size")) |>
    dplyr::mutate(
      dplyr::across(dplyr::any_of("data_resolution"), format_resolution)
    )
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
  check_display(display)

  rounded <- display$data

  # check_display() has already vouched for `kind`
  rounded[display$digits$column] <- purrr::pmap(
    display$digits,
    function(column, kind, digits) {
      switch(kind, round = round, signif = signif)(rounded[[column]], digits)
    }
  )

  rounded
}

#' @rdname round_by
#' @export
format_by <- function(display) {
  formatted <- round_by(display)
  columns <- display$digits$column

  # pinned, so one display reads the same wherever it is rendered. The app and
  # the report agreeing is the whole point, and `format()` otherwise follows
  # whatever `scipen` and `OutDec` the caller happens to have set.
  pinned <- options(scipen = 0, digits = 7, OutDec = ".")
  on.exit(options(pinned), add = TRUE)

  formatted[columns] <- purrr::map(formatted[columns], format_values)

  formatted
}

#' One value at a time, so each picks its own notation
#'
#' A missing value stays missing: `format(NA)` is the string `"NA"`, which the
#' renderer can no longer style.
#'
#' @noRd
format_values <- function(values) {
  vapply(
    values,
    function(value) {
      if (is.na(value)) NA_character_ else format(value, trim = TRUE)
    },
    character(1)
  )
}

#' Name, label and rounding for every column of a `connectivity`
#'
#' The one place that decides what a metric is called and how precisely to
#' show it. A column missing here is shown unrounded under its own name, so a
#' new metric is visible rather than hidden.
#'
#' `role` says whether a column identifies a row or measures it, which is what
#' lets a consumer pivot or drop the identifiers without naming them. Labels
#' are kept short because the PDF report renders these as a fixed-width table,
#' and a long heading hyphenates across the column boundary.
#'
#' @noRd
connectivity_columns <- function() {
  tibble::tribble(
    ~name                 , ~label            , ~role    , ~kind    , ~digits ,
    "species"             , "Species"         , "id"     , NA       , NA      ,
    "scenario_name"       , "Scenario"        , "id"     , NA       , NA      ,
    "measure"             , "Measure"         , "id"     , NA       , NA      ,
    "interpatch_distance" , "Distance (m)"    , "id"     , NA       , NA      ,
    "data_resolution"     , "Resolution (m)"  , "id"     , NA       , NA      ,
    "n_patches"           , "Patches"         , "metric" , NA       , NA      ,
    "effective_mesh_ha"   , "Mesh (ha)"       , "metric" , "round"  ,       2 ,
    "prob_connectedness"  , "P(connected)"    , "metric" , "signif" ,       3 ,
    "patch_area_mean"     , "Mean area (m2)"  , "metric" , "round"  ,       1 ,
    "patch_area_total_ha" , "Total area (ha)" , "metric" , "round"  ,       2 ,
    "patch_id"            , "Patch ID"        , "id"     , NA       , NA      ,
    "area"                , "Area (m2)"       , "metric" , "round"  ,       1 ,
    # the wide comparison's measures, once they become columns. pct_change
    # gets significant figures, not decimals: it exists to make a move that
    # reads as nothing in absolute terms legible, and 0.001% would round to 0.
    "metric"              , "Metric"          , "id"     , NA       , NA      ,
    "baseline"            , "Baseline"        , "metric" , "signif" ,       3 ,
    "scenario"            , "Scenario value"  , "metric" , "signif" ,       3 ,
    "change"              , "Change"          , "metric" , "signif" ,       3 ,
    "pct_change"          , "% change"        , "metric" , "signif" ,       3
  )
}

#' Turn a comparison inside out: metrics down, measures across
#'
#' Every identifier the object carries stays one, `scenario_name` included.
#' Without it two scenarios land on the same row and `pivot_wider()` returns
#' list-columns rather than numbers.
#'
#' @noRd
comparison_wide <- function(x) {
  spec <- connectivity_columns()
  metrics <- spec$name[spec$role == "metric"]

  wide <- tibble::as_tibble(x)

  # what tells one row from another. Species and resolution are the same for
  # every row of a comparison and are shown around the table, and an unnamed
  # comparison has no scenario to name.
  ids <- intersect(c("scenario_name", "interpatch_distance"), names(wide))

  if (all(is.na(wide$scenario_name))) {
    ids <- setdiff(ids, "scenario_name")
  }

  wide |>
    dplyr::select(dplyr::any_of(c("measure", ids, metrics))) |>
    tidyr::pivot_longer(
      cols = dplyr::any_of(metrics),
      names_to = "metric",
      values_to = "value"
    ) |>
    tidyr::pivot_wider(names_from = "measure", values_from = "value") |>
    # kept in the spec's order, then labelled: these are row values now, so
    # they need the same names the column headings would have had
    dplyr::mutate(
      metric = factor(.data$metric, levels = spec$name)
    ) |>
    dplyr::arrange(dplyr::pick(dplyr::any_of(ids)), .data$metric) |>
    dplyr::mutate(metric = display_labels(as.character(.data$metric), spec))
}

#' Apply labels, and describe the rounding for what is left numeric
#'
#' `metric_digits` overrides the per-column rules with significant figures,
#' for a table whose rows are measures rather than metrics. It applies to the
#' metrics only: an identifier rounded to 3 significant figures would turn a
#' 1234m distance into 1230.
#'
#' @noRd
display_result <- function(data, metric_digits = NULL) {
  spec <- connectivity_columns() |>
    dplyr::filter(.data$name %in% names(data))

  labels <- display_labels(names(data), spec)

  # the digit spec names its column, so two columns sharing a label would
  # round the first one twice and leave the second alone
  vctrs::vec_as_names(labels, repair = "check_unique")

  labelled <- data
  names(labelled) <- labels

  digits <- if (is.null(metric_digits)) {
    dplyr::filter(spec, !is.na(.data$kind))
  } else {
    spec |>
      dplyr::filter(.data$role == "metric") |>
      dplyr::mutate(kind = "signif", digits = metric_digits)
  }

  # only what is actually a number: DT and round() need one
  numeric <- names(labelled)[purrr::map_lgl(labelled, is.numeric)]

  digits <- digits |>
    dplyr::transmute(column = .data$label, .data$kind, .data$digits) |>
    dplyr::filter(.data$column %in% numeric)

  list(data = labelled, digits = digits)
}

#' Which display columns identify a row rather than measure it
#'
#' So a consumer that has to pivot or drop the identifiers can ask, rather
#' than hardcoding the label text.
#'
#' @param display A list from [connectivity_display()].
#'
#' @returns A character vector of column labels.
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
#' display_ids(connectivity_display(lizard))
display_ids <- function(display) {
  check_display(display)

  spec <- connectivity_columns()
  intersect(spec$label[spec$role == "id"], names(display$data))
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
  shaped <- is.list(x) &&
    all(c("data", "digits") %in% names(x)) &&
    is.data.frame(x$data) &&
    is.data.frame(x$digits) &&
    all(c("column", "kind", "digits") %in% names(x$digits))

  if (!shaped) {
    cli::cli_abort(
      c(
        "{.arg {arg}} must be a list of a {.field data} table and a
         {.field digits} table of {.field column}, {.field kind} and
         {.field digits}.",
        "i" = "Build one with {.fn connectivity_display}."
      ),
      call = call
    )
  }

  # a rule naming a column that isn't there would otherwise fail inside
  # round(), as "non-numeric argument to mathematical function"
  missing <- setdiff(x$digits$column, names(x$data))

  if (length(missing) > 0) {
    cli::cli_abort(
      c(
        "{.arg {arg}} has a digit rule for a column that isn't in the data.",
        "x" = "Not found: {.field {missing}}."
      ),
      call = call
    )
  }

  # checked here rather than where it is used, so the message isn't buried
  # under purrr's "In index: 1"
  unknown <- setdiff(x$digits$kind, c("round", "signif"))

  if (length(unknown) > 0) {
    cli::cli_abort(
      c(
        "A digit rule's {.field kind} must be {.val round} or {.val signif}.",
        "x" = "Got {.val {unknown}}."
      ),
      call = call
    )
  }

  invisible(x)
}
