#' Render a connectivity report
#'
#' One document holding the maps, tables and summary for an analysis: the same
#'   figures [write_connectivity_assets()] writes, laid out to read. HTML is a
#'   single self-contained file; PDF is rendered through Typst, so no LaTeX is
#'   needed.
#'
#'   The report covers the tabular and visual results. The GIS layers travel
#'   with [zip_connectivity_assets()], since a GeoTIFF can't live inside a
#'   document.
#'
#' @param x A `connectivity_report_data` object from
#'   [connectivity_report_data()].
#' @param output_format One of `"html"`, `"pdf"`, or `"both"`.
#' @param output_dir Directory to write the report to, defaulting to the
#'   working directory. Created if it doesn't exist.
#' @param output_file File name, without extension. Defaults to the species and
#'   today's date, matching the asset bundle's folder name.
#'
#' @returns The absolute path(s) written, invisibly.
#' @seealso [connectivity_report_data()] to build `x`, and
#'   [zip_connectivity_assets()] for the GIS layers and full tables.
#' @export
#'
#' @examples
#' \donttest{
#' report_data <- connectivity_report_data(
#'   habitat = example_habitat(),
#'   barrier = example_barrier(),
#'   species = "Blue Tongue Lizard",
#'   interpatch_distance = 20,
#'   verbose = FALSE
#' )
#'
#' generate_connectivity_report(report_data, output_dir = tempdir())
#' }
generate_connectivity_report <- function(
  x,
  output_format = c("html", "pdf", "both"),
  output_dir = ".",
  output_file = NULL
) {
  check_report_data(x)
  output_format <- rlang::arg_match(output_format)
  check_quarto()

  output_file <- output_file %||% bundle_dir_name(x)

  # Quarto renders beside its input, so the template, its data and the result
  # share one directory and only the result is copied out
  staging <- tempfile("urbioconnect-report")
  dir.create(staging, recursive = TRUE)
  on.exit(unlink(staging, recursive = TRUE), add = TRUE)

  write_report_data(x, file.path(staging, "report-data.rds"))

  template <- system.file(
    "templates",
    "connectivity-report.qmd",
    package = "urbioconnect"
  )
  staged_template <- file.path(staging, basename(template))
  file.copy(template, staged_template)

  if (!dir.exists(output_dir)) {
    dir.create(output_dir, recursive = TRUE)
  }

  extensions <- if (output_format == "both") c("html", "pdf") else output_format

  paths <- purrr::map_chr(
    extensions,
    function(extension) {
      render_report(staged_template, extension, output_dir, output_file)
    }
  )

  invisible(paths)
}

#' Render the staged template in one format and move the result out
#'
#' Driven by the extension, which is also the file name Quarto writes. Only
#' the format name differs: a `.pdf` comes out of the `typst` format.
#'
#' @noRd
render_report <- function(template, extension, output_dir, output_file) {
  cli::cli_inform("Rendering {.field {extension}} report...")

  size <- urbio_figure_size()

  render <- function(quiet) {
    quarto::quarto_render(
      input = template,
      output_format = switch(extension, html = "html", pdf = "typst"),
      # passed in, not written into the template, so the size has one home
      metadata = list(
        `fig-width` = size$width,
        `fig-height` = size$height,
        `fig-dpi` = size$dpi
      ),
      quiet = quiet
    )
  }

  # a quiet render discards the reason it failed, so retry loudly to show it
  rlang::try_fetch(
    render(quiet = TRUE),
    error = function(cnd) {
      cli::cli_inform("Render failed. Retrying to show Quarto's output.")
      render(quiet = FALSE)
      cli::cli_abort(
        "Quarto couldn't render the {.field {extension}} report.",
        parent = cnd
      )
    }
  )

  staging <- dirname(template)
  rendered <- sub("\\.qmd$", paste0(".", extension), template)

  # don't hand back a path to nothing
  if (!file.exists(rendered)) {
    cli::cli_abort(c(
      "Quarto rendered no {.field {extension}} file.",
      "i" = "Expected {.path {basename(rendered)}} in the render directory.",
      "i" = "Found: {.path {basename(list.files(staging))}}."
    ))
  }

  destination <- file.path(output_dir, paste0(output_file, ".", extension))
  copied <- file.copy(rendered, destination, overwrite = TRUE)

  if (!copied) {
    cli::cli_abort(
      "Couldn't write the report to {.path {destination}}."
    )
  }

  # absolute, so it survives a change of working directory
  destination <- normalizePath(destination, winslash = "/")
  cli::cli_inform("Wrote {.path {destination}}")

  destination
}

#' Check Quarto is available
#'
#' The R package is an Import, but it shells out to the Quarto CLI, which is
#' separate software and may not be installed.
#'
#' @noRd
check_quarto <- function(call = rlang::caller_env()) {
  if (!quarto::quarto_available()) {
    cli::cli_abort(
      c(
        "Can't find the Quarto command line tool.",
        "i" = "Install it from {.url https://quarto.org/docs/get-started/}.",
        "i" = "The assets alone need no Quarto: see
               {.fn write_connectivity_assets}."
      ),
      call = call
    )
  }
  invisible(TRUE)
}
