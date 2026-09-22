# Calculate habitat connectivity using terra

This performs the entire connectivity workflow, returning a dataframe
output. The steps are:

- [`create_barrier_mask()`](https://urbio-ecology.github.io/urbioconnect/reference/create_barrier_mask.md):
  Creating barrier mask.

- [`drop_habitat_under_barrier()`](https://urbio-ecology.github.io/urbioconnect/reference/drop_habitat_under_barrier.md):
  Removes Habitat underneath barrier.

- [`habitat_buffer()`](https://urbio-ecology.github.io/urbioconnect/reference/habitat_buffer.md):
  Buffers the habitat layer by the interpatch distance (m).

- [`fragment_habitat()`](https://urbio-ecology.github.io/urbioconnect/reference/fragment_habitat.md):
  Fragments habitat layer along barrier intersection.

- [`assign_patches_to_fragments()`](https://urbio-ecology.github.io/urbioconnect/reference/assign_patches_to_fragments.md):
  Assign patch ID to fragments.

- [`aggregate_connected_patches()`](https://urbio-ecology.github.io/urbioconnect/reference/aggregate_connected_patches.md):
  Summarise area in each patch.

## Usage

``` r
habitat_connectivity(
  habitat,
  barrier,
  species,
  interpatch_distance = NULL,
  buffer_radius = NULL,
  verbose = TRUE
)
```

## Arguments

- habitat:

  Terra SpatRaster. Habitat raster.

- barrier:

  Terra SpatRaster. Barrier raster.

- species:

  Species name. E.g., "Blue-tongued Lizard".

- interpatch_distance:

  Numeric. The distance (in meters) where habitat patches are considered
  connected. E.g., if set to 500, patches 498m apart are connected,
  those 501m apart are not connected. This is passed internally to a
  spatial operation known as "buffering", where this distance is used as
  a radius from the edge of the habitat zone. This means the specified
  `interpatch_distance` is halved exactly. So an interpatch distance of
  500 will be converted to 250. For the buffer to be representable on
  the raster, keep `resolution <= interpatch_distance / 2`; below that
  the buffer is a no-op and a warning is raised. See
  [`vignette("interpatch-distance-and-resolution")`](https://urbio-ecology.github.io/urbioconnect/articles/interpatch-distance-and-resolution.md).

- buffer_radius:

  Numeric. The radius in metres around the habitat. Since patches of
  habitat will be connected when their edge-to-edge gap is \<= 2 \*
  `buffer radius`, we recommend you specify `buffer_radius` to be half
  the "interpatch distance". This is the distance past which habitat
  patches are no longer considered connected. For example, if your
  interpatch distance is 500m, set `buffer_radius = 250`. The buffer can
  only be represented if it is at least one raster cell, i.e. keep
  `resolution <= interpatch_distance / 2`. Below that the buffer is a
  no-op:
  [`habitat_buffer()`](https://urbio-ecology.github.io/urbioconnect/reference/habitat_buffer.md)
  warns and returns the habitat unchanged. See
  [`vignette("interpatch-distance-and-resolution")`](https://urbio-ecology.github.io/urbioconnect/articles/interpatch-distance-and-resolution.md).

- verbose:

  Logical. Display progress messages (default: TRUE).

## Value

A `connectivity` object (one row): a tibble of landscape-level
connectivity metrics (patch count, effective mesh size, probability of
connectedness, mean and total patch area) for the species and interpatch
distance supplied. The per-patch areas the summary is built from are
stored in a list column, "patch_size" – retrieve them with
[`patch_sizes()`](https://urbio-ecology.github.io/urbioconnect/reference/patch_sizes.md).

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
#> ✔ Creating barrier mask [50ms]
#> 
#> ℹ Removing habitat underneath barrier
#> ✔ Removing habitat underneath barrier [24ms]
#> 
#> ℹ Adding 6m buffer (interpatch distance 12m)
#> ✔ Adding 6m buffer (interpatch distance 12m) [224ms]
#> 
#> ℹ Fragmenting habitat layer along barrier intersection
#> ✔ Fragmenting habitat layer along barrier intersection [25ms]
#> 
#> ℹ Assigning patches ID to fragments
#> ✔ Assigning patches ID to fragments [2.3s]
#> 
#> ℹ Summarising area in each patch
#> ✔ Summarising area in each patch [44ms]
#> 
connectivity
#> # A tibble: 1 × 9
#>   species     interpatch_distance n_patches effective_mesh_ha prob_connectedness
#>   <chr>                     <dbl>     <int>             <dbl>              <dbl>
#> 1 Blue-tongu…                  12       399              4.21          0.0000160
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
#> 2        3   364.
#> 3        6  2344.
#> 4       13  1220.
#> 5       48  1112.
#> # ℹ 394 more rows
```
