# Add patch area layer

Adds a layer holding the area of each cell, in square metres, and names
the layers `patch_id` and `area`.

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
fragment_patches <- assign_patches_to_fragments(
  remaining_habitat = remaining_habitat,
  fragment = fragmented
)

# a second layer holds each cell's area, in square metres
patch_areas <- add_patch_area(fragment_patches)

patch_areas
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
#> max values  :      163, 4.000273
```
