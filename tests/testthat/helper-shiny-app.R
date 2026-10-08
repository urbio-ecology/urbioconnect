# Everything the app needs before testServer() can see `server`. The app is
# sourced, not loaded, so each test that touches it pays this preamble.
skip_if_no_app <- function() {
  skip_on_cran()
  purrr::walk(
    c(
      "shiny",
      "DT",
      "bslib",
      "conflicted",
      "diffviewer",
      "fasterize",
      "shinyjs"
    ),
    skip_if_not_installed
  )
}

# sourced into the caller's environment, so `server` is visible to testServer
app_dir <- function() {
  dir <- system.file("shiny", package = "urbioconnect")
  skip_if(dir == "", "shiny app directory not found")
  dir
}

local_app_server <- function(envir = parent.frame()) {
  app_dir <- app_dir()

  suppressMessages({
    # global.R sources colours.R itself, as it does when shiny runs the app
    withr::with_dir(app_dir, source("global.R", local = envir))
    source(file.path(app_dir, "server.R"), local = envir)
  })

  invisible(app_dir)
}

# A fileInput's value: the data frame shiny hands the server for an upload.
# A shapefile needs its sidecars, so this takes every file sharing a stem.
upload_value <- function(path) {
  stem <- tools::file_path_sans_ext(path)
  files <- Sys.glob(paste0(stem, ".*"))

  data.frame(
    name = basename(files),
    size = file.size(files),
    type = "",
    datapath = files,
    stringsAsFactors = FALSE
  )
}

# The app's own example-data path, on the lizard landscape: ~200x200 cells
# after prepare_rasters, so a full analysis with a scenario comparison is
# under a second. The wren dataset is the same call with
# example_data = "wren", and costs tens of seconds, so nothing uses it by
# default.
app_lizard_inputs <- function(
  interpatch_distances = "40",
  scenario_choice = "none",
  example_data = "lizard"
) {
  list(
    example_data = example_data,
    # the app fills this in from the dataset with updateTextInput(), which
    # testServer() does not round-trip back into input$. The browser test
    # covers that; here it is set directly. global.R's own table isn't
    # visible from a helper's environment, hence the second copy.
    species = c(
      lizard = "Blue Tongue Lizard",
      wren = "Superb Fairy Wren"
    )[[example_data]],
    data_resolution = 10,
    target_resolution = 500,
    interpatch_distances = interpatch_distances,
    scenario_choice = scenario_choice,
    run_analysis = 1
  )
}

# the same landscape, uploaded rather than chosen, for the upload path. The
# habitat ships as a GeoTIFF and the barrier as a shapefile, so this covers
# both readers at once.
app_upload_inputs <- function(
  interpatch_distances = "40",
  scenario_choice = "none"
) {
  list(
    example_data = "none",
    species = "Blue Tongue Lizard",
    # the 763x766 raster, not lizard_habitat.tif at 1908x1916: both are
    # GeoTIFFs of the same landscape, and prepare_rasters() reduces either to
    # the same grid, so the larger one is only a slower read
    habitat_file = upload_value(
      system.file("ex", "lizard_habitat_raster.tif", package = "urbioconnect")
    ),
    barrier_file = upload_value(
      system.file("ex", "lizard_barrier.shp", package = "urbioconnect")
    ),
    data_resolution = 10,
    target_resolution = 500,
    interpatch_distances = interpatch_distances,
    scenario_choice = scenario_choice,
    run_analysis = 1
  )
}

# shinytest2 drives a real browser, so it needs chrome as well as the app
skip_if_no_browser_app <- function() {
  skip_if_no_app()
  skip_if_not_installed("shinytest2")
  skip_if(
    is.null(tryCatch(chromote::find_chrome(), error = function(e) NULL)),
    "no chrome for shinytest2"
  )
}

# started for real, so these tests see what shiny sees
local_app_driver <- function(envir = parent.frame()) {
  # chromote gives a command 10s by default, which is not enough for
  # Page.navigate on a cold Windows runner: CI failed there with "timed out
  # waiting for response to command Page.navigate" before the app loaded at
  # all. load_timeout is a different clock and does not cover it.
  withr::local_options(chromote.timeout = 120, .local_envir = envir)

  app <- shinytest2::AppDriver$new(app_dir(), load_timeout = 120000)
  withr::defer(app$stop(), envir = envir)

  app
}
