# Buffer habitat by distance

Creates a buffer around habitat polygons and unions overlapping areas
into a single polygon, using
[`sf::st_buffer()`](https://r-spatial.github.io/sf/reference/geos_unary.html).
Unlike the raster
[`habitat_buffer()`](https://urbio-ecology.github.io/urbioconnect/reference/habitat_buffer.md),
this works in continuous coordinate space, so there is **no resolution
constraint**: any `buffer_radius` produces an exact buffer and the
sub-cell "no buffer" problem of the raster path does not apply. The
buffer arc is approximated by `nQuadSegs` straight segments per quarter
circle (here 5, i.e. a 20-sided polygon), which affects the *smoothness*
of the outline, not whether the buffer forms. See
[`vignette("interpatch-distance-and-resolution")`](https://urbio-ecology.github.io/urbioconnect/articles/interpatch-distance-and-resolution.md).

## Usage

``` r
sf_habitat_buffer(habitat, buffer_radius)
```

## Arguments

- habitat:

  SF object. Habitat spatial data.

- buffer_radius:

  Numeric. The radius in metres around the habitat. Specify it as half
  the interpatch distance (see
  [`habitat_buffer()`](https://urbio-ecology.github.io/urbioconnect/reference/habitat_buffer.md)).
  Because vector buffering is done in continuous space, there is no
  minimum representable radius - unlike the raster path, there is no
  resolution below which the buffer becomes a no-op.

## Value

SF object with buffered and unioned habitat geometry.

## Examples

``` r
lizard_habitat_sf <- terra::as.polygons(example_habitat(), dissolve = TRUE) |>
  sf::st_as_sf()
if (FALSE) { # \dontrun{
sf_habitat_buffer(lizard_habitat_sf, buffer_radius = 10)
} # }
```
