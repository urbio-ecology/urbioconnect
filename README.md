
<!-- README.md is generated from README.Rmd. Please edit that file -->

# urbioconnect

<!-- badges: start -->

[![R-CMD-check](https://github.com/urbio-ecology/urbioconnect/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/urbio-ecology/urbioconnect/actions/workflows/R-CMD-check.yaml)
[![R-universe
version](https://urbio-ecology.r-universe.dev/urbioconnect/badges/version)](https://urbio-ecology.r-universe.dev/urbioconnect)
[![Codecov test
coverage](https://codecov.io/gh/urbio-ecology/urbioconnect/graph/badge.svg)](https://app.codecov.io/gh/urbio-ecology/urbioconnect)
[![build-desktop-app](https://github.com/urbio-ecology/urbioconnect/actions/workflows/build-desktop-app.yaml/badge.svg)](https://github.com/urbio-ecology/urbioconnect/actions/workflows/build-desktop-app.yaml)
<!-- badges: end -->

``` r
library(urbioconnect)
```

`urbioconnect` provides tools to quantify ecological connectivity of
wildlife in urban areas. It was designed to facilitate understanding how
barriers might change or impact how connected species are. The tool uses
these key inputs:

- wildlife **habitat**
- urban **barrier**
- the roaming range (in metres) of the wildlife - say, 40m.

Let’s brief show some examples of this habitat and barrier data:

- raster grid data on blue tongued-lizard **habitat**

``` r
library(terra)
#> terra 1.9.50

habitat <- example_habitat()

plot(habitat, col = "seagreen", legend = FALSE, main = "Lizard Habitat")
```

<img src="man/figures/README-unnamed-chunk-3-1.png" alt="" width="100%" />

- raster grid data on road and buildings (**barriers**)

``` r
barrier <- example_barrier()
plot(barrier, col = c("grey", "white"), legend = FALSE, main = "Lizard Barriers")
```

<img src="man/figures/README-unnamed-chunk-4-1.png" alt="" width="100%" />

In brief, the method of `urbioconnect` uses this habitat, barrier, and
interpatch distance (roaming distance) data to identify which habitats
are connected or not. A species would be connected if the edges of their
habitat are within range of the interpatch distance - which they may not
be if there is a subtantial barrier between them.

We can use this method to create metrics on how connected the species
are, which are:

- effective mesh size
- probability of connectedness
- number of patches
- total patch area, and
- mean patch area

Note you can use **vector** (shapefile) or **raster** data for habitat
and barrier formats.

The full method is described in:

> Kirk, H., Soanes, K., Amati, M., Bekessy, S., Harrison, L., Parris,
> K., Ramalho, C., van de Ree, R., & Threlfall, C. (2023). Ecological
> connectivity as a planning tool for the conservation of wildlife in
> cities. *MethodsX*, 10, 101989.
> <https://doi.org/10.1016/j.mex.2022.101989>

See the [getting
started](https://urbio-ecology.github.io/urbioconnect/articles/getting-started.html)
vignette for more details.

## Shiny app

We include a Shiny app for interactive analysis and report generation.
You can launch the interactive Shiny app with:

``` r
library(urbioconnect)
run_connectivity_app()
```

A hosted version is available at:
<https://njtierney-urbioconnect.share.connect.posit.cloud/>

You do not need the shiny app to perform analyses. All functions have
been designed to work together in a script. We have examples usages
below.

## Installation

Install from [R-universe](https://urbio-ecology.r-universe.dev/builds):

``` r
install.packages(
  "urbioconnect",
  repos = c("https://urbio-ecology.r-universe.dev", "https://cloud.r-project.org")
)
```

Or from GitHub:

``` r
# install.packages("pak")
pak::pak("urbio-ecology/urbioconnect")
```

## Get started

Let’s look at the habitat and barrier data again:

``` r
library(urbioconnect)
library(terra)

# load example habitat and barrier rasters
habitat <- example_habitat()
barrier <- example_barrier()

plot(habitat, col = "seagreen", legend = FALSE, main = "Lizard Habitat")
plot(barrier, col = c("grey", "white"), legend = FALSE, main = "Lizard Barriers")
```

<img src="man/figures/README-get-started-1.png" alt="" width="45%" /><img src="man/figures/README-get-started-2.png" alt="" width="45%" />

``` r
plot(barrier, col = c("grey", "white"), legend = FALSE, main = "Lizard Barriers and Habitat")
plot(habitat, col = "seagreen", legend = FALSE, add = TRUE)
```

<img src="man/figures/README-lizard-hab-barrier-1.png" alt="" width="90%" />

You can then run the full raster pipeline at, say, a 40m interpatch
distance:

``` r
# run the full raster pipeline at a 10m interpatch distance
areas <- habitat_connectivity(
  habitat  = habitat,
  barrier  = barrier,
  species = "Blue-tongued Lizard",
  interpatch_distance = 40
)
#> ℹ Creating barrier mask
#> ✔ Creating barrier mask [40ms]
#> 
#> ℹ Removing habitat underneath barrier
#> ✔ Removing habitat underneath barrier [37ms]
#> 
#> ℹ Buffering habitat for an interpatch distance of 40m
#> ✔ Buffering habitat for an interpatch distance of 40m [148ms]
#> 
#> ℹ Fragmenting habitat layer along barrier intersection
#> ✔ Fragmenting habitat layer along barrier intersection [14ms]
#> 
#> ℹ Assigning patches ID to fragments
#> ✔ Assigning patches ID to fragments [523ms]
#> 
#> ℹ Summarising area in each patch
#> ✔ Summarising area in each patch [93ms]
#> 

areas
#> # A tibble: 1 × 9
#>   species     interpatch_distance n_patches effective_mesh_ha prob_connectedness
#>   <chr>                     <dbl>     <int>             <dbl>              <dbl>
#> 1 Blue-tongu…                  40        81              4.45              0.169
#> # ℹ 4 more variables: patch_area_mean <dbl>, patch_area_total_ha <dbl>,
#> #   data_resolution <chr>, patch_size <list>
```

`areas` contains the landscape-level summary (effective mesh size,
probability of connectedness, patch counts, and so on).

If you want to see a plot of the individual patches that were
identified, use `plot_patches()`

``` r
patch_sizes(areas)[[1]]
#> # patch_size_tbl:      data.frame
#> # Species:             Blue-tongued Lizard
#> # Patches:             81
#> # Resolution:          2x2
#> # Interpatch Distance: 40 m
#>   patch_id    area
#>      <dbl>   <dbl>
#> 1        1 97898. 
#> 2        2  2416. 
#> 3        3  1304. 
#> 4        4    40.0
#> 5        5  1592. 
#> # ℹ 76 more rows
```

`habitat_connectivity()` runs all the steps of the pipeline - if you
want the intermediate objects that are created during the analysis, say
for example if you want to plot some of the rasters, you can use
`habitat_connectivity_full()`:

``` r
areas_full <- habitat_connectivity_full(
  habitat  = habitat,
  barrier  = barrier,
  interpatch_distance = 40
)
#> ℹ Creating barrier mask
#> ✔ Creating barrier mask [15ms]
#> 
#> ℹ Removing habitat underneath barrier
#> ✔ Removing habitat underneath barrier [65ms]
#> 
#> ℹ Buffering habitat for an interpatch distance of 40m
#> ✔ Buffering habitat for an interpatch distance of 40m [177ms]
#> 
#> ℹ Fragmenting habitat layer along barrier intersection
#> ✔ Fragmenting habitat layer along barrier intersection [11ms]
#> 
#> ℹ Assigning patches ID to fragments
#> ✔ Assigning patches ID to fragments [591ms]
#> 
#> ℹ Summarising area in each patch
#> ✔ Summarising area in each patch [36ms]
#> 
```

And then pass key information along to `plot_patches()`:

``` r
plot_patches(
  patch_id = areas_full$patch_id_raster,
  interpatch_distance = 40,
  barrier = barrier,
  buffered = areas_full$buffered_habitat
  )
#> <SpatRaster> resampled to 500554 cells.
```

<img src="man/figures/README-unnamed-chunk-6-1.png" alt="" width="100%" />

## Works with raster and vector (shapefile)

See the vignette,
[“raster-vs-vector”](https://urbio-ecology.github.io/urbioconnect/articles/raster-vs-vector.html)
for a side-by-side comparison and guidance on when to use raster or
vector. We mostly recommend using raster.

# Example usage

We have an example pipeline using `targets` and `geotarget`, which
includes generating reports as output at
<https://github.com/urbio-ecology/urbio-eco-targets>. See the vignette
[“Using urbioconnect in a targets
pipeline”](https://urbio-ecology.github.io/urbioconnect/articles/targets-pipeline.html)
for more detail.

# Acknowledgements

This research was conducted on the unceded lands of the Wurundjeri Woi
Wurrung and Bunurong Boon Wurrung peoples of the Eastern Kulin Nation,
and the unceded lands of nipaluna, lutruwita of the muwinina people. We
would like to thank Kylie Soanes, Marco Amati, Sarah Bekessy, Lee
Harrison, Kirsten Parris, Cristina Ramalho, Rodney van de Ree, and
Caragh Threlfall for their work on the original paper this work is based
upon. We would also like to thank Hugh Stanford, Nadine Gaskell, Kerryn
Kneebone, and Nicholas Golding for their comments and insight during the
development of the methods and software.
