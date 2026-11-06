# Assign patches to fragments

Assign patches to fragments

## Usage

``` r
assign_patches_to_fragments(remaining_habitat, fragment, directions = 4)
```

## Arguments

- remaining_habitat:

  Terra SpatRaster. Remaining habitat.

- fragment:

  Terra SpatRaster. Fragment geometry.

- directions:

  Which neighbouring raster cells join into one patch, passed to
  [`terra::patches()`](https://rspatial.github.io/terra/reference/patches.html).
  `4`, the default, is the rook's case: cells join only through a shared
  edge. `8` is the queen's case: cells that touch only at a corner join
  as well. It applies to rasters only, not to
  [`sf_habitat_connectivity()`](https://urbio-ecology.github.io/urbioconnect/reference/sf_habitat_connectivity.md).

## Value

Terra SpatRaster with patch IDs, numbered from 1 to the number of
patches with no gaps.

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

# each habitat cell gets the id of the fragment it is in
fragment_patches <- assign_patches_to_fragments(
  remaining_habitat = remaining_habitat,
  fragment = fragmented
)

fragment_patches
#> class       : SpatRaster
#> size        : 763, 766, 1  (nrow, ncol, nlyr)
#> resolution  : 2, 2  (x, y)
#> extent      : 326109.6, 327641.6, 5820362, 5821888  (xmin, xmax, ymin, ymax)
#> coord. ref. : GDA94 / MGA zone 55 (EPSG:28355)
#> source(s)   : memory
#> varname     : lizard_habitat_raster
#> name        : Pseudo Layer
#> min value   :            1
#> max value   :          163

terra::plot(fragment_patches)
```
