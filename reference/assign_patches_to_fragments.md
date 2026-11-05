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
plot(fragment_patches)
```
