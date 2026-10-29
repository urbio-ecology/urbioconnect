test_that("effective_mesh_size computes correctly in hectares", {
  # Single patch: sum(a^2)/sum(a) * 0.0001 = a * 0.0001
  expect_equal(
    effective_mesh_size(area = 10000),
    1
  )

  # Two equal patches: (5000^2 + 5000^2) / 10000 * 0.0001 = 0.5
  expect_equal(
    effective_mesh_size(
      area = c(5000, 5000)
    ),
    0.5
  )
})

test_that("effective_mesh_size is smaller for fragmented habitat", {
  # One big patch vs two halves - fragmentation reduces effective mesh size
  unfrag <- effective_mesh_size(area = 10000)
  frag <- effective_mesh_size(area = c(5000, 5000))
  expect_gt(unfrag, frag)
})

test_that("mean_patch_size returns mean of input", {
  expect_equal(mean_patch_size(area = c(100, 300)), 200)
  expect_equal(mean_patch_size(area = c(250)), 250)
})

test_that("n_patches counts correctly", {
  expect_equal(n_patches(area = c(100, 200, 300)), 3)
  expect_equal(n_patches(area = c(500)), 1)
  expect_equal(n_patches(area = numeric(0)), 0)
})

test_that("total_habitat_area converts square metres to hectares", {
  expect_equal(total_habitat_area(area = 10000), 1)
  expect_equal(total_habitat_area(area = c(20000, 30000)), 5)
})

test_that("connectivity_probability is 0.5 for two equal patches", {
  frag <- connectivity_probability(
    effective_mesh_ha = effective_mesh_size(area = c(5000, 5000)),
    area_baseline_ha = total_habitat_area(area = c(5000, 5000))
  )
  expect_equal(frag, 0.5)
})

test_that("connectivity_probability matches the unitless formula from areas", {
  # the hectare conversions in both helpers must cancel
  area <- lizard_areas_connected$area
  expect_equal(
    connectivity_probability(
      effective_mesh_ha = effective_mesh_size(area = area),
      area_baseline_ha = total_habitat_area(area = area)
    ),
    sum(area^2) / sum(area)^2
  )
})

test_that("a scenario's prob_connectedness is measured against the baseline total", {
  metrics <- connectivity_metrics(
    area = c(100, 200),
    area_baseline = c(100, 200, 300)
  )
  expect_equal(metrics$prob_connectedness, (100^2 + 200^2) / 600^2)
})

test_that("connectivity_probability errors unless given two single numbers", {
  expect_snapshot(error = TRUE, {
    connectivity_probability(effective_mesh_ha = c(1, 2), area_baseline_ha = 1)
  })
  expect_snapshot(error = TRUE, {
    connectivity_probability(
      effective_mesh_ha = 1,
      area_baseline_ha = lizard_areas_connected$area
    )
  })
  expect_snapshot(error = TRUE, {
    connectivity_probability(effective_mesh_ha = "1", area_baseline_ha = 1)
  })
})

test_that("summarise_connectivity returns a tibble with expected columns", {
  result <- summarise_connectivity(
    connectivity = 10000,
    interpatch_distance = 100,
    data_resolution = 10,
    species = "Test Species"
  )

  expect_s3_class(result, "tbl_df")
  expect_snapshot(names(result))
  expect_equal(nrow(result), 1)
  expect_snapshot(result)
})

test_that("summarise_connectivity stores a patch_size_tbl whichever method runs", {
  from_numeric <- summarise_connectivity(
    connectivity = c(100, 200, 300),
    interpatch_distance = 10,
    data_resolution = 2,
    species = "Test Species"
  )

  expect_s3_class(patch_sizes(from_numeric)[[1]], "patch_size_tbl")
  expect_s3_class(
    patch_sizes(summarise_connectivity(lizard_areas_connected))[[1]],
    "patch_size_tbl"
  )
})

test_that("summarise_connectivity works with patch_size data", {
  expect_snapshot(
    summarise_connectivity(lizard_areas_connected)
  )
  expect_snapshot(
    summarise_connectivity(
      connectivity = lizard_areas_connected
    )
  )
})
