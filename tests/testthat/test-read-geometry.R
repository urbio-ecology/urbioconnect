test_that("read_geometry returns an sfc object", {
  shp_path <- system.file("ex/lizard_barrier.shp", package = "urbioconnect")
  result <- read_geometry(shp_path)

  expect_s3_class(result, "sfc")
})

test_that("read_geometry reads a file without printing", {
  shp_path <- system.file("ex/lizard_barrier.shp", package = "urbioconnect")

  expect_silent(read_geometry(shp_path))
})

test_that("read_geometry strips attribute columns", {
  shp_path <- system.file("ex/lizard_barrier.shp", package = "urbioconnect")
  result <- read_geometry(shp_path)

  # sfc objects have no attribute columns (only geometry)
  expect_false(inherits(result, "sf"))
})

test_that("read_geometry accepts an sf object directly", {
  shp_path <- system.file("ex/lizard_barrier.shp", package = "urbioconnect")
  sf_obj <- sf::st_read(shp_path, quiet = TRUE)

  result <- read_geometry(sf_obj)

  expect_true(inherits(result, "sfc"))
})
