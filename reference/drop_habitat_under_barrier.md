# Remove habitat under barriers

Performs a
[`terra::mask()`](https://rspatial.github.io/terra/reference/mask.html)
operation, to remove the habitat parts that are under the mask. Habitat
is any cell that is neither `NA` nor `0`.

## Usage

``` r
drop_habitat_under_barrier(habitat, barrier_mask)
```

## Arguments

- habitat:

  Terra SpatRaster. Habitat layer.

- barrier_mask:

  Terra SpatRaster. Barrier mask.

## Value

Terra SpatRaster with habitat remaining after barrier removal, coded 1
for habitat and `NA` everywhere else.

## Examples

``` r
lizard_habitat <- example_habitat()
lizard_barrier <- example_barrier()
barrier_mask <- create_barrier_mask(lizard_barrier)
remaining_habitat <- drop_habitat_under_barrier(
  habitat = lizard_habitat,
  barrier = lizard_barrier
  )
remaining_habitat
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
