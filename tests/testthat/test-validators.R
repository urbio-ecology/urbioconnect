test_that("patch_size_tbl works", {
  expect_snapshot(
    patch_size_tbl(
      data = data.frame(area = 1:10, patch_id = 1:10),
      species = "birds",
      interpatch_distance = 10,
      res = c(1, 1)
    )
  )
})

test_that("validate_patch_size_tbl works", {
  expect_snapshot(
    error = TRUE,
    validate_patch_size_tbl(iris)
  )
  expect_snapshot(
    validate_patch_size_tbl(lizard_areas_connected)
  )
  altered_lizard_areas <- lizard_areas_connected |>
    dplyr::rename(bananas = patch_id)
  expect_snapshot(
    error = TRUE,
    validate_patch_size_tbl(altered_lizard_areas)
  )
})

test_that("check_scalar works as expected", {
  expect_snapshot(
    error = TRUE,
    check_scalar(1:3)
  )
  expect_snapshot(
    error = TRUE,
    check_scalar(LETTERS[1:3])
  )
  expect_snapshot(
    error = TRUE,
    check_scalar(c(TRUE, FALSE, TRUE))
  )
  expect_snapshot(check_scalar(1))
  expect_snapshot(check_scalar("1"))
  expect_snapshot(check_scalar(TRUE))
})

birds_r1_i8 <- new_patch_size_tbl(
  data = data.frame(patch_id = 1:5, area = 5:1),
  res = c(1, 1),
  species = "birds",
  interpatch_distance = 8
)

birds_r1_i10 <- new_patch_size_tbl(
  data = data.frame(patch_id = 1:5, area = 5:1),
  res = c(1, 1),
  species = "birds",
  interpatch_distance = 10
)

birds_r2_i10 <- new_patch_size_tbl(
  data = data.frame(patch_id = 1:5, area = 5:1),
  res = c(2, 2),
  species = "birds",
  interpatch_distance = 10
)

birds_r2_i8 <- new_patch_size_tbl(
  data = data.frame(patch_id = 1:5, area = 5:1),
  res = c(2, 2),
  species = "birds",
  interpatch_distance = 8
)

cats_r1_i8 <- new_patch_size_tbl(
  data = data.frame(patch_id = 1:5, area = 5:1),
  res = c(1, 1),
  species = "cats",
  interpatch_distance = 8
)


test_that("check_pc_match errors appropriately", {
  expect_silent(check_pc_match(birds_r1_i8, birds_r1_i8))
  expect_snapshot(
    error = TRUE,
    check_pc_match(birds_r1_i8, birds_r1_i10)
  )
  expect_snapshot(
    error = TRUE,
    check_pc_match(birds_r1_i8, cats_r1_i8)
  )
  expect_snapshot(
    error = TRUE,
    check_pc_match(birds_r1_i8, birds_r2_i8)
  )
})

test_that("check_pc_match reports the caller-supplied argument names", {
  # compare_connectivity() passes arg = "scenario" / arg_baseline = "baseline"
  # so the mismatch message names its public arguments, not the internals.
  expect_snapshot(
    error = TRUE,
    check_pc_match(
      birds_r1_i8,
      cats_r1_i8,
      arg = "scenario",
      arg_baseline = "baseline"
    )
  )
})

# Helper: small raster with sequential values
differ_rast <- function(nrows = 4, ncols = 4) {
  terra::rast(nrows = nrows, ncols = ncols, vals = seq_len(nrows * ncols))
}

# Helper: simple 100x100m polygon
differ_square <- function(xmin = 0, ymin = 0, size = 100) {
  sf::st_sfc(
    sf::st_polygon(list(cbind(
      c(xmin, xmin + size, xmin + size, xmin, xmin),
      c(ymin, ymin, ymin + size, ymin + size, ymin)
    ))),
    crs = 32754
  )
}

test_that("layers_differ is FALSE for identical rasters", {
  r <- differ_rast()
  expect_false(layers_differ(r, terra::deepcopy(r)))
})

test_that("layers_differ is TRUE for value-perturbed rasters", {
  r <- differ_rast()
  r_perturbed <- terra::deepcopy(r)
  r_perturbed[1, 1] <- 999
  expect_true(layers_differ(r, r_perturbed))
})

test_that("layers_differ is TRUE for different-geometry rasters", {
  r <- differ_rast(nrows = 4, ncols = 4)
  r_bigger <- differ_rast(nrows = 5, ncols = 5)
  expect_true(layers_differ(r, r_bigger))
})

test_that("layers_differ is FALSE for identical sf polygons", {
  poly <- differ_square()
  expect_false(layers_differ(poly, differ_square()))
})

test_that("layers_differ is TRUE for perturbed sf polygons", {
  poly <- differ_square()
  poly_perturbed <- differ_square(size = 200)
  expect_true(layers_differ(poly, poly_perturbed))
})

test_that("layers_differ handles SpatVectors", {
  v <- terra::vect(differ_square())
  expect_false(layers_differ(v, terra::vect(differ_square())))
  expect_true(layers_differ(v, terra::vect(differ_square(size = 200))))
})
