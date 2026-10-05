test_that("the app's analysis path runs and every result output renders", {
  # CI never ran inst/shiny/, so an API rename broke Run Analysis three times
  # without anything noticing. This is the regression guard, on the real
  # pipeline and the example wren data.
  skip_if_no_app()
  local_app_server()

  shiny::testServer(server, {
    rlang::exec(session$setInputs, !!!app_example_inputs())

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
      "barrier_habitat_interpatch_200",
      "patch_plot_200"
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
    rlang::exec(session$setInputs, !!!app_example_inputs())

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
          "interpatch-200m/gis/patches.gpkg",
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

test_that("the app's report buttons render a report", {
  skip_if_no_app()
  skip_if_no_quarto()
  local_app_server()

  shiny::testServer(server, {
    rlang::exec(session$setInputs, !!!app_example_inputs())

    # one render, not three: reading an output runs its handler, and the PDF
    # and zip buttons are the same path with a different format
    expect_match(
      paste(
        readLines(output$download_report_html, warn = FALSE),
        collapse = ""
      ),
      "Superb Fairy Wren",
      fixed = TRUE
    )
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
