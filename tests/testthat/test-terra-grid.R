test_that("empty_grid returns a SpatRaster with no values set", {
  habitat <- example_habitat()
  grid <- empty_grid(habitat, resolution = 10)

  expect_s4_class(grid, "SpatRaster")
  expect_false(terra::hasValues(grid))
})

test_that("empty_grid resolution matches requested resolution", {
  habitat <- example_habitat()
  grid <- empty_grid(habitat, resolution = 20)

  expect_equal(terra::res(grid), c(20, 20), tolerance = 0.01)
})

test_that("empty_grid extent matches habitat extent", {
  habitat <- example_habitat()
  grid <- empty_grid(habitat, resolution = 10)

  # Extents should be equal
  expect_true(terra::all.equal(terra::ext(grid), terra::ext(habitat)))
})

test_that("empty_grid CRS matches habitat CRS", {
  habitat <- example_habitat()
  grid <- empty_grid(habitat, resolution = 10)

  expect_equal(terra::crs(grid), terra::crs(habitat))
})

test_that("prepare_rasters returns list with habitat_raster and barrier_raster", {
  habitat_shp <- example_barrier_shp() # re-use as simple sf for testing
  barrier_shp <- example_barrier_shp()

  result <- prepare_rasters(
    habitat = habitat_shp,
    barrier = barrier_shp,
    data_resolution = 10
  )

  expect_type(result, "list")
  expect_snapshot(names(result))
  expect_s4_class(result$habitat_raster, "SpatRaster")
  expect_s4_class(result$barrier_raster, "SpatRaster")
})

test_that("prepare_rasters habitat and barrier rasters share the same extent", {
  habitat_shp <- example_barrier_shp()
  barrier_shp <- example_barrier_shp()

  result <- prepare_rasters(
    habitat_shp,
    barrier_shp,
    data_resolution = 10
  )

  expect_true(
    terra::compareGeom(
      result$habitat_raster,
      result$barrier_raster,
      stopOnError = FALSE
    )
  )
})

test_that("prepare_rasters() ends the grid at the edge of the habitat", {
  habitat <- example_habitat()
  edge <- as.vector(terra::ext(habitat))

  # the barrier reaches about 20 m past the habitat on every side
  layers <- prepare_rasters(
    habitat,
    example_barrier_shp(),
    data_resolution = 10
  )

  expect_identical(as.vector(terra::ext(layers$habitat_raster)), edge)
  expect_identical(as.vector(terra::ext(layers$barrier_raster)), edge)
})

test_that("a barrier that runs to the edge of the habitat keeps patches apart", {
  blank <- terra::rast(
    terra::ext(0, 600, 0, 600),
    res = 10,
    crs = "EPSG:32754"
  )
  habitat <- terra::init(blank, NA_real_)
  habitat[, c(1:29, 32:60)] <- 1
  barrier <- terra::init(blank, 0)
  barrier[, 30:31] <- 1

  rasters <- prepare_rasters(
    habitat,
    barrier,
    data_resolution = 10
  )
  result <- habitat_connectivity(
    rasters$habitat_raster,
    rasters$barrier_raster,
    species = "test",
    interpatch_distance = 100,
    verbose = FALSE
  )

  expect_equal(result$n_patches, 2)
})
