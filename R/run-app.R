#' Launch the Connectivity Shiny App
#'
#' @description
#' Launches the connectivity analysis Shiny application.
#'
#' @return No return value, called for side effects (launches Shiny app)
#' @export
#'
#' @examples
#' \dontrun{
#' run_connectivity_app()
#' }
run_connectivity_app <- function() {
  app_dir <- system.file("shiny", package = "urbioconnect")

  if (app_dir == "" || !dir.exists(app_dir)) {
    cli::cli_abort(
      "Shiny app not found.",
      "We see: {.path {app_dir}}",
      "Try reinstalling the package."
    )
  }

  rlang::check_installed(app_packages())

  shiny::runApp(app_dir)
}

#' Packages the Shiny app needs that urbioconnect only suggests
#'
#' `global.R` attaches all of these but `gridExtra`, which `server.R` reaches
#' through `::`. They are Suggests, so an install need not have them, which is
#' why [run_connectivity_app()] checks before launching and the tests skip
#' without them.
#'
#' One vector because the two lists had drifted: the launch check was missing
#' `diffviewer`, so it passed and then `global.R` failed to attach it, and the
#' tests were missing `gridExtra`, so they errored rather than skipping.
#'
#' @returns A character vector of package names.
#' @noRd
app_packages <- function() {
  c(
    "bslib",
    "conflicted",
    "diffviewer",
    "DT",
    "fasterize",
    "gridExtra",
    "shinyjs"
  )
}
