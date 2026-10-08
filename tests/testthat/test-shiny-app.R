test_that("the app's analysis path runs and every result output renders", {
  # CI never ran inst/shiny/, so an API rename broke Run Analysis three times
  # without anything noticing. This is the regression guard, on the real
  # pipeline and the uploaded lizard layers.
  skip_if_no_app()
  local_app_server()

  shiny::testServer(server, {
    rlang::exec(session$setInputs, !!!app_lizard_inputs())

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
      # the tab containers: these broke when the layer lists gained names,
      # because navset_tab() wants its panels unnamed
      "gg_barrier_habitat_buffer_tabs",
      "plot_patches_tabs",
      "barrier_habitat_interpatch_40",
      "patch_plot_40"
    )

    purrr::walk(outputs, function(output_name) {
      expect_no_error(output[[output_name]])
    })
  })
})

test_that("the app's downloads produce files with content", {
  skip_if_no_app()
  local_app_server()

  # the reports are rendered for real by test-assets.R; here the point is that
  # the handlers are wired, so stand in for the 17s of Quarto. quarto_available
  # is pinned too, so the archive holds the reports either way.
  local_mocked_bindings(
    quarto_available = function() TRUE,
    render_asset_reports = function(x, dir) {
      purrr::walk(
        file.path(dir, paste0("report.", c("html", "pdf"))),
        function(path) writeLines("stand-in for a rendered report", path)
      )
    }
  )

  shiny::testServer(server, {
    rlang::exec(session$setInputs, !!!app_lizard_inputs())

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

    # download everything: the same analysis, archived. Asserted here rather
    # than in its own test, which would re-run the pipeline for the same state
    expect_s3_class(results$report_data, "connectivity_report_data")

    contents <- zip::zip_list(output$download_everything)$filename
    folder <- connectivity_file_stem(results$report_data)

    expect_in(
      paste0(
        folder,
        "/",
        c(
          "README.md",
          "interpatch-40m/gis/patches.gpkg",
          "summary/connectivity-summary.csv",
          # the reports travel in the archive too
          "report.html",
          "report.pdf"
        )
      ),
      contents
    )
  })
})

test_that("the app's report button hands Quarto the analysis just run", {
  skip_if_no_app()
  local_app_server()

  # Quarto itself is exercised in test-generate-report.R, and asking it to
  # spend eleven seconds here only re-proved that. Standing in at the last
  # step still covers the whole chain the app owns - the button, the
  # analysis, the qmd and its data file - and can check something the old
  # test couldn't: that the analysis handed over is the one just run.
  handed_over <- NULL

  local_mocked_bindings(
    quarto_available = function() TRUE,
    quarto_render_file = function(input, output_format, quiet) {
      stem <- tools::file_path_sans_ext(input)
      handed_over <<- read_report_data(paste0(stem, "-data.rds"))
      writeLines("a rendered report", paste0(stem, ".html"))
      invisible(NULL)
    }
  )

  shiny::testServer(server, {
    rlang::exec(session$setInputs, !!!app_lizard_inputs())

    # one handler, not three: the PDF and zip buttons are the same path with
    # a different format
    expect_match(
      paste(
        readLines(output$download_report_html, warn = FALSE),
        collapse = ""
      ),
      "a rendered report",
      fixed = TRUE
    )

    expect_s3_class(handed_over, "connectivity_report_data")
    expect_equal(handed_over$species, "Blue Tongue Lizard")
    expect_equal(handed_over$interpatch_distance, 40)
  })
})

test_that("each dataset offers its own scenarios, as the layer they change", {
  skip_if_no_app()
  local_app_server()

  shiny::testServer(server, {
    # a scenario belongs to the landscape it was drawn on, so the dropdown's
    # options follow the dataset rather than being one fixed list. Uploading
    # is always offered, because an upload is put on whatever grid is in use.
    expect_equal(
      unname(scenario_choices("lizard")),
      c("none", "lizard_road", "upload")
    )
    expect_equal(
      unname(scenario_choices("wren")),
      c("none", "knox_barrier", "knox_habitat", "upload")
    )
    expect_equal(unname(scenario_choices("none")), c("none", "upload"))

    session$setInputs(example_data = "lizard", scenario_choice = "lizard_road")
    road <- chosen_scenario()
    expect_s4_class(road$layer, "SpatRaster")
    expect_equal(road$kind, "barrier")

    session$setInputs(example_data = "wren", scenario_choice = "knox_barrier")
    expect_equal(chosen_scenario()$kind, "barrier")

    session$setInputs(scenario_choice = "knox_habitat")
    expect_equal(chosen_scenario()$kind, "habitat")

    session$setInputs(scenario_choice = "none")
    expect_null(chosen_scenario())
  })
})

