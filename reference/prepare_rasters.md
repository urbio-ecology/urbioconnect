# Prepare habitat and barrier rasters

Put habitat and barrier layers on one grid. Either layer may be a vector
(`sf` or `SpatVector`), which is rasterised, or a `SpatRaster`, which is
resampled onto the grid.

## Usage

``` r
prepare_rasters(habitat, barrier, data_resolution = 10)
```

## Arguments

- habitat:

  SF object or `SpatRaster`. Habitat spatial data. In a raster, habitat
  is any cell that is neither `NA` nor `0`.

- barrier:

  SF object or `SpatRaster`. Barrier spatial data.

- data_resolution:

  Numeric. Cell size in metres. Default, 10.

## Value

List with `habitat_raster` and `barrier_raster` elements.

## Details

The grid covers the extent of `habitat`, and the analysis stops at its
edge, so a barrier that carries on past the study area should be drawn
past the edge of the habitat.

## Examples

``` r
lizard_habitat_sf <- terra::as.polygons(example_habitat(), dissolve = TRUE) |>
  sf::st_as_sf()
lizard_barrier_shp <- example_barrier_shp()
prepare_rasters(lizard_habitat_sf, lizard_barrier_shp)
#> $habitat_raster
#> class       : SpatRaster
#> size        : 152, 153, 1  (nrow, ncol, nlyr)
#> resolution  : 10.01307, 10.02632  (x, y)
#> extent      : 326109.6, 327641.6, 5820364, 5821888  (xmin, xmax, ymin, ymax)
#> coord. ref. : GDA94 / MGA zone 55 (EPSG:28355)
#> source(s)   : memory
#> name        : layer
#> min value   :     1
#> max value   :     1
#> 
#> $barrier_raster
#> class       : SpatRaster
#> size        : 152, 153, 1  (nrow, ncol, nlyr)
#> resolution  : 10.01307, 10.02632  (x, y)
#> extent      : 326109.6, 327641.6, 5820364, 5821888  (xmin, xmax, ymin, ymax)
#> coord. ref. : GDA94 / MGA zone 55 (EPSG:28355)
#> source(s)   : memory
#> name        : layer
#> min value   :     0
#> max value   :     1
#> 

# a raster layer is resampled onto the grid rather than rasterised
prepare_rasters(example_habitat(), lizard_barrier_shp)
#> $habitat_raster
#> class       : SpatRaster
#> size        : 153, 153, 1  (nrow, ncol, nlyr)
#> resolution  : 10.01307, 9.973856  (x, y)
#> extent      : 326109.6, 327641.6, 5820362, 5821888  (xmin, xmax, ymin, ymax)
#> coord. ref. : GDA94 / MGA zone 55 (EPSG:28355)
#> source(s)   : memory
#> name        : Pseudo Layer
#> min value   :            1
#> max value   :            1
#> 
#> $barrier_raster
#> class       : SpatRaster
#> size        : 153, 153, 1  (nrow, ncol, nlyr)
#> resolution  : 10.01307, 9.973856  (x, y)
#> extent      : 326109.6, 327641.6, 5820362, 5821888  (xmin, xmax, ymin, ymax)
#> coord. ref. : GDA94 / MGA zone 55 (EPSG:28355)
#> source(s)   : memory
#> name        : layer
#> min value   :     0
#> max value   :     1
#> 
```
