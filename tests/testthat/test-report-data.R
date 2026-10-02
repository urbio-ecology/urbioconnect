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


test_that("a bundle survives a write and read round trip", {
  bundle <- test_asset_bundle(c(40, 80))
  path <- file.path(withr::local_tempdir(), "bundle.rds")

  expect_equal(write_report_data(bundle, path), path)

  read <- read_report_data(path)

  expect_s3_class(read, "connectivity_report_data")
  expect_equal(read$connectivity, bundle$connectivity)
  expect_named(read$patch_id_raster, c("40", "80"))

  # the rasters are packed on the way out, so check they come back usable
  expect_s4_class(read$habitat, "SpatRaster")
  expect_equal(terra::values(read$habitat), terra::values(bundle$habitat))
})

test_that("read_report_data() rejects an rds that isn't a bundle", {
  # named rather than a tempfile, so the file name in the error is stable
  path <- file.path(withr::local_tempdir(), "not-a-bundle.rds")
  saveRDS(list(not = "a bundle"), path)

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
