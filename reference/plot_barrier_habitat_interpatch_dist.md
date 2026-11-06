# Save barrier habitat interpatch distance plot

Draws the plot
[`gg_barrier_habitat_interpatch_dist()`](https://urbio-ecology.github.io/urbioconnect/reference/gg_barrier_habitat_interpatch_dist.md)
makes and writes it to a PNG in the working directory, at the shared
size from
[`urbio_figure_size()`](https://urbio-ecology.github.io/urbioconnect/reference/urbio_figure_size.md).
Returns the file path, which is what a `targets::tar_file()` target
wants.

## Usage

``` r
plot_barrier_habitat_interpatch_dist(
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
  for. Used only to label the plot and name the file.

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

Named character vector. The file path, named by the interpatch distance.

## Examples

``` r
if (FALSE) { # \dontrun{
lizard_habitat <- example_habitat()
lizard_barrier <- example_barrier()
interpatch_distance <- 20
lizard_full <- habitat_connectivity_full(
  habitat = lizard_habitat,
  barrier = lizard_barrier,
  interpatch_distance = interpatch_distance,
  verbose = FALSE
)
# Creates plot-barrier-interpatch-distance-habitat-*.png in the working
# directory
plot_barrier_habitat_interpatch_dist(
  barrier = lizard_barrier,
  buffered = lizard_full$buffered_habitat,
  habitat = lizard_habitat,
  interpatch_distance = interpatch_distance,
  species = "Blue-tongued Lizard",
  col_barrier = "white",
  col_interpatch_dist = "lightgreen",
  col_habitat = "seagreen",
  col_paper = "grey50"
)
} # }
```
