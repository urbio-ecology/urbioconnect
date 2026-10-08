# Prepare habitat and barrier rasters

Put habitat and barrier layers on one grid. Either layer may be a vector
(`sf` or `SpatVector`), which is rasterised, or a `SpatRaster`, which is
resampled onto the grid.

## Usage

``` r
prepare_rasters(
  habitat,
  barrier,
  data_resolution = 10,
  target_resolution = 500
)
```

## Arguments

- habitat:

  SF object or `SpatRaster`. Habitat spatial data.

- barrier:

  SF object or `SpatRaster`. Barrier spatial data.

- data_resolution:

  Numeric. Fine resolution in meters. Default, 10.

- target_resolution:

  Numeric. Coarse resolution in meters. Default, 500.

## Value

List with `habitat_raster` and `barrier_raster` elements.

## Examples

``` r
lizard_habitat_sf <- terra::as.polygons(example_habitat(), dissolve = TRUE) |>
  sf::st_as_sf()
lizard_barrier_shp <- example_barrier_shp()
#> Reading layer `lizard_barrier' from data source 
#>   `/home/runner/work/_temp/Library/urbioconnect/ex/lizard_barrier.shp' 
#>   using driver `ESRI Shapefile'
#> Simple feature collection with 1 feature and 1 field
#> Geometry type: MULTIPOLYGON
#> Dimension:     XY
#> Bounding box:  xmin: 326089.6 ymin: 5820342 xmax: 327662.5 ymax: 5821909
#> Projected CRS: GDA94 / MGA zone 55
prepare_rasters(lizard_habitat_sf, lizard_barrier_shp)
#> $habitat_raster
#> class       : SpatRaster
#> size        : 200, 200, 1  (nrow, ncol, nlyr)
#> resolution  : 10.01307, 10.02632  (x, y)
#> extent      : 326109.6, 328112.2, 5819883, 5821888  (xmin, xmax, ymin, ymax)
#> coord. ref. : GDA94 / MGA zone 55 (EPSG:28355)
#> source(s)   : memory
#> name        : layer
#> min value   :     1
#> max value   :     1
#> 
#> $barrier_raster
#> class       : SpatRaster
#> size        : 200, 200, 1  (nrow, ncol, nlyr)
#> resolution  : 10.01307, 10.02632  (x, y)
#> extent      : 326109.6, 328112.2, 5819883, 5821888  (xmin, xmax, ymin, ymax)
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
#> size        : 200, 200, 1  (nrow, ncol, nlyr)
#> resolution  : 10.01307, 9.973856  (x, y)
#> extent      : 326109.6, 328112.2, 5819894, 5821888  (xmin, xmax, ymin, ymax)
#> coord. ref. : GDA94 / MGA zone 55 (EPSG:28355)
#> source(s)   : memory
#> name        : Pseudo Layer
#> min value   :            1
#> max value   :            1
#> 
#> $barrier_raster
#> class       : SpatRaster
#> size        : 200, 200, 1  (nrow, ncol, nlyr)
#> resolution  : 10.01307, 9.973856  (x, y)
#> extent      : 326109.6, 328112.2, 5819894, 5821888  (xmin, xmax, ymin, ymax)
#> coord. ref. : GDA94 / MGA zone 55 (EPSG:28355)
#> source(s)   : memory
#> name        : layer
#> min value   :     0
#> max value   :     1
#> 
```
