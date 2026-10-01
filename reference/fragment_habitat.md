# Fragment habitat

Takes a barrier mask (created with
[`create_barrier_mask()`](https://urbio-ecology.github.io/urbioconnect/reference/create_barrier_mask.md))
and fragments up the habitat where they intersect.

## Usage

``` r
fragment_habitat(buffered_habitat, barrier_mask)
```

## Arguments

- buffered_habitat:

  Terra SpatRaster. Buffered habitat.

- barrier_mask:

  Terra SpatRaster. Barrier mask.

## Value

Terra SpatRaster with fragmented habitat.

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
```
