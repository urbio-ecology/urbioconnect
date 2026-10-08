test_that("habitat_connectivity_comparison() scalar distance gives one block of 4 rows", {
  # the one test here on a real landscape, for the content snapshot. The rest
  # use synthetic layers. Lizard rather than wren: still real spatial data,
  # and a quarter of the cells.
  layers <- lizard_scenario_layers()

  results <- habitat_connectivity_comparison(
    habitat_scenario = layers$habitat,
    barrier_scenario = layers$barrier_scenario,
    habitat_baseline = layers$habitat,
    barrier_baseline = layers$barrier,
    species = "Blue Tongue Lizard",
    interpatch_distance = 40,
    verbose = FALSE
  )

  expect_s3_class(results, "compare_connectivity")
  expect_equal(nrow(results), 4)
  expect_snapshot(results)
})

test_that("habitat_connectivity_comparison() vector distance stacks per distance", {
  # synthetic: how the blocks stack doesn't depend on the landscape, and the
  # wren rasters cost ~8s a distance. The test above keeps them for content.
  layers <- scenario_test_layers()

  results <- habitat_connectivity_comparison(
    habitat_scenario = layers$habitat,
    barrier_scenario = layers$barrier_scenario,
    habitat_baseline = layers$habitat,
    barrier_baseline = layers$barrier,
    species = "Superb Fairy Wren",
    interpatch_distance = c(40, 80),
    verbose = FALSE
  )

  expect_s3_class(results, "compare_connectivity")
  expect_equal(nrow(results), 8)
  expect_setequal(results$interpatch_distance, c(40, 80))
  expect_snapshot(results)
})

test_that("habitat_connectivity_comparison() passes scenario_name through", {
  layers <- scenario_test_layers()

  results <- habitat_connectivity_comparison(
    habitat_scenario = layers$habitat,
    barrier_scenario = layers$barrier_scenario,
    habitat_baseline = layers$habitat,
    barrier_baseline = layers$barrier,
    species = "Test Species",
    interpatch_distance = 40,
    scenario_name = "Bentley Project",
    verbose = FALSE
  )

  expect_equal(results$scenario_name, rep("Bentley Project", 4))
})

test_that("habitat_connectivity_comparison() rejects a missing or empty distance", {
  layers <- scenario_test_layers()

  comparison_at <- function(...) {
    habitat_connectivity_comparison(
      habitat_scenario = layers$habitat,
      barrier_scenario = layers$barrier_scenario,
      habitat_baseline = layers$habitat,
      barrier_baseline = layers$barrier,
      species = "Test Species",
      verbose = FALSE,
      ...
    )
  }

  expect_snapshot(error = TRUE, {
    comparison_at()
    comparison_at(interpatch_distance = numeric(0))
  })
})

test_that("habitat_connectivity_comparison() warns and returns zero change when scenario equals baseline", {
  layers <- scenario_test_layers()

  expect_warning(
    results <- habitat_connectivity_comparison(
      habitat_scenario = layers$habitat,
      barrier_scenario = layers$barrier,
      habitat_baseline = layers$habitat,
      barrier_baseline = layers$barrier,
      species = "Superb Fairy Wren",
      interpatch_distance = 40,
      verbose = FALSE
    ),
    "identical to the baseline"
  )

  expect_s3_class(results, "compare_connectivity")
  change_row <- results[results$measure == "change", ]
  metric_cols <- c(
    "n_patches",
    "effective_mesh_ha",
    "prob_connectedness",
    "patch_area_mean",
    "patch_area_total_ha"
  )
  purrr::walk(
    change_row[metric_cols],
    \(col) expect_true(all(col == 0))
  )
})

test_that("habitat_connectivity_comparison() aborts when both layers differ", {
  # these guards fire before any pipeline runs, so the landscape is irrelevant
  layers <- scenario_test_layers()

  expect_snapshot(
    habitat_connectivity_comparison(
      habitat_scenario = layers$habitat_scenario,
      barrier_scenario = layers$barrier_scenario,
      habitat_baseline = layers$habitat,
      barrier_baseline = layers$barrier,
      species = "Superb Fairy Wren",
      interpatch_distance = 40,
      verbose = FALSE
    ),
    error = TRUE
  )
})

test_that("habitat_connectivity_comparison() aborts on a scenario elsewhere", {
  # a scenario on its own grid used to compare fine, and report the change of
  # place as a change in connectivity
  layers <- scenario_test_layers()
  elsewhere <- terra::shift(terra::deepcopy(layers$barrier), dx = 5000)

  expect_snapshot(
    habitat_connectivity_comparison(
      habitat_scenario = layers$habitat,
      barrier_scenario = elsewhere,
      habitat_baseline = layers$habitat,
      barrier_baseline = layers$barrier,
      species = "Superb Fairy Wren",
      interpatch_distance = 40,
      verbose = FALSE
    ),
    error = TRUE
  )

  coarser <- terra::aggregate(terra::deepcopy(layers$barrier), fact = 2)

  expect_snapshot(
    habitat_connectivity_comparison(
      habitat_scenario = layers$habitat,
      barrier_scenario = coarser,
      habitat_baseline = layers$habitat,
      barrier_baseline = layers$barrier,
      species = "Superb Fairy Wren",
      interpatch_distance = 40,
      verbose = FALSE
    ),
    error = TRUE
  )
})
