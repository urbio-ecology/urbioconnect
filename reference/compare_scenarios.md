# Compare several scenarios against one baseline

Where
[`compare_connectivity()`](https://urbio-ecology.github.io/urbioconnect/reference/compare_connectivity.md)
compares a single scenario against a baseline, this compares as many as
you like, and labels each one. Give it a named list of `connectivity`
objects: the names become the `scenario_name` column, so a scenario can
be identified in the result.

## Usage

``` r
compare_scenarios(baseline, scenarios)
```

## Arguments

- baseline:

  A `connectivity` object (from
  [`habitat_connectivity()`](https://urbio-ecology.github.io/urbioconnect/reference/habitat_connectivity.md)
  or
  [`summarise_connectivity()`](https://urbio-ecology.github.io/urbioconnect/reference/summarise-connectivity.md))
  that every scenario is compared against. Must be a single row.

- scenarios:

  A named list of `connectivity` objects, one per scenario. Names must
  be present and unique, and each scenario must match `baseline` on
  species, interpatch_distance, and resolution.

## Value

A `compare_connectivity` object with four rows per scenario (`baseline`,
`scenario`, `change`, `pct_change`), labelled in the `scenario_name`
column. See
[`compare_connectivity()`](https://urbio-ecology.github.io/urbioconnect/reference/compare_connectivity.md)
for the columns.

## Details

If you have raster or vector layers rather than `connectivity` objects,
run
[`habitat_connectivity()`](https://urbio-ecology.github.io/urbioconnect/reference/habitat_connectivity.md)
on each one first, as in the second example below.

## See also

[`compare_connectivity()`](https://urbio-ecology.github.io/urbioconnect/reference/compare_connectivity.md)
for a single scenario, and
[`habitat_connectivity_comparison()`](https://urbio-ecology.github.io/urbioconnect/reference/habitat_connectivity_comparison.md),
which starts from habitat and barrier layers instead of `connectivity`
objects.

## Examples

``` r
baseline <- summarise_connectivity(lizard_areas_connected)

compare_scenarios(
  baseline = baseline,
  scenarios = list(
    "Bentley Project" = summarise_connectivity(lizard_areas_connected[-1, ]),
    "Barrier upgrade" = summarise_connectivity(
      lizard_areas_connected[-(1:5), ]
    )
  )
)
#> # Connectivity comparison: baseline / scenario / change / pct_change
#> # A tibble: 8 × 10
#>   scenario_name   measure    species             interpatch_distance n_patches
#>   <chr>           <chr>      <chr>                             <dbl>     <dbl>
#> 1 Bentley Project baseline   Blue-tongued Lizard                  50     73   
#> 2 Bentley Project scenario   Blue-tongued Lizard                  50     72   
#> 3 Bentley Project change     Blue-tongued Lizard                  50     -1   
#> 4 Bentley Project pct_change Blue-tongued Lizard                  50     -1.37
#> 5 Barrier upgrade baseline   Blue-tongued Lizard                  50     73   
#> 6 Barrier upgrade scenario   Blue-tongued Lizard                  50     68   
#> 7 Barrier upgrade change     Blue-tongued Lizard                  50     -5   
#> 8 Barrier upgrade pct_change Blue-tongued Lizard                  50     -6.85
#>   effective_mesh_ha prob_connectedness patch_area_mean patch_area_total_ha
#>               <dbl>              <dbl>           <dbl>               <dbl>
#> 1         4.47                1.70e- 5         3600.               26.3   
#> 2         4.47                1.70e- 5         3648.               26.3   
#> 3        -0.0000113          -4.28e-11           47.6              -0.0172
#> 4        -0.000252           -2.52e- 4            1.32             -0.0654
#> 5         4.47                1.70e- 5         3600.               26.3   
#> 6         0.815               3.10e- 6         2343.               15.9   
#> 7        -3.66               -1.39e- 5        -1257.              -10.3   
#> 8       -81.8                -8.18e+ 1          -34.9             -39.4   
#>   data_resolution
#>   <chr>          
#> 1 2x2            
#> 2 2x2            
#> 3 2x2            
#> 4 2x2            
#> 5 2x2            
#> 6 2x2            
#> 7 2x2            
#> 8 2x2            
#> # change = scenario - baseline (positive = scenario is higher)
#> # pct_change = 100 * change / baseline

# \donttest{
# starting from layers: build a `connectivity` object for each first
wren_habitat <- example_wren_habitat()
wren_barrier <- example_wren_barrier()

wren_baseline <- habitat_connectivity(
  habitat = wren_habitat,
  barrier = wren_barrier,
  species = "Superb Fairy Wren",
  interpatch_distance = 200,
  verbose = FALSE
)

bentley_project <- habitat_connectivity(
  habitat = example_wren_habitat_scenario(),
  barrier = wren_barrier,
  species = "Superb Fairy Wren",
  interpatch_distance = 200,
  verbose = FALSE
)

compare_scenarios(
  baseline = wren_baseline,
  scenarios = list("Bentley Project" = bentley_project)
)
#> # Connectivity comparison: baseline / scenario / change / pct_change
#> # A tibble: 4 × 10
#>   scenario_name   measure    species           interpatch_distance n_patches
#>   <chr>           <chr>      <chr>                           <dbl>     <dbl>
#> 1 Bentley Project baseline   Superb Fairy Wren                 200    282   
#> 2 Bentley Project scenario   Superb Fairy Wren                 200    267   
#> 3 Bentley Project change     Superb Fairy Wren                 200    -15   
#> 4 Bentley Project pct_change Superb Fairy Wren                 200     -5.32
#>   effective_mesh_ha prob_connectedness patch_area_mean patch_area_total_ha
#>               <dbl>              <dbl>           <dbl>               <dbl>
#> 1             334.          0.0000225          52556.               1482. 
#> 2             280.          0.0000189          45903.               1226. 
#> 3             -53.6        -0.00000362         -6653.               -256. 
#> 4             -16.1       -16.1                  -12.7               -17.3
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
