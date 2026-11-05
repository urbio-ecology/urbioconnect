test_that("distance_to_nearest_habitat() is the exact Euclidean distance", {
  # Scattered habitat on deliberately non-square cells, which is where an
  # approximate distance shows up. Checked against every pairwise distance.
  habitat <- test_raster(23, 27, cell = c(3, 2))
  withr::local_seed(1)
  terra::values(habitat) <- ifelse(runif(terra::ncell(habitat)) < 0.05, 1, NA)

  distance <- distance_to_nearest_habitat(habitat, distance_within = Inf)

  expect_equal(terra::values(distance)[, 1], brute_force_distance(habitat))
})

test_that("distance_to_nearest_habitat() is exact for every cell within distance_within", {
  # rows shorter than the columns are wide, so a row count taken from the
  # width would stop short
  habitat <- test_raster(40, 40, cell = c(10, 7))
  habitat[20, 20] <- 1

  values <- terra::values(distance_to_nearest_habitat(habitat, 50))[, 1]
  truth <- brute_force_distance(habitat)
  in_reach <- truth <= 50

  expect_equal(values[in_reach], truth[in_reach])
})
