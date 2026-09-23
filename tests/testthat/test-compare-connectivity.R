wren_habitat <- example_wren_habitat()
wren_barrier <- example_wren_barrier()
wren_barrier_scenario <- example_wren_barrier_scenario()

wren_connectivity_baseline <- habitat_connectivity(
  habitat = wren_habitat,
  barrier = wren_barrier,
  species = "Superb Fairy Wren",
  interpatch_distance = 200
)

wren_connectivity_scenario <- habitat_connectivity(
  habitat = wren_habitat,
  barrier = wren_barrier_scenario,
  species = "Superb Fairy Wren",
  interpatch_distance = 200
)

test_that("compare_connectivity() identifies changes in baseline/scenario", {
  results_compare <- compare_connectivity(
    scenario = wren_connectivity_scenario,
    baseline = wren_connectivity_baseline
  )

  expect_s3_class(results_compare, "compare_connectivity")

  # rows are baseline / scenario / change
  expect_identical(
    results_compare$measure,
    c("baseline", "scenario", "change", "pct_change")
  )

  # baseline row has fewer patches / higher effective mesh than the scenario
  expect_gt(
    results_compare$effective_mesh_ha[1],
    results_compare$effective_mesh_ha[2]
  )
  expect_lt(
    results_compare$n_patches[1],
    results_compare$n_patches[2]
  )

  # the `change` row equals scenario - baseline for every metric (value-level
  # contract on the two continuous metrics, not just their sign)
  expect_equal(
    results_compare$effective_mesh_ha[3],
    results_compare$effective_mesh_ha[2] - results_compare$effective_mesh_ha[1]
  )
  expect_equal(
    results_compare$prob_connectedness[3],
    results_compare$prob_connectedness[2] -
      results_compare$prob_connectedness[1]
  )
  expect_equal(
    results_compare$patch_area_total_ha[3],
    results_compare$patch_area_total_ha[2] -
      results_compare$patch_area_total_ha[1]
  )

  expect_snapshot(results_compare)
})

test_that("compare_connectivity() against itself gives a zero change row", {
  base <- summarise_connectivity(lizard_areas_connected)
  results_self <- compare_connectivity(scenario = base, baseline = base)

  expect_s3_class(results_self, "compare_connectivity")
  expect_snapshot(results_self)
})

test_that("compare_connectivity() rejects multi-row input", {
  base <- summarise_connectivity(lizard_areas_connected)
  expect_snapshot(
    compare_connectivity(dplyr::bind_rows(base, base), base),
    error = TRUE
  )
})

test_that("compare_connectivity() rejects non-connectivity input", {
  base <- summarise_connectivity(lizard_areas_connected)
  expect_snapshot(
    compare_connectivity(
      scenario = lizard_areas_connected$area,
      baseline = base
    ),
    error = TRUE
  )
})

test_that("compare_connectivity() labels every row with scenario_name", {
  base <- summarise_connectivity(lizard_areas_connected)
  scen <- summarise_connectivity(lizard_areas_connected[-1, ])

  labelled <- compare_connectivity(
    scen,
    base,
    scenario_name = "Bentley Project"
  )

  expect_equal(labelled$scenario_name, rep("Bentley Project", 4))
  expect_snapshot(names(labelled))
})

test_that("compare_connectivity() gives NA when no scenario_name is supplied", {
  base <- summarise_connectivity(lizard_areas_connected)
  scen <- summarise_connectivity(lizard_areas_connected[-1, ])

  unlabelled <- compare_connectivity(scen, base)

  expect_equal(unlabelled$scenario_name, rep(NA_character_, 4))
})

test_that("compare_connectivity() rejects a scenario_name that isn't one string", {
  base <- summarise_connectivity(lizard_areas_connected)
  scen <- summarise_connectivity(lizard_areas_connected[-1, ])

  expect_snapshot(error = TRUE, {
    compare_connectivity(scen, base, scenario_name = c("one", "two"))
    compare_connectivity(scen, base, scenario_name = 1)
  })
})

test_that("labelled and unlabelled comparisons stack", {
  base <- summarise_connectivity(lizard_areas_connected)
  scen <- summarise_connectivity(lizard_areas_connected[-1, ])

  stacked <- dplyr::bind_rows(
    compare_connectivity(scen, base, scenario_name = "Bentley Project"),
    compare_connectivity(scen, base)
  )

  expect_s3_class(stacked, "compare_connectivity")
  expect_equal(nrow(stacked), 8)
  expect_equal(unique(stacked$scenario_name), c("Bentley Project", NA))
})

test_that("compare_connectivity() works on default-method connectivity", {
  base <- summarise_connectivity(
    connectivity = c(100, 200, 300),
    interpatch_distance = 10,
    data_resolution = 2,
    species = "Test Species"
  )
  scen <- summarise_connectivity(
    connectivity = c(100, 200),
    interpatch_distance = 10,
    data_resolution = 2,
    species = "Test Species"
  )

  expect_snapshot(compare_connectivity(scenario = scen, baseline = base))
})
