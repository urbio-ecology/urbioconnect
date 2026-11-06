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
interpatch_distance <- 20

# the steps before, in the order habitat_connectivity() runs them
barrier_mask <- create_barrier_mask(lizard_barrier)
remaining_habitat <- drop_habitat_under_barrier(
  habitat = lizard_habitat,
  barrier_mask = barrier_mask
)
buffered_habitat <- habitat_buffer(
  remaining_habitat,
  buffer_radius = interpatch_distance / 2
)
fragmented <- fragment_habitat(buffered_habitat, barrier_mask)
patch_areas <- assign_patches_to_fragments(
  remaining_habitat = remaining_habitat,
  fragment = fragmented
) |>
  add_patch_area()

# a row per patch, with its area in square metres
aggregate_connected_patches(patch_areas)
#> # A tibble: 163 × 2
#>    patch_id    area
#>       <dbl>   <dbl>
#>  1        1 97878. 
#>  2        2  2416. 
#>  3        3  1304. 
#>  4        4  1592. 
#>  5        5     4  
#>  6        6  3332. 
#>  7        7   132. 
#>  8        8   108. 
#>  9        9    36.0
#> 10       10  1112. 
#> # ℹ 153 more rows
```
