# Add patch area column

Add patch area column

## Usage

``` r
sf_add_patch_area(patches)
```

## Arguments

- patches:

  SF object. Habitat patches.

## Value

SF object with added `area` column in square metres.

## Examples

``` r
lizard_habitat_sf <- terra::as.polygons(example_habitat(), dissolve = TRUE) |>
  sf::st_as_sf()
if (FALSE) { # \dontrun{
lizard_barrier_shp <- example_barrier_shp()
buffered <- sf_habitat_buffer(lizard_habitat_sf, buffer_radius = 10)
fragments <- sf_fragment_habitat(buffered, lizard_barrier_shp)
remaining <- sf_drop_habitat_under_barrier(lizard_habitat_sf, lizard_barrier_shp)
patches <- sf_assign_patches_to_fragments(remaining, fragments)
sf_add_patch_area(patches)
} # }
```
