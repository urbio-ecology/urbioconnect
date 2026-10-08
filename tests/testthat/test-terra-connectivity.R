# Helper: create a small raster with uniform values
small_rast <- function(nrows = 5, ncols = 5, val = NA) {
  terra::rast(nrows = nrows, ncols = ncols, vals = val)
}

# Determine the flattened index from row/col in a row-major raster
index_from_ij <- function(mat, i, j) {
  (ncol(mat) * (i - 1)) + j
}

index_mat <- function(i, j) {
  n <- seq_len(i * j)
  matrix(n, i, j, byrow = TRUE)
}

create_index_mat <- function(mat) {
  i <- nrow(mat)
  j <- ncol(mat)
  index_mat(i, j)
}


test_that("create_barrier_mask converts 1s to NA and NAs to 1s", {
  r <- small_rast(nrows = 5, ncols = 5, val = NA)
  row_i <- 2
  col_j <- 2
  r[row_i, col_j] <- 1 # centre cell is a barrier

  mask <- create_barrier_mask(r)
  vals <- as.numeric(terra::values(mask))

  centre_cell_idx <- index_from_ij(r, row_i, col_j)
  # Centre cell (index 7 in 5x5 row-major: row 2, col 2) should be NA
  expect_true(is.na(vals[centre_cell_idx]))
  # All other cells (previously NA) should be 1
  expect_true(all(vals[-centre_cell_idx] == 1, na.rm = TRUE))
  expect_false(anyNA(vals[-centre_cell_idx]))
})

test_that("create_barrier_mask on all-NA raster produces all-1 raster", {
  r <- small_rast(val = NA)
  mask <- create_barrier_mask(r)
  vals <- as.numeric(terra::values(mask))

  expect_true(all(vals == 1))
  expect_false(anyNA(vals))
})

test_that("drop_habitat_under_barrier removes habitat cells covered by barriers", {
  # All-habitat raster
  habitat <- small_rast(val = 1)

  # Barrier at centre cell
  barrier <- small_rast(val = NA)
  idx_i <- 2
  idx_j <- 2
  barrier[idx_i, idx_j] <- 1
  barrier_mask <- create_barrier_mask(barrier)

  remaining <- drop_habitat_under_barrier(habitat, barrier_mask)
  vals <- as.numeric(terra::values(remaining))

  centre_cell_idx <- index_from_ij(barrier, idx_i, idx_j)
  # Centre cell should now be NA
  expect_true(is.na(vals[centre_cell_idx]))
  # All other cells should remain 1
  expect_true(all(vals[-centre_cell_idx] == 1, na.rm = TRUE))
})

test_that("fragment_habitat cuts interpatch distance at barrier cells", {
  buffered <- small_rast(val = 1)

  # Vertical barrier through centre column (col 3 of 5)
  barrier <- small_rast(val = NA)
  idx_i <- 1:5
  idx_j <- 3
  barrier[idx_i, idx_j] <- 1
  barrier_mask <- create_barrier_mask(barrier)

  fragmented <- fragment_habitat(buffered, barrier_mask)
  vals <- as.numeric(terra::values(fragmented))

  # Centre column indices in a 5x5 row-major raster: 3, 8, 13, 18, 23
  centre_col <- create_index_mat(barrier)[idx_i, idx_j]
  expect_true(all(is.na(vals[centre_col])))
  # Cells outside the barrier should remain non-NA
  expect_all_false(is.na(vals[-centre_col]))
})

lizard_habitat <- example_habitat()
lizard_barrier <- example_barrier()

# Run the full pipeline once on real lizard data; extract components so that
# habitat_buffer (the slow step) only runs once across the whole file
hcf_quiet <- habitat_connectivity_full(
  lizard_habitat,
  lizard_barrier,
  interpatch_distance = 50,
  verbose = FALSE
)
hc_quiet <- hcf_quiet$areas_connected
buffered <- hcf_quiet$buffered_habitat
barrier_mask <- hcf_quiet$barrier_mask
remaining <- hcf_quiet$remaining_habitat
patch_areas <- hcf_quiet$patch_id_raster

# fragment_habitat and assign_patches_to_fragments are fast (<1s) so we
# recompute them from the already-extracted components
fragmented <- fragment_habitat(buffered, barrier_mask)
patches <- assign_patches_to_fragments(remaining, fragmented)

test_that("habitat_buffer expands non-NA habitat area", {
  n_before <- sum(!is.na(terra::values(lizard_habitat)))
  n_after <- sum(!is.na(terra::values(buffered)))

  expect_gt(n_after, n_before)
})

