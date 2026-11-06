# Buffer habitat raster

Buffer around the habitat a given distance in metres. Every cell whose
centre lies within `buffer_radius` of a habitat cell's centre is kept,
measured with the cell's width and height. This operation is used to
identify connected patches of habitat. Two patches will connect when
their edge-to-edge gap is \<= 2 \* `buffer radius`. So, we recommend you
specify the `buffer_radius` value to be half the interpatch distance,
which is the distance past which habitat patches are no longer
considered connected. For example, if your interpatch distance is 500m,
set `buffer_radius = 250`.

## Usage

``` r
habitat_buffer(habitat, buffer_radius)
```

## Arguments

- habitat:

  Terra SpatRaster. Habitat raster, with one layer. Habitat is any cell
  that is neither `NA` nor `0`.

- buffer_radius:

  Numeric. The radius in metres around the habitat. Since patches of
  habitat will be connected when their edge-to-edge gap is \<= 2 \*
  `buffer radius`, we recommend you specify `buffer_radius` to be half
  the "interpatch distance". This is the distance past which habitat
  patches are no longer considered connected. For example, if your
  interpatch distance is 500m, set `buffer_radius = 250`. The buffer can
  only be represented if it is at least one raster cell, i.e. keep
  `resolution <= interpatch_distance / 2`. Below that the buffer is a
  no-op: `habitat_buffer()` warns and keeps only the habitat itself. See
  [`vignette("interpatch-distance-and-resolution")`](https://urbio-ecology.github.io/urbioconnect/articles/interpatch-distance-and-resolution.md).

## Value

Terra SpatRaster, 1 within `buffer_radius` of habitat and `NA`
elsewhere.

## See also

[`vignette("interpatch-distance-and-resolution")`](https://urbio-ecology.github.io/urbioconnect/articles/interpatch-distance-and-resolution.md)
for the relationship between interpatch distance, buffer radius, and
resolution.

## Examples

``` r
lizard_habitat <- example_habitat()
library(terra)
plot(lizard_habitat, col = "darkgreen", legend = FALSE)

# run with a small buffer radius
lizard_buff <- habitat_buffer(lizard_habitat, buffer_radius = 10)
plot(lizard_buff, col = "lightgreen", legend = FALSE)
plot(lizard_habitat, col = "darkgreen", legend = FALSE, add = TRUE)
```
