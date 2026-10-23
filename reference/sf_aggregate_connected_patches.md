# Aggregate connected patch areas

Groups habitat patches by their connected fragment ID and sums the area
within each one.

## Usage

``` r
sf_aggregate_connected_patches(patch_areas)
```

## Arguments

- patch_areas:

  SF object. Habitat patches with area column.

## Value

Data frame with `patch_id` and `area` columns.

## Examples

``` r
lizard_habitat_sf <- terra::as.polygons(example_habitat(), dissolve = TRUE) |>
  sf::st_as_sf()
lizard_barrier_shp <- example_barrier_shp()
if (FALSE) { # \dontrun{
buffered <- sf_habitat_buffer(lizard_habitat_sf, buffer_radius = 10)
fragments <- sf_fragment_habitat(buffered, lizard_barrier_shp)
remaining <- sf_drop_habitat_under_barrier(lizard_habitat_sf, lizard_barrier_shp)
patches <- sf_assign_patches_to_fragments(remaining, fragments) |>
  sf_add_patch_area()
sf_aggregate_connected_patches(patches)
} # }
```
