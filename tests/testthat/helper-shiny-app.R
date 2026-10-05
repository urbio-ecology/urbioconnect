# Everything the app needs before testServer() can see `server`. The app is
# sourced, not loaded, so each test that touches it pays this preamble.
skip_if_no_app <- function() {
  skip_on_cran()
  purrr::walk(
    c("shiny", "DT", "bslib", "conflicted", "fasterize", "shinyjs"),
    skip_if_not_installed
  )
}

# sourced into the caller's environment, so `server` is visible to testServer
local_app_server <- function(envir = parent.frame()) {
  app_dir <- system.file("shiny", package = "urbioconnect")
  skip_if(app_dir == "", "shiny app directory not found")

  suppressMessages({
    source(file.path(app_dir, "packages.R"), local = envir)
    source(file.path(app_dir, "colours.R"), local = envir)
    source(file.path(app_dir, "server.R"), local = envir)
  })

  invisible(app_dir)
}

# the inputs that make the app run its analysis on the example wren data
app_example_inputs <- function() {
  list(
    use_example_data = TRUE,
    species = "Superb Fairy Wren",
    data_resolution = 10,
    target_resolution = 500,
    interpatch_distances = "200",
    run_analysis = 1
  )
}
