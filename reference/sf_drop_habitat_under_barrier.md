# Remove habitat underneath barriers

Removes all habitat areas that intersect with barriers and splits
multipolygons into individual patches.

## Usage

``` r
sf_drop_habitat_under_barrier(habitat, barrier)
```

## Arguments

- habitat:

  SF object. Original habitat geometry.

- barrier:

  SF object. Barrier geometry.

## Value

SF object with habitat patches that don't intersect barriers.

## Examples

``` r
lizard_habitat_sf <- terra::as.polygons(example_habitat(), dissolve = TRUE) |>
  sf::st_as_sf()
lizard_barrier_shp <- example_barrier_shp()
sf_drop_habitat_under_barrier(lizard_habitat_sf, lizard_barrier_shp)
#> Warning: attribute variables are assumed to be spatially constant throughout all geometries
#> Warning: repeating attributes for all sub-geometries for which they may not be constant
#> Simple feature collection with 9537 features and 1 field
#> Geometry type: POLYGON
#> Dimension:     XY
#> Bounding box:  xmin: 326109.6 ymin: 5820364 xmax: 327641.6 ymax: 5821888
#> Projected CRS: GDA94 / MGA zone 55
#> First 10 features:
#>     Pseudo.Layer                       geometry
#> 1              1 POLYGON ((327507.6 5821886,...
#> 1.1            1 POLYGON ((327511.6 5821884,...
#> 1.2            1 POLYGON ((327573.6 5821886,...
#> 1.3            1 POLYGON ((327331.6 5821884,...
#> 1.4            1 POLYGON ((327335.6 5821884,...
#> 1.5            1 POLYGON ((327387.6 5821884,...
#> 1.6            1 POLYGON ((327413.6 5821884,...
#> 1.7            1 POLYGON ((327513.6 5821884,...
#> 1.8            1 POLYGON ((327529.6 5821882,...
#> 1.9            1 POLYGON ((327391.6 5821884,...
```
