# Plot barrier, habitat, and interpatch distance layers

Creates a visualisation of habitat, interpatch distance zone, and
barriers using terra rasters.

## Usage

``` r
gg_barrier_habitat_interpatch_dist(
  barrier,
  buffered,
  habitat,
  interpatch_distance,
  species,
  col_barrier = urbio_colours()$barrier,
  col_interpatch_dist = urbio_colours()$interpatch_distance,
  col_habitat = urbio_colours()$habitat,
  col_paper = "grey96"
)
```

## Arguments

- barrier:

  Terra SpatRaster. Barrier layer (e.g., roads).

- buffered:

  Terra SpatRaster. Buffered habitat layer.

- habitat:

  Terra SpatRaster. Original habitat layer. Habitat is any cell that is
  neither `NA` nor `0`.

- interpatch_distance:

  Numeric. The interpatch distance, in metres, that `buffered` was made
  for. Used only to label the plot.

- species:

  Character. Species name for plot title.

- col_barrier:

  Character. Colour for barrier layer. Defaults to the package palette,
  so a map drawn here matches the app, the downloads and the report. See
  [`urbio_colours()`](https://urbio-ecology.github.io/urbioconnect/reference/urbio_colours.md).

- col_interpatch_dist:

  Character. Colour for interpatch distance zone.

- col_habitat:

  Character. Colour for habitat patches.

- col_paper:

  Character. Background colour (default: "grey96").

## Value

A ggplot2 object.

## Examples

``` r
lizard_habitat <- example_habitat()
lizard_barrier <- example_barrier()
interpatch_distance <- 20

# the buffer habitat_connectivity() makes
lizard_full <- habitat_connectivity_full(
  habitat = lizard_habitat,
  barrier = lizard_barrier,
  interpatch_distance = interpatch_distance,
  verbose = FALSE
)

lizard_map <- gg_barrier_habitat_interpatch_dist(
  barrier = lizard_barrier,
  buffered = lizard_full$buffered_habitat,
  habitat = lizard_habitat,
  interpatch_distance = interpatch_distance,
  species = "Blue Tongue Lizard",
  col_barrier = "black",
  col_interpatch_dist = "lightgreen",
  col_habitat = "seagreen"
)
#> <SpatRaster> resampled to 500554 cells.
#> <SpatRaster> resampled to 500554 cells.
#> <SpatRaster> resampled to 500554 cells.

# add a north arrow and scale bar with ggspatial, if it is installed
if (requireNamespace("ggspatial", quietly = TRUE)) {
  lizard_map <- lizard_map +
    ggspatial::annotation_north_arrow(
      style = ggspatial::north_arrow_fancy_orienteering()
    ) +
    ggspatial::annotation_scale()
}

lizard_map
```
