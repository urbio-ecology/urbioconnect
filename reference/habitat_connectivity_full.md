# Calculate habitat connectivity with visualisation data

Like
[`habitat_connectivity()`](https://urbio-ecology.github.io/urbioconnect/reference/habitat_connectivity.md),
but also returns the intermediate rasters (buffered habitat, patch ID
raster, barrier mask, remaining habitat) useful for mapping and
reporting.

## Usage

``` r
habitat_connectivity_full(
  habitat,
  barrier,
  interpatch_distance,
  directions = 4,
  verbose = TRUE
)
```

## Arguments

- habitat:

  Terra SpatRaster. Habitat raster, projected in metres. Habitat is any
  cell that is neither `NA` nor `0`.

- barrier:

  Terra SpatRaster. Barrier raster.

- interpatch_distance:

  Numeric. The distance (in metres) where habitat patches are considered
  connected. E.g., if set to 500, patches 498m apart are connected,
  those 501m apart are not connected. This is passed internally to a
  spatial operation known as "buffering", where this distance is used as
  a radius from the edge of the habitat zone. This means the specified
  `interpatch_distance` is halved exactly. So an interpatch distance of
  500 will be converted to 250. For the buffer to be representable on
  the raster, keep `resolution <= interpatch_distance / 2`; below that
  the buffer is a no-op and a warning is raised. See
  [`vignette("interpatch-distance-and-resolution")`](https://urbio-ecology.github.io/urbioconnect/articles/interpatch-distance-and-resolution.md).

- directions:

  Which neighbouring raster cells join into one patch, passed to
  [`terra::patches()`](https://rspatial.github.io/terra/reference/patches.html).
  `4`, the default, is the rook's case: cells join only through a shared
  edge. `8` is the queen's case: cells that touch only at a corner join
  as well. It applies to rasters only, not to
  [`sf_habitat_connectivity()`](https://urbio-ecology.github.io/urbioconnect/reference/sf_habitat_connectivity.md).

- verbose:

  Logical. Display progress messages (default: TRUE).

## Value

Named list with elements: `buffered_habitat`, `patch_id_raster`,
`areas_connected`, `barrier_mask`, `remaining_habitat`.

## Examples

``` r
lizard_habitat <- example_habitat()
lizard_barrier <- example_barrier()
result <- habitat_connectivity_full(
  lizard_habitat,
  lizard_barrier,
  interpatch_distance = 20,
  verbose = FALSE
)
names(result)
#> [1] "buffered_habitat"  "patch_id_raster"   "areas_connected"  
#> [4] "barrier_mask"      "remaining_habitat"
```
