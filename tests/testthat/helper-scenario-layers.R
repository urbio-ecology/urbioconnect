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
