# Fragment habitat along barriers

Removes barrier areas from buffered habitat and splits the result into
individual polygon fragments.

## Usage

``` r
sf_fragment_habitat(habitat_buffered, barrier)
```

## Arguments

- habitat_buffered:

  SF object. Buffered habitat geometry.

- barrier:

  SF object. Barrier geometry (e.g., roads).

## Value

SF object with individual habitat fragments, each with a unique ID.

## Examples

``` r
lizard_habitat_sf <- terra::as.polygons(example_habitat(), dissolve = TRUE) |>
  sf::st_as_sf()
lizard_barrier_shp <- example_barrier_shp()
if (FALSE) { # \dontrun{
buffered <- sf_habitat_buffer(lizard_habitat_sf, interpatch_distance = 10)
sf_fragment_habitat(buffered, lizard_barrier_shp)
} # }
```
