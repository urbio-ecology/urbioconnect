## Packages
library(colorspace)
library(conflicted)
library(crew)
library(DT)
library(fasterize)
library(fs)
library(geotargets)
library(glue)
library(here)
library(igraph)
library(knitr)
library(marquee)
library(magick)
library(prettyunits)
library(quarto)
library(raster)
library(scico)
library(sf)
library(stars)
library(shiny)
library(stringr)
library(targets)
library(tarchetypes)
library(terra)
library(tidyterra)
library(tidyverse)
library(vctrs)
library(withr)
conflicts_prefer(dplyr::filter)
conflicts_prefer(dplyr::select)
lapply(list.files("R/", pattern = "*.R|*.r", full.names = TRUE), source)

# shapefile inputs from user
barrier_file <- here("data-raw/superb-fairy-wren/allSFWRoads.shp")
# shapefile inputs from user
habitat_file <- here("data-raw/superb-fairy-wren/superbHab.shp")
# our custom function to read in data
barrier <- read_geometry(barrier_file) |> st_as_sf()
habitat <- read_geometry(habitat_file) |>
  # custom function that we provide
  clean() |>
  st_as_sf()

# input for the user - text
species <- "Superb Fairy Wren"
# input for the user - one number,
target_resolution <- 500
# input for the user - one number
data_resolution <- 10

# determined from user input
aggregation_factor <- target_resolution / data_resolution

# input from the user - can be one number, up to 4 numbers
# e.g., distance <- c(100, 250, 400)
distance <- 100

# These are operations that happen in the background ----
# convert the vector format into a raster
# TODO so reactive({}) ends up becoming the equivalent of tar_target()
habitat_rasterised <- terra::rasterize(
  habitat,
  terra::rast(
    x = habitat,
    res = data_resolution,
    crs = crs(habitat)
  ),
  background = NA
)

barrier_rasterised <- terra::rasterize(
  barrier,
  terra::rast(
    x = habitat,
    res = data_resolution,
    crs = crs(habitat)
  ),
  background = 0
)

# aggregate rasters to make them the size of the overlay raster
## could generate an empty raster with this resolution instead of using
## barrier data directly - we could instead do raster of this grid spec
coarse_raster <- terra::aggregate(
  barrier_rasterised * 0,
  fact = aggregation_factor
)

## making the grid finer
coarse_template <- terra::disagg(coarse_raster, aggregation_factor)
## terra resample or project could help us get to these different resolutions
## terra resample by util

## again, we could get around this by specifying a grid spec
## make sure the extent snaps to the right shape
## so give it the extent and resolution
## with the extent and the resolution, make sure that they snap together
## terra::rast(nrow = ..., ncol = ..., extent)
habitat_raster <- terra::extend(habitat_rasterised, coarse_template)
barrier_raster <- terra::extend(barrier_rasterised, coarse_template)

# outputs ----
# show this output as a DT data table - one row per distance
results_connect_habitat <- habitat_connectivity(
  habitat = habitat_raster,
  barrier = barrier_raster,
  species = species,
  interpatch_distance = distance
)
