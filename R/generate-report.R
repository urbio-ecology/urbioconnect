#' Write a connectivity report's source, so you can render it yourself
#'
#' Writes the report as a Quarto document you own a copy of, next to the data
#'   it draws. Open it, change it, render it. [render_connectivity_report()]
#'   renders it the way the package does, and
#'   [generate_connectivity_report()] does both steps at once when the source
#'   isn't wanted.
#'
#'   Two files are written: `path`, and the analysis beside it as
#'   `<name>-data.rds`. The document reads that file by name, so the two
#'   travel together. Moving one without the other breaks the render.
#'
#' @param x A `connectivity_report_data` object from
#'   [connectivity_report_data()].
#' @param path File to write, ending in `.qmd`. Defaults to the species and
#'   today's date, in the working directory. The directory must already exist.
#'
#' @returns The absolute path of the `.qmd`, invisibly.
#' @seealso [render_connectivity_report()] to render it,
#'   [generate_connectivity_report()] to do both.
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
#' qmd <- write_connectivity_report(
#'   report_data,
#'   file.path(tempdir(), "lizard-report.qmd")
#' )
#'
#' readLines(qmd, n = 5)
#' }
write_connectivity_report <- function(x, path = NULL) {
  check_report_data(x)

  path <- path %||% paste0(bundle_dir_name(x), ".qmd")
  check_qmd_path(path)

  qmd <- absolute_path(path)
  stem <- tools::file_path_sans_ext(basename(qmd))
  data_file <- paste0(stem, "-data.rds")

  write_report_data(x, file.path(dirname(qmd), data_file))
  writeLines(report_source(data_file), qmd)

  invisible(qmd)
}

#' Render a connectivity report's source
#'
#' Renders a `.qmd` from [write_connectivity_report()], with the figure sizes
#'   and the Typst routing the package uses. Rendering the document yourself,
#'   with the Render button or [quarto::quarto_render()], gives the same
#'   result; this adds the choice of format by extension and puts the output
#'   where you ask.
#'
#' @param input The `.qmd` to render, from [write_connectivity_report()].
#' @param path File to write. The extension sets the format, as it does for
#'   [ggplot2::ggsave()]. Defaults to `input` with a `.html` extension. The
#'   directory must already exist.
#'
#' @returns The absolute path written, invisibly.
#' @seealso [write_connectivity_report()] to write the source.
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
#' qmd <- write_connectivity_report(
#'   report_data,
#'   file.path(tempdir(), "lizard-report.qmd")
#' )
#'
#' render_connectivity_report(qmd)
#' }
render_connectivity_report <- function(input, path = NULL) {
  check_scalar_character(input)
  check_quarto()

  if (!file.exists(input)) {
    cli::cli_abort(c(
      "{.arg input} doesn't exist: {.path {input}}.",
      "i" = "Write one with {.fn write_connectivity_report}."
    ))
  }

  path <- path %||% paste0(tools::file_path_sans_ext(input), ".html")
  format <- report_format(path)

  invisible(render_report(input, format, absolute_path(path)))
}

#' Render a connectivity report
#'
#' One document holding the maps, tables and summary for an analysis: the same
#'   figures [write_connectivity_assets()] writes, laid out to read. HTML is a
#'   single self-contained file; PDF is rendered through Typst, so no LaTeX is
#'   needed.
#'
#'   [write_connectivity_report()] then [render_connectivity_report()], in one
#'   call, through a temporary directory. Use those two instead when you want
#'   the Quarto source to keep or to change.
#'
#'   The report covers the tabular and visual results. The GIS layers travel
#'   with [zip_connectivity_assets()], since a GeoTIFF can't live inside a
#'   document.
#'
#'   The format comes from `path`'s extension, as it does for
#'   [ggplot2::ggsave()]: `"report.pdf"` writes a PDF and `"report.html"` an
#'   HTML file. Write both by calling this twice.
#'
#'   Any format Quarto can write works, so `"report.docx"` and `"report.rtf"`
#'   also do what they look like. The Shiny app offers HTML and PDF only. A
#'   `.pdf` renders through Typst rather than Quarto's LaTeX-based `pdf`
#'   format, so no TeX install is needed. Note that the tabbed sections are
#'   HTML-only, and fall back to plain headings everywhere else.
#'
#' @param x A `connectivity_report_data` object from
#'   [connectivity_report_data()].
#' @param path File to write. The extension sets the format. Defaults to the
#'   species, today's date and `.html`, in the working directory. The
#'   directory must already exist.
#'
#' @returns The absolute path written, invisibly.
#' @seealso [connectivity_report_data()] to build `x`,
#'   [write_connectivity_report()] for the Quarto source, and
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
#' generate_connectivity_report(
#'   report_data,
#'   file.path(tempdir(), "lizard-report.html")
#' )
#' }
generate_connectivity_report <- function(x, path = NULL) {
  check_report_data(x)
  check_quarto()

  path <- path %||% paste0(bundle_dir_name(x), ".html")

  # checked before the analysis is written out, so a bad path fails on the
  # path the caller gave rather than deep inside the render
  report_format(path)
  destination <- absolute_path(path)

  staging <- tempfile("urbioconnect-report")
  dir.create(staging, recursive = TRUE)
  on.exit(unlink(staging, recursive = TRUE), add = TRUE)

  qmd <- write_connectivity_report(
    x,
    file.path(staging, "connectivity-report.qmd")
  )

  render_connectivity_report(qmd, destination)
}

