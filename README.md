
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

`urbioconnect` provides tools to quantify ecological connectivity for
different urban wildlife species based on:

- wildlife **habitat**
- urban **barrier**
- the roaming range (in metres) of the wildlife
- A few other parameters

An example of this is raster grid data on blue tongued-lizard
**habitat**, raster grid data on road and buildings (**barriers**), and
how far their roaming range is (say, 100 metres).

`urbioconnect` computes metrics for assessing the connectedness of these
habitat patches:

- effective mesh size
- probability of connectedness
- number of patches
- total patch area, and
- mean patch area

Note you can use **vector** (shapefile) or **raster** data for habitat
and barrier formats.

This method is described in:

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
<https://njtierney.shinyapps.io/urbioconnect/>

You do not need the shiny app to perform analyses. All functions have
been designed to work together in a pipeline - see example usage below.

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

``` r
library(urbioconnect)
library(terra)
#> terra 1.9.34

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

``` r
# run the full raster pipeline at a 10m interpatch distance
areas <- habitat_connectivity(
  habitat  = habitat,
  barrier  = barrier,
  species = "Blue-tongued Lizard",
  interpatch_distance = 10
)
#> ℹ Creating barrier mask
#> ✔ Creating barrier mask [60ms]
#> 
#> ℹ Removing habitat underneath barrier
#> ✔ Removing habitat underneath barrier [21ms]
#> 
#> ℹ Adding 5m buffer (interpatch distance 10m)
#> Warning: Buffer radius doesn't align with the raster resolution.
#> ✖ 5 m isn't a multiple of 2 m.
#> ℹ It snaps to 4 m (interpatch distance 8 m).
#> ℹ Connectivity may shift for patches near the cut-off.
#> ℹ See `vignette(urbioconnect::interpatch-distance-and-resolution)`.
#> ✔ Adding 5m buffer (interpatch distance 10m) [126ms]
#> 
#> ℹ Fragmenting habitat layer along barrier intersection
#> ✔ Fragmenting habitat layer along barrier intersection [20ms]
#> 
#> ℹ Assigning patches ID to fragments
#> ✔ Assigning patches ID to fragments [1.1s]
#> 
#> ℹ Summarising area in each patch
#> ✔ Summarising area in each patch [147ms]
#> 

areas
#> # A tibble: 1 × 9
#>   species     interpatch_distance n_patches effective_mesh_ha prob_connectedness
#>   <chr>                     <dbl>     <int>             <dbl>              <dbl>
#> 1 Blue-tongu…                  10       703                 4           0.000015
#> # ℹ 4 more variables: patch_area_mean <dbl>, patch_area_total_ha <dbl>,
#> #   data_resolution <chr>, patch_size <list>
```

`areas` already contains the landscape-level summary (effective mesh
size, probability of connectedness, patch counts, and so on). The
per-patch areas that summary is built from are stored in a list-column,
and can be pulled out with `patch_sizes()`:

``` r
patch_sizes(areas)[[1]]
#> # patch_size_tbl:      data.frame
#> # Species:             Blue-tongued Lizard
#> # Patches:             703
#> # Resolution:          2x2
#> # Interpatch Distance: 10 m
#>   patch_id    area
#>      <dbl>   <dbl>
#> 1        1    60.0
#> 2        2  1648. 
#> 3        7    12.0
#> 4        8  1200. 
#> 5       10 92034. 
#> # ℹ 698 more rows
```

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
