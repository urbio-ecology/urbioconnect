# Fair Wren Habitat, Barrier, and scenario Data from City of Knox.

We provide Habitat, Barrier, and scenario data on the species, "Superb
Fairy Wren". The data was collected from City of Knox, a local
government area in Melbourne, on the eastern suburbs, north of Dandenon
and south of Ringwood. For analysis purposes, we have also implemented a
scenario piece of data.

## Usage

``` r
example_wren_habitat()

example_wren_habitat_scenario()

example_wren_barrier()

example_wren_barrier_scenario()
```

## Value

A terra raster object or sf object depending on the function called

## Details

We provide helper functions to load the raster and shapefile data. These
are required due to how the raster and vector data are stored. These
functions provide easy access to example raster and shapefile data
included with the package:

- `example_wren_habitat()` Returns a raster of wren habitat data.

- `example_wren_habitat_scenario()` Returns a raster of wren habitat
  scenario data.

- `example_wren_barrier()` Returns a raster of wren barrier data.

- `example_wren_barrier_scenario()` Returns a raster of wren barrier
  scenario data.

## Examples

``` r
library(terra)

# Load habitat raster
wren_habitat <- example_wren_habitat()
# Load barrier raster
wren_barrier <- example_wren_barrier()
# load barrier scenario
wren_barrier_scenario <- example_wren_barrier_scenario()
plot(wren_habitat, col = "darkgreen", legend = FALSE, main = "wren Habitat")


plot(
wren_barrier,
col = c("grey", "white"),
legend = FALSE, main = "wren Barriers")


plot(
  wren_barrier,
  col = c("grey", "white"),
  legend = FALSE,
  main = "wren Habitat and Barrier"
  )
plot(wren_habitat, col = "darkgreen", legend = FALSE, add = TRUE)


plot(
  wren_barrier_scenario,
  col = c("grey", "white"),
  legend = FALSE,
  main = "wren Habitat and Barrier scenario"
  )
plot(wren_habitat, col = "darkgreen", legend = FALSE, add = TRUE)
```
