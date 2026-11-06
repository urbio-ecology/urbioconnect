# Plot connected habitat patches

Visualises habitat patches coloured by their connected fragment ID.

## Usage

``` r
plot_patches(
  patch_id,
  interpatch_distance,
  species = "Species",
  n_cols = 7,
  barrier = NULL,
  buffered = NULL,
  directions = 4
)
```

## Arguments

- patch_id:

  Terra SpatRaster with a layer named `patch_id`, such as the
  `patch_id_raster` from
  [`habitat_connectivity_full()`](https://urbio-ecology.github.io/urbioconnect/reference/habitat_connectivity_full.md)
  or the result of
  [`add_patch_area()`](https://urbio-ecology.github.io/urbioconnect/reference/add_patch_area.md).

- interpatch_distance:

  Numeric. The interpatch distance, in metres, the patches were found
  with. Used only to label the plot.

- species:

  Character. Species name (default: "Species").

- n_cols:

  Integer. Number of colours to cycle through (default: 7).

- barrier:

  Terra SpatRaster, optional. The barrier layer the patches were found
  with, 1 where there is a barrier.

- buffered:

  Terra SpatRaster, optional. Needs `barrier`. The buffered habitat the
  patches were found with, from
  [`habitat_connectivity_full()`](https://urbio-ecology.github.io/urbioconnect/reference/habitat_connectivity_full.md).

- directions:

  Which neighbouring cells join, as in
  [`habitat_connectivity()`](https://urbio-ecology.github.io/urbioconnect/reference/habitat_connectivity.md):
  `4`, the default, or `8`. Used with `buffered` to find the zones, so
  give it the value the patches were found with.

## Value

A ggplot2 object showing patches with distinct colours.

## Details

With `barrier`, the barrier is drawn in grey. With `buffered` as well,
each patch's connecting zone, the buffered habitat cut by the barrier
that joins it into one patch, is shaded a paler version of its colour.
Buffer cut off from all habitat joins no patch, so it is left blank.

## Examples

``` r
lizard_barrier <- example_barrier()
interpatch_distance <- 20

# the patches habitat_connectivity() finds, and the buffer it finds them with
lizard_full <- habitat_connectivity_full(
  habitat = example_habitat(),
  barrier = lizard_barrier,
  interpatch_distance = interpatch_distance,
  verbose = FALSE
)

plot_patches(
  patch_id = lizard_full$patch_id_raster,
  interpatch_distance = interpatch_distance
)
#> <SpatRaster> resampled to 500554 cells.


# with the barrier
plot_patches(
  lizard_full$patch_id_raster,
  interpatch_distance,
  barrier = lizard_barrier
)
#> <SpatRaster> resampled to 500554 cells.


# with the barrier, and each patch's connecting zone shaded
lizard_patch_map <- plot_patches(
  lizard_full$patch_id_raster,
  interpatch_distance,
  barrier = lizard_barrier,
  buffered = lizard_full$buffered_habitat
)
#> <SpatRaster> resampled to 500554 cells.

# add a north arrow and scale bar with ggspatial, if it is installed
if (requireNamespace("ggspatial", quietly = TRUE)) {
  lizard_patch_map <- lizard_patch_map +
    ggspatial::annotation_north_arrow(
      style = ggspatial::north_arrow_fancy_orienteering()
    ) +
    ggspatial::annotation_scale()
}

lizard_patch_map
```
