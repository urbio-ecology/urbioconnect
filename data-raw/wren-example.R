library(terra)
library(tidyterra)
library(tidyverse)
library(sf)
library(urbioconnect)

wren_barrier_file <- file.path("data-raw/superb-fairy-wren/allSFWRoads.shp")

wren_barrier <- wren_barrier_file |>
  sf::st_read() |>
  sf::st_geometry() |>
  sf::st_as_sf()

wren_barrier_scenario_file <- file.path(
  "data-raw/knoxscenariodata/KnoxTestScenario.shp"
)

wren_barrier_scenario <- wren_barrier_scenario_file |>
  sf::st_read() |>
  sf::st_geometry() |>
  sf::st_as_sf()

# data_dir <- system.file(
#     "data-raw/superb-fairy-wren/",
#     package = "urbioconnect"
# )

# wren_habitat_file_path <- file.path(data_dir, "superbHab.shp")
wren_habitat_file_path <- file.path("data-raw/superb-fairy-wren/superbHab.shp")

wren_habitat <- read_geometry(wren_habitat_file_path) |>
  clean() |>
  st_as_sf()
# habitat_file <- file.path("ex/lizard_habitat.tif")
# barrier_file <- file.path("ex/lizard_barrier.shp")

###
data_resolution <- 10

# input from the user - can be one number, up to 4 numbers
# e.g., distance <- c(100, 250, 400)
distance <- 100

# These are operations that happen in the background ----
wren_baseline_rasters <- prepare_rasters(
  habitat = wren_habitat,
  barrier = wren_barrier,
  data_resolution = data_resolution
)

wren_habitat_baseline <- wren_baseline_rasters$habitat_raster
wren_barrier_baseline <- wren_baseline_rasters$barrier_raster

wren_scenario_rasters <- prepare_rasters(
  habitat = wren_habitat,
  barrier = wren_barrier_scenario,
  data_resolution = data_resolution
)

wren_barrier_scenario <- wren_scenario_rasters$barrier_raster

## OPtional downsizing...ends up making it far too fine a grid
# coarser resolution for computational efficiency (metres)
# target_resolution <- 2
#
# # aligned grid template at target resolution
# # ensures both rasters have identical cell boundaries
# target_grid <- terra::rast(
#   extent = terra::ext(wren_habitat_baseline),
#   resolution = target_resolution,
#   crs = terra::crs(wren_habitat_baseline)
# )
#
# # align both rasters to the target grid - using method = "near" preserves binary values (0/1)
# wren_habitat_baseline <- terra::resample(
#   wren_habitat_baseline,
#   target_grid,
#   method = "near"
# )
#
# wren_barrier_baseline <- terra::resample(
#   wren_barrier_baseline,
#   target_grid,
#   method = "near"
# )
#
# wren_barrier_scenario <- terra::resample(
#   wren_barrier_scenario,
#   target_grid,
#   method = "near"
# )

plot(wren_habitat_baseline, main = "Wren Habitat (2m resolution)")
plot(wren_barrier_baseline, main = "Wren Barriers (2m resolution)")

# Check final resolution and dimensions
all.equal(terra::res(wren_habitat_baseline), terra::res(wren_barrier_baseline))
all.equal(dim(wren_habitat_baseline), dim(wren_barrier_baseline))
all.equal(
  terra::ncell(wren_habitat_baseline),
  terra::ncell(wren_barrier_baseline)
)

terra::writeRaster(
  x = wren_habitat_baseline,
  filename = "inst/ex/wren_habitat_baseline_rast.tif",
  filetype = "COG",
  overwrite = TRUE
)

terra::writeRaster(
  x = wren_barrier_baseline,
  filename = "inst/ex/wren_barrier_baseline_rast.tif",
  filetype = "COG",
  overwrite = TRUE
)

terra::writeRaster(
  x = wren_barrier_scenario,
  filename = "inst/ex/wren_barrier_scenario_rast.tif",
  filetype = "COG",
  overwrite = TRUE
)
