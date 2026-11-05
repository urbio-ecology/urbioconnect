# Everything one connectivity analysis produces

Runs the connectivity pipeline once per distance and keeps both the
summary and the spatial layers the maps need.
[`habitat_connectivity()`](https://urbio-ecology.github.io/urbioconnect/reference/habitat_connectivity.md)
returns the summary alone; this also keeps the buffered habitat and the
patch-ID raster for each distance, which is what the downloadable assets
and the report are built from.

## Usage

``` r
connectivity_report_data(
  habitat,
  barrier,
  species,
  interpatch_distance,
  habitat_scenario = NULL,
  barrier_scenario = NULL,
  scenario_name = NULL,
  settings = NULL,
  directions = 4,
  verbose = TRUE
)
```

## Arguments

- habitat:

  Terra SpatRaster. The habitat layer.

- barrier:

  Terra SpatRaster. The barrier layer.

- species:

  Species name. E.g., "Superb Fairy Wren".

- interpatch_distance:

  Numeric. The distance (in metres) at which habitat patches are
  considered connected. May be a scalar or a vector; a vector runs the
  pipeline once per distance.

- habitat_scenario, barrier_scenario:

  Optional. The whole habitat or barrier layer after a planned change,
  as an `sf`, `SpatVector` or `SpatRaster`: give one, not both. It is
  put on the grid of the layer it replaces with
  [`onto_grid()`](https://urbio-ecology.github.io/urbioconnect/reference/onto_grid.md),
  so it does not have to arrive on one. Supplying it runs the pipeline a
  second time, on the scenario landscape, and fills the `scenario_*`
  fields and `comparison` below. To compare a plan that changes both
  layers, use
  [`habitat_connectivity_comparison()`](https://urbio-ecology.github.io/urbioconnect/reference/habitat_connectivity_comparison.md).

- scenario_name:

  Optional name for the scenario, carried in the comparison so several
  can be stacked.

- settings:

  Optional named list of whatever produced this analysis that it can't
  derive for itself: the resolution
  [`prepare_rasters()`](https://urbio-ecology.github.io/urbioconnect/reference/prepare_rasters.md)
  was called with, where the layers came from, a run id. Each element
  becomes one row of
  [`connectivity_settings()`](https://urbio-ecology.github.io/urbioconnect/reference/connectivity_settings.md)
  and of the download bundle's `summary/settings.csv`, with a vector
  written as one comma-separated value. Each needs a name of its own,
  not one the analysis records itself.

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

A `connectivity_report_data` object: a list of

- `connectivity`, a `connectivity` summary with one row per distance

- `habitat` and `barrier`, the layers as supplied

- `buffered_habitat` and `patch_id_raster`, lists of `SpatRaster`, one
  per distance and named by it

- `species`, `interpatch_distance` and `directions`

- `settings`, the named character vector the caller recorded, and
  `run_time`, when the analysis ran.
  [`connectivity_settings()`](https://urbio-ecology.github.io/urbioconnect/reference/connectivity_settings.md)
  turns the two into the settings record.

and, when a scenario was given, the same view of the scenario landscape:
`scenario_kind`, `scenario_habitat`, `scenario_barrier`,
`scenario_buffered_habitat`, and `comparison`. Without one these are all
`NULL`.
[`scenario_layer()`](https://urbio-ecology.github.io/urbioconnect/reference/scenario_layer.md)
returns whichever layer the scenario changed.

## See also

[`habitat_connectivity()`](https://urbio-ecology.github.io/urbioconnect/reference/habitat_connectivity.md)
when only the summary is wanted, and
[`habitat_connectivity_comparison()`](https://urbio-ecology.github.io/urbioconnect/reference/habitat_connectivity_comparison.md)
for a scenario that changes both layers.

## Examples

``` r
# \donttest{
report_data <- connectivity_report_data(
  habitat = example_wren_habitat(),
  barrier = example_wren_barrier(),
  species = "Superb Fairy Wren",
  interpatch_distance = 200,
  verbose = FALSE
)

report_data$connectivity
#> # A tibble: 1 × 9
#>   species     interpatch_distance n_patches effective_mesh_ha prob_connectedness
#>   <chr>                     <dbl>     <int>             <dbl>              <dbl>
#> 1 Superb Fai…                 200       282              334.              0.225
#> # ℹ 4 more variables: patch_area_mean <dbl>, patch_area_total_ha <dbl>,
#> #   data_resolution <chr>, patch_size <list>
names(report_data$patch_id_raster)
#> [1] "200"

# with a scenario, the baseline and the scenario are each run once and
# the comparison is built from the two
with_scenario <- connectivity_report_data(
  habitat = example_wren_habitat(),
  barrier = example_wren_barrier(),
  species = "Superb Fairy Wren",
  interpatch_distance = 200,
  barrier_scenario = example_wren_barrier_scenario(),
  verbose = FALSE
)

with_scenario$comparison
#> # A tibble: 4 × 10
#>   scenario_name measure  species interpatch_distance n_patches effective_mesh_ha
#>   <chr>         <chr>    <chr>                 <dbl>     <dbl>             <dbl>
#> 1 NA            baseline Superb…                 200   282               334.   
#> 2 NA            scenario Superb…                 200   283               333.   
#> 3 NA            change   Superb…                 200     1                -0.965
#> 4 NA            pct_cha… Superb…                 200     0.355            -0.289
#> # ℹ 4 more variables: prob_connectedness <dbl>, patch_area_mean <dbl>,
#> #   patch_area_total_ha <dbl>, data_resolution <chr>
# }
```