test_that("add_patch_area returns a two-layer raster named patch_id and area", {
  result <- add_patch_area(patches)
  expect_equal(terra::nlyr(result), 2)
  expect_snapshot(names(result))
})

res_con_patch <- aggregate_connected_patches(patch_areas)
test_that("aggregate_connected_patches returns tibble with correct columns", {
  expect_s3_class(res_con_patch, "tbl_df")
  expect_snapshot(names(res_con_patch))
  expect_gt(nrow(res_con_patch), 0)
  expect_all_true(res_con_patch$area > 0)
})

test_that("aggregate_connected_patches area_squared equals area squared", {
  # area_squared = area^2, then both rounded to 3 dp
  expect_equal(res_con_patch$area_squared, round(res_con_patch$area^2, 3))
})

# Small projected raster for fast coverage of verbose=TRUE code paths
small_habitat <- terra::rast(
  nrows = 20,
  ncols = 20,
  extent = terra::ext(0, 2000, 0, 2000),
  crs = terra::crs(lizard_habitat),
  vals = 1
)
small_barrier <- terra::rast(
  nrows = 20,
  ncols = 20,
  extent = terra::ext(0, 2000, 0, 2000),
  crs = terra::crs(lizard_habitat),
  vals = NA
)
small_barrier[10, 10] <- 1

hc_verbose <- habitat_connectivity(
  small_habitat,
  small_barrier,
  species = "lizard",
  interpatch_distance = 200,
  verbose = TRUE
)

test_that("habitat_connectivity verbose=TRUE returns a data frame", {
  expect_s3_class(hc_verbose, "data.frame")
})

test_that("habitat_connectivity returns a data frame with expected columns", {
  expect_s3_class(hc_quiet, "data.frame")
  expect_snapshot(names(hc_quiet))
  expect_gt(nrow(hc_quiet), 0)
})

test_that("align_to resamples rasters with mismatched geometry", {
  # Fine-resolution habitat, coarse-resolution barrier
  habitat <- terra::rast(
    nrows = 100,
    ncols = 100,
    extent = terra::ext(0, 1000, 0, 1000),
    vals = 1
  )
  barrier <- terra::rast(
    nrows = 50,
    ncols = 50,
    extent = terra::ext(0, 1000, 0, 1000),
    vals = NA
  )
  barrier[25, 25] <- 1
  barrier_mask <- create_barrier_mask(barrier)

  # drop_habitat_under_barrier calls align_to internally when geometries differ
  result <- drop_habitat_under_barrier(habitat, barrier_mask)
  expect_true(inherits(result, "SpatRaster"))
  expect_true(terra::compareGeom(result, habitat, stopOnError = FALSE))
})

hcf_verbose <- habitat_connectivity_full(
  small_habitat,
  small_barrier,
  interpatch_distance = 200,
  verbose = TRUE
)

test_that("habitat_connectivity_full verbose=TRUE returns a list", {
  expect_type(hcf_verbose, "list")
})

test_that("habitat_connectivity_full returns list with expected elements", {
  expect_type(hcf_quiet, "list")
  expect_snapshot(names(hcf_quiet))
  expect_s3_class(hcf_quiet$areas_connected, "data.frame")
  expect_s4_class(hcf_quiet$buffered_habitat, "SpatRaster")
})

test_that("onto_grid puts a vector and a raster layer on the same grid", {
  grid <- empty_grid(example_barrier_shp(), resolution = 10)

  from_vector <- onto_grid(example_barrier_shp(), grid, background = 0)
  from_raster <- onto_grid(example_habitat(), grid, background = NA)

  purrr::walk(list(from_vector, from_raster), function(layer) {
    expect_equal(terra::res(layer), terra::res(grid))
    expect_equal(as.vector(terra::ext(layer)), as.vector(terra::ext(grid)))
  })

  # background says what an empty cell means: a barrier's are 0, so nothing is
  # missing, while a habitat's are NA
  expect_equal(sum(is.na(terra::values(from_vector))), 0)
  expect_gt(sum(is.na(terra::values(from_raster))), 0)
})

test_that("prepare_rasters takes a raster layer as well as a vector one", {
  # the app offers GeoTIFF uploads, which used to fail inside terra::rasterize
  # with "unable to find an inherited method"
  prepared <- prepare_rasters(
    habitat = example_habitat(),
    barrier = example_barrier_shp()
  )

  expect_s4_class(prepared$habitat_raster, "SpatRaster")
  expect_equal(
    as.vector(terra::ext(prepared$habitat_raster)),
    as.vector(terra::ext(prepared$barrier_raster))
  )
})
