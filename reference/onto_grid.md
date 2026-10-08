# Put a layer on a grid, whichever form it arrives in

A vector layer is rasterised; a `SpatRaster` is already cells, so it is
resampled onto the grid instead. This is the one place that decides what
an empty cell means, which is why `background` is required: `NA` for
habitat, because a cell with no habitat in it has no value, and `0` for
a barrier, because a cell with no barrier in it is not blocked.

## Usage

``` r
onto_grid(layer, grid, background)
```

## Arguments

- layer:

  An `sf`, `SpatVector` or `SpatRaster` layer.

- grid:

  A `SpatRaster` whose geometry the result takes, from
  [`empty_grid()`](https://urbio-ecology.github.io/urbioconnect/reference/empty_grid.md)
  or an already-prepared layer.

- background:

  Value for cells the layer does not cover. Ignored when `layer` is a
  `SpatRaster`, which brings its own.

## Value

A `SpatRaster` on `grid`'s geometry.

## Details

Use it to put a scenario layer on the grid of the layer it replaces. A
scenario rasterised onto a grid of its own extent is a different
landscape, and
[`habitat_connectivity_comparison()`](https://urbio-ecology.github.io/urbioconnect/reference/habitat_connectivity_comparison.md)
will refuse to compare it.

## See also

[`prepare_rasters()`](https://urbio-ecology.github.io/urbioconnect/reference/prepare_rasters.md),
which uses this for both of its layers.

## Examples

``` r
grid <- empty_grid(example_barrier_shp(), resolution = 10)
#> Reading layer `lizard_barrier' from data source 
#>   `/home/runner/work/_temp/Library/urbioconnect/ex/lizard_barrier.shp' 
#>   using driver `ESRI Shapefile'
#> Simple feature collection with 1 feature and 1 field
#> Geometry type: MULTIPOLYGON
#> Dimension:     XY
#> Bounding box:  xmin: 326089.6 ymin: 5820342 xmax: 327662.5 ymax: 5821909
#> Projected CRS: GDA94 / MGA zone 55

# a vector layer is rasterised
onto_grid(example_barrier_shp(), grid, background = 0)
#> Reading layer `lizard_barrier' from data source 
#>   `/home/runner/work/_temp/Library/urbioconnect/ex/lizard_barrier.shp' 
#>   using driver `ESRI Shapefile'
#> Simple feature collection with 1 feature and 1 field
#> Geometry type: MULTIPOLYGON
#> Dimension:     XY
#> Bounding box:  xmin: 326089.6 ymin: 5820342 xmax: 327662.5 ymax: 5821909
#> Projected CRS: GDA94 / MGA zone 55
#> class       : SpatRaster
#> size        : 157, 157, 1  (nrow, ncol, nlyr)
#> resolution  : 10.0184, 9.979108  (x, y)
#> extent      : 326089.6, 327662.5, 5820342, 5821909  (xmin, xmax, ymin, ymax)
#> coord. ref. : GDA94 / MGA zone 55 (EPSG:28355)
#> source(s)   : memory
#> name        : layer
#> min value   :     0
#> max value   :     1

# a raster one is resampled
onto_grid(example_habitat(), grid, background = NA)
#> class       : SpatRaster
#> size        : 157, 157, 1  (nrow, ncol, nlyr)
#> resolution  : 10.0184, 9.979108  (x, y)
#> extent      : 326089.6, 327662.5, 5820342, 5821909  (xmin, xmax, ymin, ymax)
#> coord. ref. : GDA94 / MGA zone 55 (EPSG:28355)
#> source(s)   : memory
#> name        : Pseudo Layer
#> min value   :            1
#> max value   :            1
```
