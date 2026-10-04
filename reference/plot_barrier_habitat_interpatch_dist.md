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
  col_paper = NA
)
```

## Arguments

- barrier:

  barrier layer

- buffered:

  buffered layer

- habitat:

  habitat layer

- interpatch_distance:

  Numeric. The distance (in meters) where habitat patches are considered
  connected. E.g., if set to 500, patches 498m apart are connected,
  those 501m apart are not connected. This is passed internally to a
  spatial operation known as "buffering", where this distance is used as
  a radius from the edge of the habitat zone. This means the specified
  `interpatch_distance` is halved exactly. So an interpatch distance of
  500 will be converted to 250.

- species:

  character, species name, e.g., "Superb Fairy Wren"

- col_barrier:

  colour to colour the barrier layer. Defaults to the package palette,
  see
  [`urbio_colours()`](https://urbio-ecology.github.io/urbioconnect/reference/urbio_colours.md).

- col_interpatch_dist:

  colour to colour the interpatch distance layer

- col_habitat:

  colour to colour the habitat layer

- col_paper:

  colour to colour the paper layer of ggplot

## Value

Named character vector. The file path, named by the interpatch distance.

## Examples

``` r
if (FALSE) { # \dontrun{
lizard_habitat <- example_habitat()
lizard_barrier <- example_barrier()
buffered <- habitat_buffer(lizard_habitat, interpatch_distance = 10)
# Creates plot-barrier-interpatch-dist-habitat-*.png in the working directory
plot_barrier_habitat_interpatch_dist(
  barrier = lizard_barrier,
  buffered = buffered,
  habitat = lizard_habitat,
  interpatch_distance = 10,
  species = "Blue-tongued Lizard",
  col_barrier = "white",
  col_interpatch_dist = "lightgreen",
  col_habitat = "seagreen",
  col_paper = "grey50"
)
} # }
```
