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

A `patch_size_tbl` with one row per connected patch, holding `patch_id`
and `area`.

## Examples

``` r
lizard_barrier_shp <- example_barrier_shp()
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
