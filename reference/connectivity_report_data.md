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
  scenario = NULL,
  scenario_kind = NULL,
  scenario_name = NULL,
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

- scenario:

  Optional layer to compare against the baseline: an `sf`, `SpatVector`
  or `SpatRaster` standing in for one of `habitat` and `barrier`. It is
  put on the baseline's own grid with
  [`onto_grid()`](https://urbio-ecology.github.io/urbioconnect/reference/onto_grid.md),
  so it does not have to arrive on one. Supplying it runs the pipeline a
  second time, on the scenario landscape, and fills the `scenario_*`
  fields and `comparison` below.

- scenario_kind:

  Which layer `scenario` replaces, `"habitat"` or `"barrier"`. Required
  with `scenario`. Only one layer may change at a time, so that the
  difference in connectivity is attributable to it.

- scenario_name:

  Optional name for the scenario, carried in the comparison so several
  can be stacked.

- verbose:

  Logical. Display progress messages (default: TRUE).

## Value

A `connectivity_report_data` object: a list of

- `connectivity`, a `connectivity` summary with one row per distance

- `habitat` and `barrier`, the layers as supplied

- `buffered_habitat` and `patch_id_raster`, lists of `SpatRaster`, one
  per distance and named by it

- `species` and `interpatch_distance`

and, when a `scenario` was given, the same view of the scenario
landscape: `scenario_kind`, `scenario_habitat`, `scenario_barrier`,
`scenario_buffered_habitat`, and `comparison`. Without one these are all
`NULL`.
[`scenario_layer()`](https://urbio-ecology.github.io/urbioconnect/reference/scenario_layer.md)
returns whichever layer the scenario changed.

## See also

[`habitat_connectivity()`](https://urbio-ecology.github.io/urbioconnect/reference/habitat_connectivity.md)
when only the summary is wanted, and
[`habitat_connectivity_comparison()`](https://urbio-ecology.github.io/urbioconnect/reference/habitat_connectivity_comparison.md)
to compare two landscapes you have already assembled yourself.

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
#> 1 Superb Fai…                 200       282              334.          0.0000225
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
  scenario = example_wren_barrier_scenario(),
  scenario_kind = "barrier",
  verbose = FALSE
)

with_scenario$comparison
#> # Connectivity comparison: baseline / scenario / change / pct_change
#> # A tibble: 4 × 10
#>   scenario_name measure    species           interpatch_distance n_patches
#>   <chr>         <chr>      <chr>                           <dbl>     <dbl>
#> 1 NA            baseline   Superb Fairy Wren                 200   282    
#> 2 NA            scenario   Superb Fairy Wren                 200   283    
#> 3 NA            change     Superb Fairy Wren                 200     1    
#> 4 NA            pct_change Superb Fairy Wren                 200     0.355
#>   effective_mesh_ha prob_connectedness patch_area_mean patch_area_total_ha
#>               <dbl>              <dbl>           <dbl>               <dbl>
#> 1           334.          0.0000225           52556.               1482.  
#> 2           333.          0.0000224           51828.               1467.  
#> 3            -0.965      -0.0000000651         -728.                -15.3 
#> 4            -0.289      -0.289                  -1.38               -1.04
#>   data_resolution 
#>   <chr>           
#> 1 9.99673x10.00151
#> 2 9.99673x10.00151
#> 3 9.99673x10.00151
#> 4 9.99673x10.00151
#> # change = scenario - baseline (positive = scenario is higher)
#> # pct_change = 100 * change / baseline
# }
```
