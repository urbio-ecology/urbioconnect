# The lizard landscape and a scenario on it: a new road straight through the
# middle, which fragments the habitat further. Real spatial data, for the
# content and snapshot tests that want it, but 763x766 cells against the
# wren's 1500x1400: a full comparison here is ~3s rather than ~11s.
lizard_scenario_layers <- function() {
  barrier <- example_barrier()

  with_road <- terra::deepcopy(barrier)
  middle <- round(terra::ncol(barrier) / 2)
  with_road[, middle:(middle + 4)] <- 1

  list(
    habitat = example_habitat(),
    barrier = barrier,
    barrier_scenario = with_road
  )
}

# Small synthetic layers for the scenario wrappers. One pipeline run on these
# takes ~0.1s, against ~4.7s for the wren rasters, and these tests care about
# the wrapper's structure rather than the connectivity numbers.
scenario_test_layers <- function() {
  blank <- function() {
    r <- terra::rast(
      nrows = 40,
      ncols = 40,
      xmin = 0,
      xmax = 400,
      ymin = 0,
      ymax = 400,
      crs = "EPSG:32754"
    )
    terra::values(r) <- NA_real_
    r
  }

  habitat <- blank()
  habitat[5:12, 5:12] <- 1
  habitat[20:30, 20:30] <- 1
  habitat[5:10, 25:35] <- 1

  # a development removes the third patch
  habitat_scenario <- terra::deepcopy(habitat)
  habitat_scenario[5:10, 25:35] <- NA

  barrier <- blank()
  barrier[, 18] <- 1

  # the upgrade widens the barrier
  barrier_scenario <- terra::deepcopy(barrier)
  barrier_scenario[, 17:19] <- 1

  list(
    habitat = habitat,
    barrier = barrier,
    habitat_scenario = habitat_scenario,
    barrier_scenario = barrier_scenario
  )
}

# the app's own case: the lizard landscape at the app's default resolutions,
# against the new road, at three distances. ~3s.
lizard_road_comparison <- function() {
  rasters <- prepare_rasters(
    example_habitat(),
    example_barrier(),
    data_resolution = 10,
    target_resolution = 500
  )

  connectivity_report_data(
    habitat = rasters$habitat_raster,
    barrier = rasters$barrier_raster,
    species = "Blue Tongue Lizard",
    interpatch_distance = c(40, 80, 160),
    scenario = example_barrier_scenario(),
    scenario_kind = "barrier",
    scenario_name = "A new road through the habitat",
    verbose = FALSE
  )$comparison
}

# both synthetic scenarios at two distances: the shape a comparison plot has
# to lay out, at ~0.5s
scenario_test_comparison <- function() {
  layers <- scenario_test_layers()

  habitat_connectivity_scenarios(
    habitat_baseline = layers$habitat,
    barrier_baseline = layers$barrier,
    species = "Test Species",
    habitat_scenarios = list("Bentley Project" = layers$habitat_scenario),
    barrier_scenarios = list("Barrier upgrade" = layers$barrier_scenario),
    interpatch_distance = c(20, 40),
    verbose = FALSE
  )
}

# a scenario that adds habitat, so its P(connected), measured against the
# baseline's smaller area, comes out above 1
pc_above_one_comparison <- function() {
  summarise <- function(areas) {
    summarise_connectivity(
      areas,
      interpatch_distance = 40,
      data_resolution = 10,
      species = "Test Species"
    )
  }

  compare_connectivity(
    scenario = summarise(c(11000, 1000)),
    baseline = summarise(c(9000, 1000)),
    scenario_name = "New reserve"
  )
}
