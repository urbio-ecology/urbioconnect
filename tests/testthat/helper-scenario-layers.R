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