test_that("each supplied scenario covers the landscape it belongs to", {
  # a scenario is resampled onto whatever grid is in use, so it no longer has
  # to match one exactly - but it does have to describe the same place, or
  # check_layer_covers() rejects it at analysis time. This is the data
  # integrity check for that, and it reads the shipped rasters rather than
  # building a grid from the shapefiles.
  pairs <- list(
    list(example_wren_barrier_scenario(), example_wren_barrier()),
    list(example_wren_habitat_scenario(), example_wren_habitat()),
    list(example_barrier_scenario(), example_barrier())
  )

  purrr::walk(pairs, function(pair) {
    expect_no_error(check_layer_covers(pair[[1]], pair[[2]]))
  })
})

test_that("uploaded layers and an uploaded scenario reach the analysis", {
  skip_if_no_app()
  local_app_server()

  # a scenario covering part of the landscape, uploaded as a vector, so it
  # arrives as neither a raster nor on the baseline's grid. Written before
  # the session starts, from the same layer the upload uses, so the analysis
  # runs once rather than once without a scenario and again with one.
  scenario <- terra::as.polygons(
    terra::ext(example_barrier()) / 2,
    crs = terra::crs(example_barrier())
  )
  path <- withr::local_tempfile(fileext = ".gpkg")
  terra::writeVector(scenario, path)

  shiny::testServer(server, {
    # the whole upload path in one test, because it is what someone brings
    # their own data through: a GeoTIFF habitat, a shapefile barrier, and a
    # GeoPackage scenario on top
    rlang::exec(
      session$setInputs,
      !!!app_upload_inputs(scenario_choice = "upload")
    )
    session$setInputs(
      scenario_kind = "barrier",
      scenario_file = upload_value(path),
      run_analysis = 2
    )

    baseline <- results$barrier_raster

    expect_true(results$ready)
    expect_s3_class(results$comparison, "compare_connectivity")
    expect_equal(results$scenario_kind, "barrier")

    # connectivity_report_data() put it on the baseline's grid on the way in
    expect_equal(
      as.vector(terra::ext(results$scenario_barrier)),
      as.vector(terra::ext(baseline))
    )
    expect_s4_class(results$scenario_layer, "SpatRaster")

    # everything a comparison drives, rendered here rather than on the wren
    # data above: the tab containers, the per-distance plots they hold, and
    # the diffviewer widget, which writes a PNG per side before it compares
    purrr::walk(
      c(
        "comparison_wide_table",
        "comparison_long_table",
        "layer_habitat",
        "layer_barrier",
        "layer_scenario",
        "baseline_landscape_tabs",
        "scenario_landscape_tabs",
        "landscape_compare_tabs",
        "baseline_landscape_40",
        "scenario_landscape_40",
        "compare_40"
      ),
      function(name) expect_no_error(output[[name]])
    )
  })
})

test_that("a scenario that can't match the baseline says so by name", {
  skip_if_no_app()
  local_app_server()

  shiny::testServer(server, {
    # a Knox scenario against uploaded layers: the dropdown never offers this
    # pairing, but the inputs can still be driven into it
    session$setInputs(
      example_data = "none",
      species = "Wren",
      scenario_choice = "knox_barrier"
    )
    expect_snapshot(check_scenario_choice(), error = TRUE)

    # or against the other example dataset
    session$setInputs(example_data = "lizard")
    expect_snapshot(check_scenario_choice(), error = TRUE)

    session$setInputs(scenario_choice = "upload")
    expect_snapshot(check_scenario_choice(), error = TRUE)

    session$setInputs(scenario_choice = "none")
    expect_no_error(check_scenario_choice())
  })
})

test_that("no scenario chosen means no comparison anywhere", {
  skip_if_no_app()
  local_app_server()

  shiny::testServer(server, {
    rlang::exec(session$setInputs, !!!app_lizard_inputs())

    expect_true(results$ready)
    expect_null(results$comparison)

    # so the report and the download have nothing scenario-shaped in them
    expect_null(results$report_data$comparison)
  })
})

test_that("the report buttons do nothing before an analysis has run", {
  skip_if_no_app()
  local_app_server()

  shiny::testServer(server, {
    # filename runs before content, so a missing req() there used to abort in
    # the browser rather than quietly doing nothing
    purrr::walk(
      c("download_report_html", "download_report_pdf", "download_reports_zip"),
      function(id) expect_error(output[[id]], class = "shiny.silent.error")
    )
  })
})
