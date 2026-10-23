# Aggregate connected patch areas

Aggregate a raster with connected patch areas into a data frame where
each row is a unique patch, and its area.

## Usage

``` r
aggregate_connected_patches(raster)
```

## Arguments

- raster:

  terra SpatRaster. Raster with patch_id and area layers.

## Value

Data frame with `patch_id` and `area` columns.

## Examples

``` r
lizard_habitat <- example_habitat()
lizard_barrier <- example_barrier()
buffered_habitat <- habitat_buffer(lizard_habitat, 5)
#> Warning: `interpatch_distance` doesn't align with the raster resolution.
#> ✖ 10 m isn't a multiple of 4 m.
#> ℹ It snaps to 8 m.
#> ℹ Connectivity may shift for patches near the cut-off.
#> ℹ See `vignette(urbioconnect::interpatch-distance-and-resolution)`.
barrier_mask <- create_barrier_mask(lizard_barrier)
fragmented <- fragment_habitat(buffered_habitat, barrier_mask)
remaining_habitat <- drop_habitat_under_barrier(
  habitat = lizard_habitat,
  barrier = lizard_barrier
  )
fragment_patches <- assign_patches_to_fragments(
  remaining_habitat = remaining_habitat,
  fragment = fragmented
  )
library(terra)
patch_areas <- add_patch_area(fragment_patches)
aggregate_connected_patches(patch_areas)
#> # A tibble: 638 × 2
#>    patch_id    area
#>       <dbl>   <dbl>
#>  1        1    60.0
#>  2        2  1736. 
#>  3        7    12.0
#>  4        8  1200. 
#>  5       10 92202. 
#>  6       11    40.0
#>  7       12   288. 
#>  8       28  1212. 
#>  9       30    64.0
#> 10       31   940. 
#> # ℹ 628 more rows
```