#' The shipped template, with its data file name substituted in
#'
#' The document names its data in one YAML scalar, so that a copy written
#' beside its own `.rds` renders on its own. The substitution is checked,
#' because a template whose `params` block moved would otherwise write a
#' document pointing at a file that isn't there.
#'
#' @noRd
report_source <- function(data_file) {
  template <- system.file(
    "templates",
    "connectivity-report.qmd",
    package = "urbioconnect"
  )

  lines <- readLines(template)
  pattern <- '^(\\s*report_data:\\s*).*$'
  found <- grepl(pattern, lines)

  if (sum(found) != 1) {
    cli::cli_abort(c(
      "Can't find the {.field report_data} parameter in the report template.",
      "x" = "Matched {sum(found)} lines, expected exactly 1.",
      "i" = "This is a bug in urbioconnect."
    ))
  }

  lines[found] <- sub(pattern, paste0('\\1"', data_file, '"'), lines[found])
  lines
}

#' @noRd
check_qmd_path <- function(
  path,
  arg = rlang::caller_arg(path),
  call = rlang::caller_env()
) {
  check_scalar_character(path, arg = arg, call = call)

  if (tolower(tools::file_ext(path)) != "qmd") {
    cli::cli_abort(
      c(
        "{.arg {arg}} must end in {.path .qmd}.",
        "x" = "{.arg {arg}} is {.path {path}}.",
        "i" = "This writes the report's source. To write a rendered report,
               see {.fn generate_connectivity_report}."
      ),
      call = call
    )
  }

  invisible(path)
}

#' Render a document and move the result to `destination`
#'
#' @noRd
render_report <- function(input, format, destination) {
  extension <- tolower(tools::file_ext(destination))

  cli::cli_inform("Rendering {.field {extension}} report...")

  render <- function(quiet) {
    quarto::quarto_render(
      input = input,
      output_format = format,
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

  # Quarto writes beside its input, under the same stem
  rendered <- paste0(tools::file_path_sans_ext(input), ".", extension)

  # don't hand back a path to nothing
  if (!file.exists(rendered)) {
    cli::cli_abort(c(
      "Quarto rendered no {.field {extension}} file.",
      "i" = "Expected {.path {basename(rendered)}} in {.path {dirname(input)}}.",
      "i" = "Found: {.path {basename(list.files(dirname(input)))}}."
    ))
  }

  if (normalizePath(rendered, winslash = "/") != destination) {
    copied <- file.copy(rendered, destination, overwrite = TRUE)

    if (!copied) {
      cli::cli_abort("Couldn't write the report to {.path {destination}}.")
    }
  }

  cli::cli_inform("Wrote {.path {destination}}")

  destination
}

#' The Quarto format for a report path, from its extension
#'
#' The extension is Quarto's format name for most of its outputs, so it is
#' passed straight through and Quarto reports anything it can't write. These
#' are the three where the two names differ. Quarto's own `pdf` is LaTeX; a
#' `.pdf` goes through Typst instead, so no TeX install is needed.
#'
#' @noRd
report_format <- function(
  path,
  arg = rlang::caller_arg(path),
  call = rlang::caller_env()
) {
  check_scalar_character(path, arg = arg, call = call)

  extension <- tolower(tools::file_ext(path))

  if (extension == "") {
    cli::cli_abort(
      c(
        "{.arg {arg}} needs a file extension, to say which format to write.",
        "x" = "{.arg {arg}} is {.path {path}}.",
        "i" = "Try {.path .html} or {.path .pdf}."
      ),
      call = call
    )
  }

  switch(extension, pdf = "typst", md = "gfm", tex = "latex", extension)
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
