test_that("the app's analysis path runs and every result output renders", {
  # CI never ran inst/shiny/, so an API rename broke Run Analysis three times
  # without anything noticing. This is the regression guard. It costs ~10s,
  # since it runs the real pipeline on the example wren data.
  skip_on_cran()
  skip_if_not_installed("shiny")
  skip_if_not_installed("DT")
  skip_if_not_installed("bslib")
  skip_if_not_installed("conflicted")
  skip_if_not_installed("fasterize")
  skip_if_not_installed("shinyjs")

  app_dir <- system.file("shiny", package = "urbioconnect")
  skip_if(app_dir == "", "shiny app directory not found")

  # the same sources app.R uses, minus ui.R, which testServer doesn't need
  suppressMessages({
    source(file.path(app_dir, "packages.R"))
    source(file.path(app_dir, "colours.R"))
    source(file.path(app_dir, "server.R"), local = TRUE)
  })

  shiny::testServer(server, {
    session$setInputs(
      use_example_data = TRUE,
      species = "Superb Fairy Wren",
      data_resolution = 10,
      target_resolution = 500,
      interpatch_distances = "200",
      run_analysis = 1
    )

    expect_true(results$ready)
    expect_equal(nrow(results$results_connect_habitat), 1)
    expect_s3_class(results$results_connect_habitat, "connectivity")

    # each of these has broken at least once: the tables on the patch_size
    # list-column, the maps on a renamed loop variable
    outputs <- c(
      "summary_table",
      "results_connect_habitat_table",
      "results_connect_habitat_longer_table",
      "plot_connectivity_output",
      "barrier_habitat_interpatch_200",
      "patch_plot_200"
    )

    purrr::walk(outputs, function(output_name) {
      expect_no_error(output[[output_name]])
    })
  })
})

test_that("the app's downloads produce files with content", {
  skip_on_cran()
  skip_if_not_installed("shiny")
  skip_if_not_installed("DT")
  skip_if_not_installed("bslib")
  skip_if_not_installed("conflicted")
  skip_if_not_installed("fasterize")
  skip_if_not_installed("shinyjs")

  app_dir <- system.file("shiny", package = "urbioconnect")
  skip_if(app_dir == "", "shiny app directory not found")

  suppressMessages({
    source(file.path(app_dir, "packages.R"))
    source(file.path(app_dir, "colours.R"))
    source(file.path(app_dir, "server.R"), local = TRUE)
  })

  shiny::testServer(server, {
    session$setInputs(
      use_example_data = TRUE,
      species = "Superb Fairy Wren",
      data_resolution = 10,
      target_resolution = 500,
      interpatch_distances = "200",
      run_analysis = 1
    )

    summary_csv <- readr::read_csv(
      output$download_summary_csv,
      show_col_types = FALSE
    )
    patches_csv <- readr::read_csv(
      output$download_patches_csv,
      show_col_types = FALSE
    )

    # the summary used to carry an empty patch_size column, from the
    # list-column of per-patch tables
    expect_false("patch_size" %in% names(summary_csv))
    expect_equal(nrow(summary_csv), 1)
    expect_snapshot(names(summary_csv))

    expect_true(all(c("area", "interpatch_distance") %in% names(patches_csv)))
    expect_gt(nrow(patches_csv), 1)

    patch_raster <- terra::rast(output$download_raster)
    expect_s4_class(patch_raster, "SpatRaster")
  })
})

test_that("the app's download-everything button returns the asset bundle", {
  skip_on_cran()
  skip_if_not_installed("shiny")
  skip_if_not_installed("DT")
  skip_if_not_installed("bslib")
  skip_if_not_installed("conflicted")
  skip_if_not_installed("fasterize")
  skip_if_not_installed("shinyjs")

  app_dir <- system.file("shiny", package = "urbioconnect")
  skip_if(app_dir == "", "shiny app directory not found")

  suppressMessages({
    source(file.path(app_dir, "packages.R"))
    source(file.path(app_dir, "colours.R"))
    source(file.path(app_dir, "server.R"), local = TRUE)
  })

  shiny::testServer(server, {
    session$setInputs(
      use_example_data = TRUE,
      species = "Superb Fairy Wren",
      data_resolution = 10,
      target_resolution = 500,
      interpatch_distances = "200",
      run_analysis = 1
    )

    expect_s3_class(results$report_data, "connectivity_report_data")

    contents <- zip::zip_list(output$download_everything)$filename
    folder <- paste0("superb-fairy-wren-connectivity-", Sys.Date())

    expect_true(paste0(folder, "/README.md") %in% contents)
    expect_true(
      paste0(folder, "/interpatch-200m/gis/patches.gpkg") %in% contents
    )
    expect_true(
      paste0(folder, "/summary/connectivity-summary.csv") %in% contents
    )
  })
})
