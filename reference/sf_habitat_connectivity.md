# Calculate habitat connectivity

Performs complete habitat connectivity analysis using vector-based
spatial operations. Buffers habitat, fragments it along barriers, and
calculates areas of connected patches.

## Usage

``` r
sf_habitat_connectivity(habitat, barrier, species, interpatch_distance)
```

## Arguments

- habitat:

  SF object. Original habitat spatial data.

- barrier:

  SF object. Barrier spatial data (e.g., roads, waterways).

- species:

  character. Species name.

- interpatch_distance:

  Numeric. The distance (in meters) where habitat patches are considered
  connected. E.g., if set to 500, patches 498m apart are connected,
  those 501m apart are not connected. This is passed internally to a
  spatial operation known as "buffering", where this distance is used as
  a radius from the edge of the habitat zone. This means the specified
  `interpatch_distance` is halved exactly. So an interpatch distance of
  500 will be converted to a 250m buffer radius.

## Value

Data frame with connectivity metrics for each connected patch, including
`patch_id`, `area`, and `area_squared`.

## Examples

``` r
lizard_barrier_shp <- example_barrier_shp()
#> Reading layer `lizard_barrier' from data source 
#>   `/home/runner/work/_temp/Library/urbioconnect/ex/lizard_barrier.shp' 
#>   using driver `ESRI Shapefile'
#> Simple feature collection with 1 feature and 1 field
#> Geometry type: MULTIPOLYGON
#> Dimension:     XY
#> Bounding box:  xmin: 326089.6 ymin: 5820342 xmax: 327662.5 ymax: 5821909
#> Projected CRS: GDA94 / MGA zone 55
lizard_habitat_sf <- terra::as.polygons(
  example_habitat(),
  dissolve = TRUE
  ) |>
  sf::st_as_sf()
result <- sf_habitat_connectivity(
  habitat = lizard_habitat_sf,
  barrier = lizard_barrier_shp,
  species = "Blue-tongued lizard",
  interpatch_distance = 10
  )
#> Warning: attribute variables are assumed to be spatially constant throughout all geometries
#> Warning: repeating attributes for all sub-geometries for which they may not be constant
result
#> # patch_size_tbl:      data.frame
#> # Species:             Blue-tongued lizard
#> # Patches:             479
#> # Resolution:          NA
#> # Interpatch Distance: 10 m
#>   patch_id  area
#>      <dbl> <dbl>
#> 1        1 1536.
#> 2        2  287.
#> 3        3  292.
#> 4        4  851.
#> 5        5    8 
#> # ℹ 474 more rows
```
