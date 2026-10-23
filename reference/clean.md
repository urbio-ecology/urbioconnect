# Clean any spatial data layer (shape file)

Many shape files contain errors, places where the edges of a polygon
cross over or polygons which overlap. This helps remove some of those
errors by smoothing the edges of polygons, removing corners, and
dissolving edges where polygons overlap. This reduces the complexity of
the shape file, making future steps faster.

## Usage

``` r
clean(spatial_data, ...)
```

## Arguments

- spatial_data:

  spatial data frame from sf.

- ...:

  extra options (currently not used)

## Value

An sf object with simplified and validated geometry.

## Examples

``` r
lizard_barrier_shp <- example_barrier_shp()
clean(lizard_barrier_shp)
#> Geometry set for 1 feature 
#> Geometry type: MULTIPOLYGON
#> Dimension:     XY
#> Bounding box:  xmin: 326089.7 ymin: 5820343 xmax: 327662.5 ymax: 5821909
#> Projected CRS: GDA94 / MGA zone 55
#> MULTIPOLYGON (((326138.4 5820343, 326130.6 5820...
```
