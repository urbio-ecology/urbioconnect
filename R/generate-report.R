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

  path <- path %||% paste0(connectivity_file_stem(x), ".qmd")
  check_qmd_path(path)

  qmd <- absolute_path(path)
  data_file <- paste0(tools::file_path_sans_ext(qmd), "-data.rds")

  write_report_data(x, data_file)
  file.copy(report_template(), qmd, overwrite = TRUE)

  invisible(qmd)
}

#' Render a connectivity report's source
#'
#' Renders a `.qmd` from [write_connectivity_report()]. The document carries
#'   its own figure sizes, so rendering it yourself with the Render button or
#'   [quarto::quarto_render()] gives the same figures; this adds the choice of
#'   format by extension, the Typst routing for a `.pdf`, and puts the output
#'   where you ask rather than beside the input.
#'
#' @param input The `.qmd` to render, from [write_connectivity_report()]. Its
#'   `-data.rds` must still be beside it.
#' @param path File to write. The extension sets the format, as it does for
#'   [ggplot2::ggsave()]. Defaults to `input` with a `.html` extension. The
#'   directory must already exist.
#' @param format The Quarto format, when `path` can't say. See
#'   [generate_connectivity_report()].
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
#' # rendering needs the Quarto command line tool
#' if (quarto_available()) {
#'   render_connectivity_report(qmd)
#' }
#' }
render_connectivity_report <- function(
  input,
  path = NULL,
  format = report_format(path)
) {
  check_scalar_character(input)
  check_quarto()

  if (!file.exists(input)) {
    cli::cli_abort(c(
      "{.arg input} doesn't exist: {.path {input}}.",
      "i" = "Write one with {.fn write_connectivity_report}."
    ))
  }

  path <- path %||% paste0(tools::file_path_sans_ext(input), ".html")

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
#'   Any format Quarto can write to a single file works, so `"report.docx"`
#'   and `"report.rtf"` also do what they look like. The Shiny app offers HTML
#'   and PDF only. A `.pdf` renders through Typst rather than Quarto's
#'   LaTeX-based `pdf` format, so no TeX install is needed.
#'
#'   Formats that keep their figures in a folder beside the document, such as
#'   `.md`, are refused: a report has to be one file, and copying the document
#'   alone would lose every figure. Note too that the tabbed sections are
#'   HTML-only and fall back to plain headings everywhere else.
#'
#' @param x A `connectivity_report_data` object from
#'   [connectivity_report_data()].
#' @param path File to write. The extension sets the format. Defaults to the
#'   species, today's date and `.html`, in the working directory. The
#'   directory must already exist.
#' @param format The Quarto format, when `path` can't say. Taken from `path`'s
#'   extension by default, which is what you want unless the destination is a
#'   name something else chose, as `shiny::downloadHandler()` does.
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
#' # rendering needs the Quarto command line tool
#' if (quarto_available()) {
#'   generate_connectivity_report(
#'     report_data,
#'     file.path(tempdir(), "lizard-report.html")
#'   )
#' }
#' }
generate_connectivity_report <- function(
  x,
  path = NULL,
  format = report_format(path)
) {
  check_report_data(x)
  check_quarto()

  path <- path %||% paste0(connectivity_file_stem(x), ".html")

  # resolved before the analysis is written out, so a bad path fails on the
  # path the caller gave rather than deep inside the render
  force(format)
  destination <- absolute_path(path)

  staging <- tempfile("urbioconnect-report")
  on.exit(unlink(staging, recursive = TRUE), add = TRUE)

  invisible(render_report(stage_report_qmd(x, staging), format, destination))
}

#' Write the report source into a directory the caller owns and cleans up
#'
#' @noRd
stage_report_qmd <- function(x, staging) {
  dir.create(staging, recursive = TRUE, showWarnings = FALSE)
  write_connectivity_report(x, file.path(staging, "connectivity-report.qmd"))
}

#' The shipped report template
#'
#' Copied verbatim. The document works out its own data file name from its
#' own, so nothing has to be written into it.
#'
#' @noRd
report_template <- function() {
  system.file(
    "templates",
    "connectivity-report.qmd",
    package = "urbioconnect"
  )
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

#' Hand a document to Quarto
#'
#' Its own function so that tests can stand in for it. What happens either
#' side of a render - the missing-output check, the sidecar refusal, moving
#' the result into place - is this package's logic, and asking Quarto to
#' spend five seconds proving it is five seconds per case.
#'
#' @noRd
quarto_render_file <- function(input, output_format, quiet) {
  quarto::quarto_render(
    input = input,
    output_format = output_format,
    quiet = quiet
  )
}

#' Render a document and move the result to `destination`
#'
#' `format` is the extension to write, not Quarto's name for it, because
#' `destination` may be a name Shiny chose with no extension at all.
#'
#' @noRd
render_report <- function(input, format, destination) {
  cli::cli_inform("Rendering {.field {format}} report...")

  render <- function(quiet) {
    quarto_render_file(
      input = input,
      output_format = quarto_format(format),
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
        "Quarto couldn't render the {.field {format}} report.",
        parent = cnd
      )
    }
  )

  # Quarto writes beside its input, under the same stem
  rendered <- paste0(tools::file_path_sans_ext(input), ".", format)

  # don't hand back a path to nothing
  if (!file.exists(rendered)) {
    cli::cli_abort(c(
      "Quarto rendered no {.field {format}} file.",
      "i" = "Expected {.path {basename(rendered)}} in {.path {dirname(input)}}.",
      "i" = "Found: {.path {basename(list.files(dirname(input)))}}."
    ))
  }

  # A self-contained format cleans up its figure folder; one that needs the
  # figures on disk leaves it behind, named `<stem>.<format>_files`. Copying
  # the one document out would lose every figure, so refuse instead of
  # handing back a report with no pictures.
  beside <- list.dirs(dirname(input), recursive = FALSE)
  sidecars <- beside[grepl(
    paste0("^", tools::file_path_sans_ext(basename(input)), ".*_files$"),
    basename(beside)
  )]

  if (length(sidecars) > 0) {
    unlink(c(rendered, sidecars), recursive = TRUE)
    cli::cli_abort(c(
      "Can't write a {.field {format}} report.",
      "x" = "{.field {format}} keeps its figures in a separate folder, and a
             report has to be one file.",
      "i" = "Use a self-contained format: {.path .html}, {.path .pdf},
             {.path .docx} or {.path .rtf}."
    ))
  }

  if (normalizePath(rendered, winslash = "/") != destination) {
    copied <- file.copy(rendered, destination, overwrite = TRUE)

    if (!copied) {
      cli::cli_abort("Couldn't write the report to {.path {destination}}.")
    }

    # Quarto wrote this beside the input, which on the public render path is
    # the caller's own directory
    unlink(rendered)
  }

  cli::cli_inform("Wrote {.path {destination}}")

  destination
}

#' A report path's format: its extension, lower case
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

  extension
}

#' Quarto's name for a format
#'
#' The extension is Quarto's own name for most of its outputs, so it passes
#' straight through and Quarto reports anything it can't write. `pdf` is the
#' one that differs: Quarto's own `pdf` is LaTeX, and this goes through Typst
#' instead so no TeX install is needed.
#'
#' @noRd
quarto_format <- function(format) {
  switch(format, pdf = "typst", format)
}

#' Is the Quarto command line tool installed?
#'
#' Quarto is separate software, not an R package, so it can be missing. The
#'   reports need it; nothing else in urbioconnect does. Ask this to decide
#'   what to offer: the Shiny app disables its report buttons when it returns
#'   `FALSE`, and `reports` defaults to it in
#'   [write_connectivity_assets()].
#'
#' @returns `TRUE` or `FALSE`.
#' @seealso [generate_connectivity_report()], which needs it.
#' @export
#'
#' @examples
#' quarto_available()
quarto_available <- function() {
  quarto::quarto_available()
}

#' Check Quarto is available
#'
#' The R package is an Import, but it shells out to the Quarto CLI, which is
#' separate software and may not be installed.
#'
#' @noRd
check_quarto <- function(call = rlang::caller_env()) {
  if (!quarto_available()) {
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
