# Compare several scenarios against one baseline, starting from layers

The layer-level counterpart to
[`compare_scenarios()`](https://urbio-ecology.github.io/urbioconnect/reference/compare_scenarios.md).
Give it one baseline habitat/barrier pair and named lists of scenario
layers, and it runs the connectivity pipeline on each and compares them
all against that baseline.

## Usage

``` r
habitat_connectivity_scenarios(
  habitat_baseline,
  barrier_baseline,
  species,
  habitat_scenarios = NULL,
  barrier_scenarios = NULL,
  interpatch_distance = NULL,
  buffer_radius = NULL,
  verbose = TRUE
)
```

## Arguments

- habitat_baseline:

  Terra SpatRaster. The baseline habitat layer.

- barrier_baseline:

  Terra SpatRaster. The baseline barrier layer.

- species:

  Species name. E.g., "Superb Fairy Wren".

- habitat_scenarios:

  A named list of habitat layers, one per scenario, each compared
  against `habitat_baseline` with the barrier held at
  `barrier_baseline`. Names become the `scenario_name` column.

- barrier_scenarios:

  A named list of barrier layers, the mirror of `habitat_scenarios`.
  Supply either list, or both; names must be unique across the two.

- interpatch_distance:

  Numeric. The distance (in metres) at which habitat patches are
  considered connected. May be a scalar or a vector; a vector runs every
  scenario once per distance. Provide exactly one of
  `interpatch_distance` or `buffer_radius`.

- buffer_radius:

  Numeric. The radius in metres around the habitat, an alternative to
  `interpatch_distance`.

- verbose:

  Logical. Display progress messages (default: TRUE).

## Value

A `compare_connectivity` object with four rows per scenario per
distance, labelled in the `scenario_name` column. Habitat scenarios come
first, then barrier scenarios, in the order given.

## Details

A scenario changes exactly one layer: habitat scenarios are run against
the baseline barrier, and barrier scenarios against the baseline
habitat. There's no way to write a scenario that changes both, which is
what
[`habitat_connectivity_comparison()`](https://urbio-ecology.github.io/urbioconnect/reference/habitat_connectivity_comparison.md)
has to check for.

The baseline is run once per distance and reused by every scenario, so
comparing three scenarios at one distance runs the pipeline four times,
not six.

## See also

[`compare_scenarios()`](https://urbio-ecology.github.io/urbioconnect/reference/compare_scenarios.md)
when you already have `connectivity` objects, and
[`habitat_connectivity_comparison()`](https://urbio-ecology.github.io/urbioconnect/reference/habitat_connectivity_comparison.md)
for a single scenario.

## Examples

``` r
# \donttest{
wren_habitat <- example_wren_habitat()
wren_barrier <- example_wren_barrier()

habitat_connectivity_scenarios(
  habitat_baseline = wren_habitat,
  barrier_baseline = wren_barrier,
  species = "Superb Fairy Wren",
  habitat_scenarios = list(
    "Bentley Project" = example_wren_habitat_scenario()
  ),
  barrier_scenarios = list(
    "Barrier upgrade" = example_wren_barrier_scenario()
  ),
  interpatch_distance = 200,
  verbose = FALSE
)
#> # Connectivity comparison: baseline / scenario / change / pct_change
#> # A tibble: 8 × 10
#>   scenario_name   measure    species           interpatch_distance n_patches
#>   <chr>           <chr>      <chr>                           <dbl>     <dbl>
#> 1 Bentley Project baseline   Superb Fairy Wren                 200   282    
#> 2 Bentley Project scenario   Superb Fairy Wren                 200   267    
#> 3 Bentley Project change     Superb Fairy Wren                 200   -15    
#> 4 Bentley Project pct_change Superb Fairy Wren                 200    -5.32 
#> 5 Barrier upgrade baseline   Superb Fairy Wren                 200   282    
#> 6 Barrier upgrade scenario   Superb Fairy Wren                 200   283    
#> 7 Barrier upgrade change     Superb Fairy Wren                 200     1    
#> 8 Barrier upgrade pct_change Superb Fairy Wren                 200     0.355
#>   effective_mesh_ha prob_connectedness patch_area_mean patch_area_total_ha
#>               <dbl>              <dbl>           <dbl>               <dbl>
#> 1           334.               2.25e-5        52556.               1482.  
#> 2           280.               1.89e-5        45903.               1226.  
#> 3           -53.6             -3.62e-6        -6653.               -256.  
#> 4           -16.1             -1.61e+1          -12.7               -17.3 
#> 5           334.               2.25e-5        52556.               1482.  
#> 6           333.               2.24e-5        51828.               1467.  
#> 7            -0.965           -6.51e-8         -728.                -15.3 
#> 8            -0.289           -2.89e-1           -1.38               -1.04
#>   data_resolution 
#>   <chr>           
#> 1 9.99673x10.00151
#> 2 9.99673x10.00151
#> 3 9.99673x10.00151
#> 4 9.99673x10.00151
#> 5 9.99673x10.00151
#> 6 9.99673x10.00151
#> 7 9.99673x10.00151
#> 8 9.99673x10.00151
#> # change = scenario - baseline (positive = scenario is higher)
#> # pct_change = 100 * change / baseline
# }
```
