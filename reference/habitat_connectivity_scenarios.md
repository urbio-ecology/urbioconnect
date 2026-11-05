# Compare several scenarios against one baseline, starting from layers

Each layer in `habitat_scenarios` or `barrier_scenarios` is its own
scenario that changes that one layer; the lists are never combined. A
habitat scenario runs against `barrier_baseline`, and a barrier scenario
against `habitat_baseline`. For a scenario that changes both layers, use
[`habitat_connectivity_comparison()`](https://urbio-ecology.github.io/urbioconnect/reference/habitat_connectivity_comparison.md).

## Usage

``` r
habitat_connectivity_scenarios(
  habitat_baseline,
  barrier_baseline,
  species,
  interpatch_distance,
  habitat_scenarios = NULL,
  barrier_scenarios = NULL,
  directions = 4,
  verbose = TRUE
)
```

## Arguments

- habitat_baseline:

  Terra SpatRaster. The baseline habitat layer: the landscape as it is
  today.

- barrier_baseline:

  Terra SpatRaster. The baseline barrier layer.

- species:

  Species name. E.g., "Superb Fairy Wren".

- interpatch_distance:

  Numeric. The distance (in metres) at which habitat patches are
  considered connected. May be a scalar or a vector; a vector runs every
  scenario once per distance.

- habitat_scenarios:

  A named list of habitat layers, one per scenario. Names become the
  `scenario_name` column.

- barrier_scenarios:

  A named list of barrier layers, the mirror of `habitat_scenarios`.
  Give either list, or both; names must be unique across the two.

- directions:

  Which neighbouring raster cells join into one patch, passed to
  [`terra::patches()`](https://rspatial.github.io/terra/reference/patches.html).
  `4`, the default, is the rook's case: cells join only through a shared
  edge. `8` is the queen's case: cells that touch only at a corner join
  as well. It applies to rasters only, not to
  [`sf_habitat_connectivity()`](https://urbio-ecology.github.io/urbioconnect/reference/sf_habitat_connectivity.md).

- verbose:

  Logical. Display progress messages (default: TRUE).

## Value

A `compare_connectivity` object with four rows per scenario per
distance, labelled in the `scenario_name` column. Habitat scenarios come
first, then barrier scenarios, in the order given.

## Details

The layer-level counterpart to
[`compare_scenarios()`](https://urbio-ecology.github.io/urbioconnect/reference/compare_scenarios.md):
it runs the connectivity pipeline on each scenario and compares them all
against the baseline. The baseline is run once per distance and reused
by every scenario, so comparing three scenarios at one distance runs the
pipeline four times, not six.

Each scenario layer must be the whole layer after the change, on the
same grid as the layer it replaces, or this gives an error: put it there
with
[`onto_grid()`](https://urbio-ecology.github.io/urbioconnect/reference/onto_grid.md).

## See also

[`compare_scenarios()`](https://urbio-ecology.github.io/urbioconnect/reference/compare_scenarios.md)
when you already have `connectivity` objects,
[`habitat_connectivity_comparison()`](https://urbio-ecology.github.io/urbioconnect/reference/habitat_connectivity_comparison.md)
for one scenario, including one that changes both layers, and
[`vignette("scenario-comparison")`](https://urbio-ecology.github.io/urbioconnect/articles/scenario-comparison.md).

## Examples

``` r
# \donttest{
wren_habitat <- example_wren_habitat()
wren_barrier <- example_wren_barrier()

habitat_connectivity_scenarios(
  habitat_baseline = wren_habitat,
  barrier_baseline = wren_barrier,
  species = "Superb Fairy Wren",
  interpatch_distance = 200,
  habitat_scenarios = list(
    "Bentley Project" = example_wren_habitat_scenario()
  ),
  barrier_scenarios = list(
    "Barrier upgrade" = example_wren_barrier_scenario()
  ),
  verbose = FALSE
)
#> # A tibble: 8 × 10
#>   scenario_name  measure species interpatch_distance n_patches effective_mesh_ha
#>   <chr>          <chr>   <chr>                 <dbl>     <dbl>             <dbl>
#> 1 Bentley Proje… baseli… Superb…                 200   282               334.   
#> 2 Bentley Proje… scenar… Superb…                 200   267               280.   
#> 3 Bentley Proje… change  Superb…                 200   -15               -53.6  
#> 4 Bentley Proje… pct_ch… Superb…                 200    -5.32            -16.1  
#> 5 Barrier upgra… baseli… Superb…                 200   282               334.   
#> 6 Barrier upgra… scenar… Superb…                 200   283               333.   
#> 7 Barrier upgra… change  Superb…                 200     1                -0.965
#> 8 Barrier upgra… pct_ch… Superb…                 200     0.355            -0.289
#> # ℹ 4 more variables: prob_connectedness <dbl>, patch_area_mean <dbl>,
#> #   patch_area_total_ha <dbl>, data_resolution <chr>
# }
```
