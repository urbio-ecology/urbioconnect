test_that("compare_scenarios() stacks four labelled rows per scenario", {
  baseline <- summarise_connectivity(lizard_areas_connected)
  results <- compare_scenarios(
    baseline = baseline,
    scenarios = list(
      "Bentley Project" = summarise_connectivity(lizard_areas_connected[-1, ]),
      "Barrier upgrade" = summarise_connectivity(
        lizard_areas_connected[-(1:5), ]
      )
    )
  )

  expect_s3_class(results, "compare_connectivity")
  expect_equal(nrow(results), 8)
  expect_equal(
    results$scenario_name,
    rep(c("Bentley Project", "Barrier upgrade"), each = 4)
  )
  expect_snapshot(results)
})

test_that("compare_scenarios() matches compare_connectivity() per scenario", {
  baseline <- summarise_connectivity(lizard_areas_connected)
  scenario <- summarise_connectivity(lizard_areas_connected[-1, ])

  many <- compare_scenarios(baseline, list("Bentley Project" = scenario))
  one <- compare_connectivity(
    scenario,
    baseline,
    scenario_name = "Bentley Project"
  )

  expect_equal(as.data.frame(many), as.data.frame(one))
})

test_that("compare_scenarios() rejects badly named scenarios", {
  baseline <- summarise_connectivity(lizard_areas_connected)
  scenario <- summarise_connectivity(lizard_areas_connected[-1, ])

  expect_snapshot(error = TRUE, {
    compare_scenarios(baseline, list(scenario))
    compare_scenarios(baseline, list("a" = scenario, scenario))
    # jarl-ignore-start duplicated_arguments: This is why we are testing this
    compare_scenarios(baseline, list("a" = scenario, "a" = scenario))
    # jarl-ignore-end duplicated_arguments
    compare_scenarios(baseline, list())
  })
})

test_that("compare_scenarios() rejects scenarios that aren't connectivity", {
  baseline <- summarise_connectivity(lizard_areas_connected)

  expect_snapshot(error = TRUE, {
    compare_scenarios(
      baseline,
      list("Bentley Project" = lizard_areas_connected$area)
    )
  })
})

test_that("compare_scenarios() rejects a scenario that mismatches the baseline", {
  baseline <- summarise_connectivity(lizard_areas_connected)
  other_species <- summarise_connectivity(
    connectivity = c(100, 200, 300),
    interpatch_distance = 10,
    data_resolution = 2,
    species = "Superb Fairy Wren"
  )

  expect_snapshot(error = TRUE, {
    compare_scenarios(baseline, list("Bentley Project" = other_species))
  })
})
