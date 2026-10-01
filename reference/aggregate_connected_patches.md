# Aggregate connected patch areas

Aggregate a raster with connected patch areas into a data frame where
each row is a unique patch, and its area and area squared.

## Usage

``` r
aggregate_connected_patches(raster)
```

## Arguments

- raster:

  terra SpatRaster. Raster with patch_id and area layers.

## Value

Data frame with patch areas and areas squared.

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
#> # A tibble: 638 × 3
#>    patch_id    area area_squared
#>       <dbl>   <dbl>        <dbl>
#>  1        1    60.0        3600.
#>  2        2  1736.      3014096.
#>  3        7    12.0         144.
#>  4        8  1200.      1440195.
#>  5       10 92202.   8501145019.
#>  6       11    40.0        1600.
#>  7       12   288.        82955.
#>  8       28  1212.      1469120.
#>  9       30    64.0        4096.
#> 10       31   940.       883705.
#> # ℹ 628 more rows
```
