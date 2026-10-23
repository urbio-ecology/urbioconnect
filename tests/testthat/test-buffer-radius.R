test_that("buffer_radius_from() halves the interpatch distance", {
  # interpatch_distance is the full edge-to-edge gap; each patch is buffered by
  # half of it, so the two meet in the middle
  expect_equal(buffer_radius_from(250), 125)
  expect_equal(buffer_radius_from(0), 0)
  # vectorised, because habitat_connectivity() sweeps
  expect_equal(buffer_radius_from(c(250, 500)), c(125, 250))
})

test_that("the entry points that take one distance say so", {
  layers <- scenario_test_layers()

  expect_snapshot(
    error = TRUE,
    habitat_connectivity_full(
      layers$habitat,
      layers$barrier,
      interpatch_distance = c(40, 80),
      verbose = FALSE
    )
  )
})

test_that("habitat_connectivity() requires numeric interpatch distances", {
  layers <- scenario_test_layers()

  # the errors are attributed to the function the user called, so they are
  # snapshotted from there rather than from the internal helper
  connectivity_at <- function(...) {
    habitat_connectivity(
      habitat = layers$habitat,
      barrier = layers$barrier,
      species = "Test Species",
      verbose = FALSE,
      ...
    )
  }

  expect_snapshot(error = TRUE, {
    connectivity_at()
    connectivity_at(interpatch_distance = "40")
    connectivity_at(interpatch_distance = numeric(0))
    connectivity_at(interpatch_distance = c(40, 40))
    connectivity_at(interpatch_distance = c(40, -80))
    connectivity_at(interpatch_distance = c(40, NA))
    connectivity_at(interpatch_distance = Inf)
  })
})

test_that("check_distances() rejects a zero-length vector", {
  # a sweep over numeric(0) returns no rows and no error, which is how an
  # empty comparison table once got out
  expect_equal(check_distances(c(100, 200)), c(100, 200))
  expect_error(check_distances(numeric(0)), "at least one distance")
})

test_that("warn_buffer_resolution is silent when the radius aligns with the resolution", {
  # 500 is a clean multiple of a 250 m cell -> no discretisation loss
  expect_no_warning(
    warn_buffer_resolution(
      buffer_radius = 500,
      resolution = 250
    )
  )
})

test_that("warn_buffer_resolution warns when the radius is smaller than one cell", {
  # a 200 m interpatch distance on a 500 m cell -> sub-cell, buffer is negligible
  expect_snapshot(
    warn_buffer_resolution(
      buffer_radius = 100,
      resolution = 500
    )
  )
})

test_that("warn_buffer_resolution reports the effective distance when not a clean multiple", {
  # a 1200 m interpatch distance on a 500 m cell snaps to 1000 m
  expect_snapshot(
    warn_buffer_resolution(
      buffer_radius = 600,
      resolution = 500
    )
  )
})
