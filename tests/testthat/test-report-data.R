test_that("connectivity_report_data() keeps a summary and layers per distance", {
  layers <- scenario_test_layers()

  report_data <- connectivity_report_data(
    habitat = layers$habitat,
    barrier = layers$barrier,
    species = "Test Species",
    interpatch_distance = c(40, 80),
    verbose = FALSE
  )

  expect_s3_class(report_data, "connectivity_report_data")
  expect_snapshot(names(report_data))

  expect_s3_class(report_data$connectivity, "connectivity")
  expect_equal(nrow(report_data$connectivity), 2)
  expect_equal(report_data$connectivity$interpatch_distance, c(40, 80))

  # the spatial layers are named by interpatch distance, one per run
  expect_named(report_data$buffered_habitat, c("40", "80"))
  expect_named(report_data$patch_id_raster, c("40", "80"))
  purrr::walk(report_data$patch_id_raster, function(patch_id) {
    expect_s4_class(patch_id, "SpatRaster")
    expect_true(all(c("patch_id", "area") %in% names(patch_id)))
  })
})

test_that("a scenario gives the same comparison, for half the pipeline runs", {
  layers <- scenario_test_layers()

  # the comparison used to be built by habitat_connectivity_comparison() and
  # passed in, which ran the baseline again on top of this function's own run.
  # Building it from the two runs this function already does has to give the
  # same numbers.
  separately <- habitat_connectivity_comparison(
    habitat_scenario = layers$habitat,
    barrier_scenario = layers$barrier_scenario,
    habitat_baseline = layers$habitat,
    barrier_baseline = layers$barrier,
    species = "Test Species",
    interpatch_distance = c(40, 80),
    verbose = FALSE
  )

  together <- connectivity_report_data(
    habitat = layers$habitat,
    barrier = layers$barrier,
    species = "Test Species",
    interpatch_distance = c(40, 80),
    scenario = layers$barrier_scenario,
    scenario_kind = "barrier",
    verbose = FALSE
  )

  expect_equal(together$comparison, separately)

  # and the scenario landscape comes back with it, so the maps need no
  # second pass over the rasters
  expect_equal(together$scenario_kind, "barrier")
  expect_named(together$scenario_buffered_habitat, c("40", "80"))
  expect_equal(
    terra::values(scenario_layer(together)),
    terra::values(
      layers$barrier_scenario
    )
  )
  expect_equal(
    terra::values(together$scenario_habitat),
    terra::values(layers$habitat)
  )
})

test_that("both landscapes are built by the same chain", {
  layers <- scenario_test_layers()

  # the app used to buffer the scenario's raw habitat while the baseline's
  # came out of habitat_connectivity_full(), which buffers what is left after
  # the barrier is removed, so the two maps were drawn differently. Now both
  # sides go through the same function and an unchanged scenario has to give
  # the baseline's own layers back.
  unchanged <- suppressWarnings(
    connectivity_report_data(
      habitat = layers$habitat,
      barrier = layers$barrier,
      species = "Test Species",
      interpatch_distance = 40,
      scenario = layers$barrier,
      scenario_kind = "barrier",
      verbose = FALSE
    )
  )

  expect_equal(
    terra::values(unchanged$scenario_buffered_habitat[["40"]]),
    terra::values(unchanged$buffered_habitat[["40"]])
  )
})

test_that("an analysis with no scenario has no scenario anything", {
  layers <- scenario_test_layers()

  plain <- connectivity_report_data(
    habitat = layers$habitat,
    barrier = layers$barrier,
    species = "Test Species",
    interpatch_distance = 40,
    verbose = FALSE
  )

  expect_null(plain$comparison)
  expect_null(plain$scenario_kind)
  expect_null(scenario_layer(plain))
})

test_that("a scenario and its kind have to arrive together", {
  layers <- scenario_test_layers()

  report_data <- function(...) {
    connectivity_report_data(
      habitat = layers$habitat,
      barrier = layers$barrier,
      species = "Test Species",
      interpatch_distance = 40,
      verbose = FALSE,
      ...
    )
  }

  expect_snapshot(error = TRUE, {
    report_data(scenario = layers$barrier_scenario)
    report_data(scenario_kind = "barrier")
    report_data(scenario = layers$barrier_scenario, scenario_kind = "both")
  })

  # an unchanged scenario is legal, and says so
  expect_snapshot(
    report_data(scenario = layers$barrier, scenario_kind = "barrier")
  )
})

test_that("connectivity_report_data() matches habitat_connectivity()", {
  layers <- scenario_test_layers()

  report_data <- connectivity_report_data(
    habitat = layers$habitat,
    barrier = layers$barrier,
    species = "Test Species",
    interpatch_distance = 40,
    verbose = FALSE
  )

  direct <- habitat_connectivity(
    habitat = layers$habitat,
    barrier = layers$barrier,
    species = "Test Species",
    interpatch_distance = 40,
    verbose = FALSE
  )

  expect_equal(report_data$connectivity, direct)
})


test_that("an analysis survives a write and read round trip", {
  written <- test_report_data(c(40, 80))
  path <- file.path(withr::local_tempdir(), "analysis.rds")

  expect_equal(write_report_data(written, path), path)

  read <- read_report_data(path)

  expect_s3_class(read, "connectivity_report_data")
  expect_equal(read$connectivity, written$connectivity)
  expect_named(read$patch_id_raster, c("40", "80"))

  # the rasters are packed on the way out, so check they come back usable
  expect_s4_class(read$habitat, "SpatRaster")
  expect_equal(terra::values(read$habitat), terra::values(written$habitat))
})

test_that("read_report_data() rejects an rds holding something else", {
  # named rather than a tempfile, so the file name in the error is stable
  path <- file.path(withr::local_tempdir(), "not-report-data.rds")
  saveRDS(list(not = "an analysis"), path)

  expect_snapshot(read_report_data(path), error = TRUE)
})

test_that("connectivity_report_data() checks its arguments", {
  layers <- scenario_test_layers()

  expect_snapshot(error = TRUE, {
    connectivity_report_data(
      habitat = layers$habitat,
      barrier = layers$barrier,
      species = "Test Species",
      verbose = FALSE
    )
    connectivity_report_data(
      habitat = layers$habitat,
      barrier = layers$barrier,
      species = c("one", "two"),
      interpatch_distance = 40,
      verbose = FALSE
    )
  })
})
