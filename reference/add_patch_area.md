# Add patch area layer

Adds an area layer to the raster of the area of each patch.

## Usage

``` r
add_patch_area(raster)
```

## Arguments

- raster:

  terra SpatRaster. In the workflow, this is the patch ID raster.

## Value

terra SpatRaster with two layers: patch_id and area.

## Examples

``` r
lizard_habitat <- example_habitat()
lizard_barrier <- example_barrier()
buffered_habitat <- habitat_buffer(lizard_habitat, 5)
#> Warning: Buffer radius doesn't align with the raster resolution.
#> ✖ 5 m isn't a multiple of 2 m.
#> ℹ It snaps to 4 m (interpatch distance 8 m).
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
#> terra 1.9.50
add_patch_area(fragment_patches)
#> class       : SpatRaster
#> size        : 763, 766, 2  (nrow, ncol, nlyr)
#> resolution  : 2, 2  (x, y)
#> extent      : 326109.6, 327641.6, 5820362, 5821888  (xmin, xmax, ymin, ymax)
#> coord. ref. : GDA94 / MGA zone 55 (EPSG:28355)
#> source(s)   : memory
#> varnames    : lizard_habitat_raster
#>               lizard_habitat_raster
#> names       : patch_id,     area
#> min values  :        1, 4.000221
#> max values  :     1481, 4.000273
```
