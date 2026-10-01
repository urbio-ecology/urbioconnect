# Helper: simple 100x100m habitat square in UTM Zone 54S
square <- function(xmin, ymin, size = 100) {
  sf::st_polygon(list(cbind(
    c(xmin, xmin + size, xmin + size, xmin, xmin),
    c(ymin, ymin, ymin + size, ymin + size, ymin)
  )))
}

test_that("sf_habitat_buffer expands area", {
  habitat <- sf::st_sfc(square(0, 0), crs = 32754)

  area_before <- as.numeric(sf::st_area(habitat))
  buffered <- sf_habitat_buffer(habitat, buffer_radius = 50)
  area_after <- as.numeric(sf::st_area(buffered))

  expect_gt(area_after, area_before)
})

test_that("sf_habitat_buffer with large buffer_radius unions separate patches", {
  habitat <- sf::st_sfc(square(0, 0), square(1000, 0), crs = 32754)

  # Buffer radius of 600m spans the 1000m gap between patches
  buffered <- sf_habitat_buffer(habitat, buffer_radius = 600)

  expect_equal(length(buffered), 1)
})

test_that("sf_habitat_buffer with small buffer_radius keeps patches separate", {
  habitat <- sf::st_sfc(square(0, 0), square(1000, 0), crs = 32754)

  # Buffer radius of 50m does not span the 1000m gap
  buffered <- sf_habitat_buffer(habitat, buffer_radius = 50)

  # Should be a multipolygon (still two separate blobs)
  expect_true(sf::st_is(buffered, "MULTIPOLYGON"))
})

test_that("sf_add_patch_area adds area column in square metres", {
  patches <- sf::st_sf(
    patch_id = 1L,
    geometry = sf::st_sfc(square(0, 0), crs = 32754)
  )

  result <- sf_add_patch_area(patches)
  expect_true("area" %in% names(result))
  expect_snapshot(result)
  expect_s3_class(result$area, "units")
  expect_gt(as.numeric(result$area), 0)
})

test_that("sf_aggregate_connected_patches groups by patch_id", {
  # Two patches with patch_id=1 and one with patch_id=2
  patches <- sf::st_sf(
    patch_id = c(1L, 1L, 2L),
    geometry = sf::st_sfc(
      square(0, 0),
      square(200, 0),
      square(500, 0),
      crs = 32754
    )
  ) |>
    sf_add_patch_area()

  result <- sf_aggregate_connected_patches(patches)

  expect_gt(result$area[1], result$area[2])
  expect_gt(result$area_squared[1], result$area_squared[2])
  expect_equal(nrow(result), 2)
  expect_snapshot(names(result))
  expect_all_true(as.numeric(result$area) > 0)
  expect_equal(result$area_squared, result$area^2)
})

test_that("sf_aggregate_connected_patches computes area_squared correctly", {
  patches <- sf::st_sf(
    patch_id = c(1L),
    geometry = sf::st_sfc(square(0, 0), crs = 32754)
  ) |>
    sf_add_patch_area()

  result <- sf_aggregate_connected_patches(patches)

  expect_equal(result$area_squared, result$area^2)
})

test_that("sf_drop_habitat_under_barrier removes overlapping habitat", {
  habitat <- sf::st_sfc(square(0, 0, size = 200), crs = 32754)
  # Barrier splits habitat down the middle (x=80 to x=120)
  barrier <- sf::st_sfc(square(80, 0, size = 40), crs = 32754) |>
    sf::st_set_crs(32754)

  remaining <- sf_drop_habitat_under_barrier(habitat, barrier)

  expect_lt(sf::st_area(remaining), sf::st_area(habitat))
})

test_that("sf_habitat_connectivity returns a data frame with expected columns", {
  # Two patches separated by a wide barrier
  habitat <- sf::st_sfc(square(0, 0), square(300, 0), crs = 32754)
  barrier <- sf::st_sfc(square(90, 0, size = 120), crs = 32754)

  result <- sf_habitat_connectivity(
    habitat = habitat,
    barrier = barrier,
    species = "lizard",
    interpatch_distance = 400
  )

  expect_s3_class(result, "patch_size_tbl")
  expect_snapshot(names(result))
  expect_gt(nrow(result), 0)
  expect_all_true(as.numeric(result$area) > 0)
})
