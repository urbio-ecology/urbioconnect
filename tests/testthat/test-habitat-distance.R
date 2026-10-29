test_that("nearest_habitat_distance() is the exact Euclidean distance", {
  # Scattered habitat on deliberately non-square cells, which is where an
  # approximate distance shows up. Checked against every pairwise distance.
  habitat <- test_raster(23, 27, cell = c(3, 2))
  withr::local_seed(1)
  terra::values(habitat) <- ifelse(runif(terra::ncell(habitat)) < 0.05, 1, NA)

  surface <- nearest_habitat_distance(habitat, max_distance = Inf)

  expect_equal(terra::values(surface)[, 1], brute_force_distance(habitat))
})

test_that("nearest_habitat_distance() is exact for every cell within max_distance", {
  habitat <- test_raster(40, 40)
  habitat[20, 20] <- 1

  values <- terra::values(nearest_habitat_distance(habitat, 50))[, 1]
  truth <- brute_force_distance(habitat)
  within <- truth <= 50

  expect_equal(values[within], truth[within])
})

test_that("a landscape with no habitat has nothing within any radius", {
  habitat <- test_raster(10, 10)

  surface <- nearest_habitat_distance(habitat, max_distance = 50)

  expect_all_true(is.na(terra::values(habitat_within(surface, 50))[, 1]))
})

test_that("habitat_buffer() handles a raster one cell wide or tall", {
  strip <- function(nrows, ncols) {
    layer <- test_raster(nrows, ncols)
    layer[1, 1] <- 1
    layer
  }

  expect_no_warning(wide <- habitat_buffer(strip(1, 5), 20))
  expect_no_warning(tall <- habitat_buffer(strip(5, 1), 20))
  expect_equal(terra::values(wide)[, 1], c(1, 1, 1, NA, NA))
  expect_equal(terra::values(tall)[, 1], c(1, 1, 1, NA, NA))
})

test_that("a habitat layer with several layers is an error", {
  layer <- test_raster(10, 10)
  layer[5, 5] <- 1
  stacked <- c(layer, layer)

  expect_snapshot(error = TRUE, {
    habitat_buffer(stacked, 20)
    habitat_connectivity(stacked, layer, "lizard", 40, verbose = FALSE)
  })
})

test_that("habitat_buffer() names itself in a radius error", {
  layer <- test_raster(10, 10)
  layer[5, 5] <- 1

  expect_snapshot(error = TRUE, habitat_buffer(layer, -20))
})

test_that("habitat_buffer() keeps the cells the focal buffer kept", {
  habitat <- example_habitat()
  extent <- terra::ext(habitat)
  crop <- terra::crop(
    habitat,
    terra::ext(
      extent$xmin,
      extent$xmin + 300,
      extent$ymax - 300,
      extent$ymax
    )
  )

  new <- habitat_buffer(crop, 20)

  window <- terra::focalMat(crop, d = 20, type = "circle")
  window <- window / max(window)
  focal <- terra::focal(crop, w = window, fun = max, na.rm = TRUE)
  focal[focal != 1] <- NA

  expect_equal(
    !is.na(terra::values(new)[, 1]),
    !is.na(terra::values(focal)[, 1])
  )
})

test_that("is_habitat() counts a cell as habitat unless it is NA or zero", {
  # absence arrives as NA from onto_grid() and as 0 from a GeoTIFF
  expect_equal(
    is_habitat(c(1, NA, 0, 2, -1, NaN)),
    c(TRUE, FALSE, FALSE, TRUE, TRUE, FALSE)
  )
})

test_that("habitat_buffer() reaches exactly as far as asked on non-square cells", {
  habitat <- test_raster(21, 21, cell = c(3, 2), fill = 0)
  habitat[11, 11] <- 1
  habitat[3, 5] <- 2

  # 9 m is not a multiple of the 2 m rows, which warns and isn't the point here
  buffered <- suppressWarnings(habitat_buffer(habitat, c(9, 6)))
  truth <- brute_force_distance(habitat)

  expect_snapshot(names(buffered))
  expect_equal(!is.na(terra::values(buffered)[, 1]), truth <= 9)
  expect_equal(!is.na(terra::values(buffered)[, 2]), truth <= 6)
})

test_that("habitat_buffer() keeps a cell exactly one radius away", {
  # in floating point 3 * 0.1 is past 0.3, and 4.3 / 0.1 is short of 43
  strip <- test_raster(101, 1, cell = c(0.1, 0.1))
  strip[51, 1] <- 1

  expect_no_warning(buffered <- habitat_buffer(strip, c(0.3, 0.4, 1.1, 4.3)))

  rows_reached <- (colSums(!is.na(terra::values(buffered))) - 1) / 2
  expect_equal(unname(rows_reached), c(3, 4, 11, 43))
})

test_that("habitat_buffer() warns below one cell and keeps only the habitat", {
  layer <- test_raster(10, 10, fill = 0)
  layer[5, 5] <- 2

  expect_snapshot(buffered <- habitat_buffer(layer, c(5, 20)))

  expect_equal(
    !is.na(terra::values(buffered)[, 1]),
    is_habitat(terra::values(layer)[, 1])
  )
})

test_that("habitat_buffer() judges 'below one cell' by the smaller cell side", {
  layer <- test_raster(10, 10, cell = c(10, 9.5))
  layer[5, 5] <- 1

  # 9.7 m reaches the vertical neighbours, 9.5 m away, but not the 10 m ones
  expect_snapshot(buffered <- habitat_buffer(layer, 9.7))

  expect_equal(
    terra::values(buffered)[, 1][
      c(
        terra::cellFromRowCol(layer, 4, 5),
        terra::cellFromRowCol(layer, 5, 4)
      )
    ],
    c(1, NA)
  )
})
