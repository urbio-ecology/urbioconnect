test_that("effective_mesh_size with many equal patches scales correctly", {
  # 10 patches of 1000 sq m each vs 1 patch of 10000 sq m
  # With 10 equal patches: sum(1000^2 * 10) / 10000 * 0.0001 = 1e7/1e4 * 1e-4 = 0.1
  # With 1 patch of 10000: 1e8/1e4 * 1e-4 = 1.0
  many <- effective_mesh_size(area = rep(1000, 10))
  one <- effective_mesh_size(area = 10000)

  expect_lt(many, one)
  expect_equal(many, 0.1)
})

test_that("total_habitat_area is additive", {
  combined <- total_habitat_area(c(10000, 20000, 30000))
  separate <- total_habitat_area(10000) +
    total_habitat_area(20000) +
    total_habitat_area(30000)

  expect_equal(combined, separate)
})

test_that("n_patches handles single-element input", {
  expect_equal(n_patches(42), 1)
})

test_that("mean_patch_size with identical patches equals that patch size", {
  expect_equal(mean_patch_size(rep(500, 10)), 500)
})

test_that("summarise_connectivity with multiple Interpatch distance distances stays one row each", {
  # Called once per interpatch distance - should always return exactly 1 row
  purrr::walk(c(50, 100, 200), function(dist) {
    result <- summarise_connectivity(
      connectivity = c(5000, 5000),
      interpatch_distance = dist,
      data_resolution = 10,
      species = "Wren"
    )
    expect_equal(nrow(result), 1)
    expect_equal(result$interpatch_distance, dist)
  })
})

test_that("connectivity_probability with single large patch equals single small patch", {
  small_area <- 1000
  large_area <- 100000
  effective_mesh_small <- effective_mesh_size(
    area = small_area
  )
  effective_mesh_large <- effective_mesh_size(
    area = large_area
  )
  # For one patch: prob = (A^2/A * 0.0001) / A = 0.0001 regardless of area
  small <- connectivity_probability(effective_mesh_small, small_area)
  large <- connectivity_probability(effective_mesh_large, large_area)

  expect_equal(small, large)
  expect_equal(small, 0.0001)
})
