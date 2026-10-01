# Using urbioconnect in a targets pipeline

``` r

library(urbioconnect)
```

## Why use targets for connectivity analysis?

Habitat connectivity analysis involves expensive raster operations:
buffering, masking, and patch identification. Depending on the size of
the raster or vector files, these operations can take minutes to hours
to run. When you are iterating on your analysis (trying different buffer
distances, updating input data, or fine-tuning parameters), re-running
everything from scratch is slowed down, and you can end up being unsure
if everything is up to date, so you just run it all again.

In an ideal world you would only need to run code that has changed, or
has had its dependencies change.

The [targets](https://docs.ropensci.org/targets/) package addresses this
issue by only running code that has been changed. You can think of this
as a kind of **intelligent caching**: it tracks every input and output
in your pipeline and only re-runs the steps whose inputs have changed.
If you add a new interpatch distance, targets re-runs only the
connectivity step for that distance - not the data preparation or the
other interpatch distances.

`urbioconnect` is works well in a targets pipeline, and this vignette
unpacks an example pipeline, describing how it works.

We first discuss a minimal pipeline, before going on to add multiple
interpatch distances, and then finally demonstrate how to take advantage
of parallel processing.

## A minimal `_targets.R`

The following `_targets.R` file uses the built-in lizard example data
and runs connectivity analysis at one interpatch distance.

Place this code in a file in the root of your project directory, and
name it `_targets.R`:

``` r

# _targets.R
library(geotargets)
library(tarchetypes)
library(targets)
library(terra)
library(urbioconnect)

## Load any R files
tar_source()

## Assign like regular R, just make sure to pipe into a tar_ operation
tar_assign({
  species <- tar_target("Blue-Tongued-Lizard")
  data_resolution <- tar_target(10)
  interpatch_distance <- tar_target(10)
  
  barrier <- example_barrier() |> tar_terra_rast()
  habitat <- example_habitat() |> tar_terra_rast()

  barrier_mask <- create_barrier_mask(barrier) |> tar_terra_rast()
  remaining <- drop_habitat_under_barrier(habitat, barrier_mask) |>
    tar_terra_rast()
  buffered_habitat <- habitat_buffer(remaining, interpatch_distance = interpatch_distance) |>
    tar_terra_rast()
  fragmentation_raster <- fragment_habitat(buffered_habitat, barrier_mask) |>
    tar_terra_rast()

  # get IDs of connected areas
  # intersect with habitat to get area IDs of habitat patches
  patches <- assign_patches_to_fragments(remaining, fragmentation_raster) |>
    add_patch_area() |>
    tar_terra_rast()
  areas <- aggregate_connected_patches(patches) |>
    tar_target()

  # or as one step
  areas_connected <- habitat_connectivity(
    habitat = habitat,
    barrier = barrier,
    species = "Blue-tongued Lizard",
    interpatch_distance = interpatch_distance
  ) |>
    tar_target()

  results_connect_habitat <- summarise_connectivity(
    connectivity = areas_connected
  ) |>
    tar_target()
})
```

### What each section does

This `tar_assign({` does something special

``` r

tar_assign({
})
```

It means we get to use `<-` like we do in normal R, and it marks it as
something that is part of a targets pipeline.

We specify that each of these things below are to be watched with
targets with
[`tar_target()`](https://docs.ropensci.org/targets/reference/tar_target.html):

``` r

  species <- tar_target("Blue-Tongued-Lizard")
  target_resolution <- tar_target(500)
  interpatch_distance <- tar_target(10)
```

This means if any of these variables are changed, say
`interpatch_distance` changes from 10 and 20, then anything using
`distance` would need to get rerun.

These parts here:

``` r

example_habitat() |> tar_terra_rast()
example_barrier() |> tar_terra_rast()
```

Are somewhat special because
[`example_habitat()`](https://urbio-ecology.github.io/urbioconnect/reference/example-lizard-data.md)
creates an example habitat raster file:

``` r

example_habitat()
#> class       : SpatRaster
#> size        : 763, 766, 1  (nrow, ncol, nlyr)
#> resolution  : 2, 2  (x, y)
#> extent      : 326109.6, 327641.6, 5820362, 5821888  (xmin, xmax, ymin, ymax)
#> coord. ref. : GDA94 / MGA zone 55 (EPSG:28355)
#> source      : lizard_habitat_raster.tif
#> name        : Pseudo Layer
#> min value   :            1
#> max value   :            1
```

but instead of using
[`tar_target()`](https://docs.ropensci.org/targets/reference/tar_target.html),
we use `tar_terra_rast()`. The reason is essentially that raster objects
are very special and need to be treated differently by targets. This is
made possible by the R package, `geotargets`, which extends targets to
cover special geospatial objects. Read more at
<https://github.com/ropensci/geotargets>.

In a project using real data, you would replace
[`example_habitat()`](https://urbio-ecology.github.io/urbioconnect/reference/example-lizard-data.md)
and
[`example_barrier()`](https://urbio-ecology.github.io/urbioconnect/reference/example-lizard-data.md)
with your own loading code, which might look like this:

``` r

tar_file(habitat_file, "data/habitat.tif")
rast(habitat_file) |> tar_terra_rast()
```

Targets will re-run this step only if the file, `habitat_file` changes.

The rest of the code then follows as we have done in other examples, the
most important difference being that every example must be designated as
a target, using something such as
[`tar_target()`](https://docs.ropensci.org/targets/reference/tar_target.html),
`tar_terra_rast()`, or similar.

## Running and inspecting the pipeline

### Running

From an R session in your project directory run the following

``` r

targets::tar_make()
```

On first run, every target is computed and cached. When you run it
again, only out-of-date targets are re-computed.

If you need to force everything to re-run, you can do the following:

``` r

targets::tar_invalidate(everything())
targets::tar_make()
```

### Inspecting results

You can load the individual targets back into your R session using
[`tar_load()`](https://docs.ropensci.org/targets/reference/tar_load.html)

``` r

# The combined summary table
targets::tar_load(results_connect_habitat)
results_connect_habitat

# The connectivity data frame for a specific interpatch distance
targets::tar_load(connectivity_50)
connectivity_50
```

### Visualising the dependency graph

Before running, you can inspect the pipeline graph to check the
dependency structure looks correct:

``` r

targets::tar_visnetwork()
```

## Example workflows

This is a very simple demonstration of using targets, for other more
complex examples, which includes quarto report generation, and parallel
execution, see:

**<https://github.com/urbio-ecology/urbio-eco-targets>**

That repository demonstrates:

- Loading real habitat and barrier shapefiles and converting them with
  [`prepare_rasters()`](https://urbio-ecology.github.io/urbioconnect/reference/prepare_rasters.md)
- Saving habitat interpatch distance plots to files with
  [`plot_barrier_habitat_interpatch_dist()`](https://urbio-ecology.github.io/urbioconnect/reference/plot_barrier_habitat_interpatch_dist.md)
- Rendering a quarto report as a targets artefact
- Using `geotargets` to store terra rasters natively in the targets
  cache
