wren_habitat <- example_wren_habitat()
wren_barrier <- example_wren_barrier()
wren_barrier_scenario <- example_wren_barrier_scenario()

test_that("habitat_connectivity_comparison() scalar distance gives one block of 4 rows", {
  results <- habitat_connectivity_comparison(
    habitat_scenario = wren_habitat,
    barrier_scenario = wren_barrier_scenario,
    habitat_baseline = wren_habitat,
    barrier_baseline = wren_barrier,
    species = "Superb Fairy Wren",
    interpatch_distance = 200,
    verbose = FALSE
  )

  expect_s3_class(results, "compare_connectivity")
  expect_equal(nrow(results), 4)
  expect_snapshot(results)
})

test_that("habitat_connectivity_comparison() vector distance stacks per distance", {
  results <- habitat_connectivity_comparison(
    habitat_scenario = wren_habitat,
    barrier_scenario = wren_barrier_scenario,
    habitat_baseline = wren_habitat,
    barrier_baseline = wren_barrier,
    species = "Superb Fairy Wren",
    interpatch_distance = c(100, 200),
    verbose = FALSE
  )

  expect_s3_class(results, "compare_connectivity")
  expect_equal(nrow(results), 8)
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

test_that("habitat_connectivity_comparison() sweeps buffer_radius too", {
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

  by_radius <- comparison_at(buffer_radius = 20)

  expect_s3_class(by_radius, "compare_connectivity")
  expect_equal(nrow(by_radius), 4)
  # a buffer radius is half an interpatch distance, so these are the same run
  expect_equal(by_radius, comparison_at(interpatch_distance = 40))
})

test_that("habitat_connectivity_comparison() aborts when neither distance nor buffer supplied", {
  expect_snapshot(
    habitat_connectivity_comparison(
      habitat_scenario = wren_habitat,
      barrier_scenario = wren_barrier_scenario,
      habitat_baseline = wren_habitat,
      barrier_baseline = wren_barrier,
      species = "Superb Fairy Wren",
      verbose = FALSE
    ),
    error = TRUE
  )
})

test_that("habitat_connectivity_comparison() aborts when both distance and buffer supplied", {
  expect_snapshot(
    habitat_connectivity_comparison(
      habitat_scenario = wren_habitat,
      barrier_scenario = wren_barrier_scenario,
      habitat_baseline = wren_habitat,
      barrier_baseline = wren_barrier,
      species = "Superb Fairy Wren",
      interpatch_distance = 200,
      buffer_radius = 100,
      verbose = FALSE
    ),
    error = TRUE
  )
})

test_that("habitat_connectivity_comparison() warns and returns zero change when scenario equals baseline", {
  expect_warning(
    results <- habitat_connectivity_comparison(
      habitat_scenario = wren_habitat,
      barrier_scenario = wren_barrier,
      habitat_baseline = wren_habitat,
      barrier_baseline = wren_barrier,
      species = "Superb Fairy Wren",
      interpatch_distance = 200,
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
  wren_habitat_scenario <- terra::deepcopy(wren_habitat)
  wren_habitat_scenario[1, 1] <- 1

  expect_snapshot(
    habitat_connectivity_comparison(
      habitat_scenario = wren_habitat_scenario,
      barrier_scenario = wren_barrier_scenario,
      habitat_baseline = wren_habitat,
      barrier_baseline = wren_barrier,
      species = "Superb Fairy Wren",
      interpatch_distance = 200,
      verbose = FALSE
    ),
    error = TRUE
  )
})
