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

# the barrier cuts the buffered habitat into fragments
fragmented <- fragment_habitat(buffered_habitat, barrier_mask)

fragmented
#> class       : SpatRaster
#> size        : 763, 766, 1  (nrow, ncol, nlyr)
#> resolution  : 2, 2  (x, y)
#> extent      : 326109.6, 327641.6, 5820362, 5821888  (xmin, xmax, ymin, ymax)
#> coord. ref. : GDA94 / MGA zone 55 (EPSG:28355)
#> source(s)   : memory
#> varname     : lizard_habitat_raster
#> name        : Pseudo Layer
#> min value   :            1
#> max value   :            1
```
