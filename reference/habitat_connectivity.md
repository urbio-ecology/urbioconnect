# Calculate habitat connectivity using terra

This performs the entire connectivity workflow, returning a
`connectivity` summary. The steps are:

- [`create_barrier_mask()`](https://urbio-ecology.github.io/urbioconnect/reference/create_barrier_mask.md):
  Creates the barrier mask.

- [`drop_habitat_under_barrier()`](https://urbio-ecology.github.io/urbioconnect/reference/drop_habitat_under_barrier.md):
  Removes habitat underneath the barrier.

- [`habitat_buffer()`](https://urbio-ecology.github.io/urbioconnect/reference/habitat_buffer.md):
  Buffers the remaining habitat by half the interpatch distance (m).

- [`fragment_habitat()`](https://urbio-ecology.github.io/urbioconnect/reference/fragment_habitat.md):
  Fragments the buffered habitat along the barrier.

- [`assign_patches_to_fragments()`](https://urbio-ecology.github.io/urbioconnect/reference/assign_patches_to_fragments.md):
  Assigns a patch ID to each fragment.

- [`add_patch_area()`](https://urbio-ecology.github.io/urbioconnect/reference/add_patch_area.md):
  Adds the area of each cell.

- [`aggregate_connected_patches()`](https://urbio-ecology.github.io/urbioconnect/reference/aggregate_connected_patches.md):
  Sums the area in each patch.

- [`summarise_connectivity()`](https://urbio-ecology.github.io/urbioconnect/reference/summarise-connectivity.md):
  Calculates the connectivity metrics.

## Usage

``` r
habitat_connectivity(
  habitat,
  barrier,
  species,
  interpatch_distance,
  directions = 4,
  verbose = TRUE
)
```

## Arguments

- habitat:

  Terra SpatRaster. Habitat raster. Habitat is any cell that is neither
  `NA` nor `0`.

- barrier:

  Terra SpatRaster. Barrier raster.

- species:

  Species name. E.g., "Blue-tongued Lizard".

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

A `connectivity` object (one row): a tibble of landscape-level
connectivity metrics (patch count, effective mesh size, probability of
connectedness, mean and total patch area) for the species and interpatch
distance supplied. The per-patch areas the summary is built from are
stored in a list column, "patch_size" – retrieve them with
[`patch_sizes()`](https://urbio-ecology.github.io/urbioconnect/reference/patch_sizes.md).

## Details

By default, patches join through shared edges only (rook's case,
`directions = 4`): two buffered cells that touch only at a corner stay
in separate patches. This is the more conservative choice.
`directions = 8` (queen's case) joins them. The buffer is drawn in whole
cells, so whether two buffers share an edge or only a corner can depend
on the cell size, and the same landscape can count more patches on a
coarser grid. See
[`vignette("interpatch-distance-and-resolution")`](https://urbio-ecology.github.io/urbioconnect/articles/interpatch-distance-and-resolution.md).

## See also

[`vignette("interpatch-distance-and-resolution")`](https://urbio-ecology.github.io/urbioconnect/articles/interpatch-distance-and-resolution.md)
for the relationship between interpatch distance, buffer radius, and
resolution.

## Examples

``` r
lizard_habitat <- example_habitat()
lizard_barrier <- example_barrier()
connectivity <- habitat_connectivity(
    habitat = lizard_habitat,
    barrier = lizard_barrier,
    species = "Blue-tongued Lizard",
    interpatch_distance = 12
  )
#> ℹ Creating barrier mask
#> ✔ Creating barrier mask [30ms]
#> 
#> ℹ Removing habitat underneath barrier
#> ✔ Removing habitat underneath barrier [52ms]
#> 
#> ℹ Buffering habitat for an interpatch distance of 12m
#> ✔ Buffering habitat for an interpatch distance of 12m [162ms]
#> 
#> ℹ Fragmenting habitat layer along barrier intersection
#> ✔ Fragmenting habitat layer along barrier intersection [20ms]
#> 
#> ℹ Assigning patches ID to fragments
#> ✔ Assigning patches ID to fragments [2.5s]
#> 
#> ℹ Summarising area in each patch
#> ✔ Summarising area in each patch [38ms]
#> 
connectivity
#> # A tibble: 1 × 9
#>   species     interpatch_distance n_patches effective_mesh_ha prob_connectedness
#>   <chr>                     <dbl>     <int>             <dbl>              <dbl>
#> 1 Blue-tongu…                  12       399              4.21              0.160
#> # ℹ 4 more variables: patch_area_mean <dbl>, patch_area_total_ha <dbl>,
#> #   data_resolution <chr>, patch_size <list>

# get the patch size:
patch_sizes(connectivity)[[1]]
#> # patch_size_tbl:      data.frame
#> # Species:             Blue-tongued Lizard
#> # Patches:             399
#> # Resolution:          2x2
#> # Interpatch Distance: 12 m
#>   patch_id   area
#>      <dbl>  <dbl>
#> 1        1 95326.
#> 2        2   364.
#> 3        3  2344.
#> 4        4  1220.
#> 5        5  1112.
#> # ℹ 394 more rows

# patches join only through a shared edge, like two rooks side by side.
# An interpatch distance of 0 buffers nothing, so only touching cells join
side_by_side <- rbind(c(1, 1), c(NA, NA))
corner_to_corner <- rbind(c(1, NA), c(NA, 1))
n_patches_of <- function(cells, directions = 4) {
  habitat <- terra::rast(cells, crs = "local")
  connectivity <- habitat_connectivity(
    habitat = habitat,
    barrier = terra::rast(habitat, vals = NA),
    species = "demo",
    interpatch_distance = 0,
    directions = directions,
    verbose = FALSE
  )
  connectivity$n_patches
}
n_patches_of(side_by_side)
#> [1] 1
n_patches_of(corner_to_corner)
#> [1] 2

# the queen's case joins cells that touch only at a corner
n_patches_of(corner_to_corner, directions = 8)
#> [1] 1
```
