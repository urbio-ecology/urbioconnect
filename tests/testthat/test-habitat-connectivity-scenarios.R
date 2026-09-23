test_that("habitat_connectivity_scenarios() stacks habitat then barrier scenarios", {
  layers <- scenario_test_layers()

  results <- habitat_connectivity_scenarios(
    habitat_baseline = layers$habitat,
    barrier_baseline = layers$barrier,
    species = "Test Species",
    habitat_scenarios = list("Bentley Project" = layers$habitat_scenario),
    barrier_scenarios = list("Barrier upgrade" = layers$barrier_scenario),
    interpatch_distance = 40,
    verbose = FALSE
  )

  expect_s3_class(results, "compare_connectivity")
  expect_equal(
    results$scenario_name,
    rep(c("Bentley Project", "Barrier upgrade"), each = 4)
  )
  expect_snapshot(results)
})

test_that("habitat_connectivity_scenarios() takes either list on its own", {
  layers <- scenario_test_layers()

  habitat_only <- habitat_connectivity_scenarios(
    habitat_baseline = layers$habitat,
    barrier_baseline = layers$barrier,
    species = "Test Species",
    habitat_scenarios = list("Bentley Project" = layers$habitat_scenario),
    interpatch_distance = 40,
    verbose = FALSE
  )

  barrier_only <- habitat_connectivity_scenarios(
    habitat_baseline = layers$habitat,
    barrier_baseline = layers$barrier,
    species = "Test Species",
    barrier_scenarios = list("Barrier upgrade" = layers$barrier_scenario),
    interpatch_distance = 40,
    verbose = FALSE
  )

  expect_equal(nrow(habitat_only), 4)
  expect_equal(nrow(barrier_only), 4)
  expect_equal(unique(habitat_only$scenario_name), "Bentley Project")
  expect_equal(unique(barrier_only$scenario_name), "Barrier upgrade")
})

test_that("habitat_connectivity_scenarios() shares one baseline across scenarios", {
  layers <- scenario_test_layers()

  results <- habitat_connectivity_scenarios(
    habitat_baseline = layers$habitat,
    barrier_baseline = layers$barrier,
    species = "Test Species",
    habitat_scenarios = list("Bentley Project" = layers$habitat_scenario),
    barrier_scenarios = list("Barrier upgrade" = layers$barrier_scenario),
    interpatch_distance = 40,
    verbose = FALSE
  )

  baseline_rows <- results[results$measure == "baseline", ]

  expect_equal(nrow(baseline_rows), 2)
  expect_equal(baseline_rows$n_patches[1], baseline_rows$n_patches[2])
  expect_equal(
    baseline_rows$effective_mesh_ha[1],
    baseline_rows$effective_mesh_ha[2]
  )
})

test_that("habitat_connectivity_scenarios() runs every scenario per distance", {
  layers <- scenario_test_layers()

  results <- habitat_connectivity_scenarios(
    habitat_baseline = layers$habitat,
    barrier_baseline = layers$barrier,
    species = "Test Species",
    habitat_scenarios = list("Bentley Project" = layers$habitat_scenario),
    barrier_scenarios = list("Barrier upgrade" = layers$barrier_scenario),
    interpatch_distance = c(40, 80),
    verbose = FALSE
  )

  # 2 scenarios x 2 distances x 4 measures
  expect_equal(nrow(results), 16)
  expect_equal(
    unique(results$interpatch_distance),
    c(40, 80)
  )
})

test_that("habitat_connectivity_scenarios() warns on a scenario matching baseline", {
  layers <- scenario_test_layers()

  expect_snapshot(
    results <- habitat_connectivity_scenarios(
      habitat_baseline = layers$habitat,
      barrier_baseline = layers$barrier,
      species = "Test Species",
      habitat_scenarios = list("No change" = layers$habitat),
      interpatch_distance = 40,
      verbose = FALSE
    )
  )

  expect_equal(results$n_patches[results$measure == "change"], 0)
})

test_that("habitat_connectivity_scenarios() rejects a layer passed outside a list", {
  layers <- scenario_test_layers()

  # c() binds SpatRaster layers rather than erroring, so a bare layer used to
  # pass every name check and come back labelled "lyr.1"
  expect_snapshot(error = TRUE, {
    habitat_connectivity_scenarios(
      habitat_baseline = layers$habitat,
      barrier_baseline = layers$barrier,
      species = "Test Species",
      habitat_scenarios = layers$habitat_scenario,
      interpatch_distance = 40,
      verbose = FALSE
    )
    habitat_connectivity_scenarios(
      habitat_baseline = layers$habitat,
      barrier_baseline = layers$barrier,
      species = "Test Species",
      barrier_scenarios = layers$barrier_scenario,
      interpatch_distance = 40,
      verbose = FALSE
    )
  })
})

test_that("habitat_connectivity_scenarios() rejects missing or clashing names", {
  layers <- scenario_test_layers()

  expect_snapshot(error = TRUE, {
    # neither list supplied
    habitat_connectivity_scenarios(
      habitat_baseline = layers$habitat,
      barrier_baseline = layers$barrier,
      species = "Test Species",
      interpatch_distance = 40,
      verbose = FALSE
    )
    # a name used in both lists
    habitat_connectivity_scenarios(
      habitat_baseline = layers$habitat,
      barrier_baseline = layers$barrier,
      species = "Test Species",
      habitat_scenarios = list("Stage 2" = layers$habitat_scenario),
      barrier_scenarios = list("Stage 2" = layers$barrier_scenario),
      interpatch_distance = 40,
      verbose = FALSE
    )
    # an unnamed scenario
    habitat_connectivity_scenarios(
      habitat_baseline = layers$habitat,
      barrier_baseline = layers$barrier,
      species = "Test Species",
      habitat_scenarios = list(layers$habitat_scenario),
      interpatch_distance = 40,
      verbose = FALSE
    )
  })
})
