# Compare the connectivity of two scenarios

We can measure the connectivity of a given habitat and barrier with
[`habitat_connectivity()`](https://urbio-ecology.github.io/urbioconnect/reference/habitat_connectivity.md).
We can also compare the connectivity, say for example if you have the
same area habitat and barrier, but you want to understand what the
change in connectedness is when you remove, or add some habitat, or some
barrier(s). This function helps you do that, by comparing a "scenario"
`connectivity` object against a "baseline" `connectivity` object (both
created by
[`habitat_connectivity()`](https://urbio-ecology.github.io/urbioconnect/reference/habitat_connectivity.md)
or
[`summarise_connectivity()`](https://urbio-ecology.github.io/urbioconnect/reference/summarise-connectivity.md)).

## Usage

``` r
compare_connectivity(scenario, baseline, scenario_name = NULL)
```

## Arguments

- scenario:

  A `connectivity` object (from
  [`habitat_connectivity()`](https://urbio-ecology.github.io/urbioconnect/reference/habitat_connectivity.md)
  or
  [`summarise_connectivity()`](https://urbio-ecology.github.io/urbioconnect/reference/summarise-connectivity.md)).
  The scenario to compare against `baseline`. Must be a single row.

- baseline:

  A `connectivity` object (from
  [`habitat_connectivity()`](https://urbio-ecology.github.io/urbioconnect/reference/habitat_connectivity.md)
  or
  [`summarise_connectivity()`](https://urbio-ecology.github.io/urbioconnect/reference/summarise-connectivity.md)).
  The reference the `scenario` is compared against. Must be a single
  row, and match `scenario` on species, interpatch_distance, and
  resolution.

- scenario_name:

  Character. An optional label for the scenario, for example "Bentley
  Project". Appears in the `scenario_name` column on every row. Defaults
  to `NULL`, which gives `NA`.

## Value

A `compare_connectivity` object: a tibble with four rows (`baseline`,
`scenario`, `change`, `pct_change`, in the `measure` column) and the
same metric columns as
[`summarise_connectivity()`](https://urbio-ecology.github.io/urbioconnect/reference/summarise-connectivity.md)
output: `scenario_name`, `measure`, `species`, `interpatch_distance`,
`n_patches`, `effective_mesh_ha`, `prob_connectedness`,
`patch_area_mean`, `patch_area_total_ha`, and `data_resolution`. The
`change` row is `scenario - baseline`, so a positive value means the
scenario is higher than the baseline; the `pct_change` row expresses
that same change as `100 * change / baseline`, which is the readable
form for metrics whose absolute deltas are very small. Metric values are
held at full precision — they are not rounded — so `change` is exact.

## Details

If you have raster or vector layers rather than `connectivity` objects,
use
[`habitat_connectivity_comparison()`](https://urbio-ecology.github.io/urbioconnect/reference/habitat_connectivity_comparison.md),
which runs
[`habitat_connectivity()`](https://urbio-ecology.github.io/urbioconnect/reference/habitat_connectivity.md)
on each scenario for you and then calls this function.

## See also

[`habitat_connectivity_comparison()`](https://urbio-ecology.github.io/urbioconnect/reference/habitat_connectivity_comparison.md),
which starts from habitat and barrier layers instead of `connectivity`
objects,
[`habitat_connectivity()`](https://urbio-ecology.github.io/urbioconnect/reference/habitat_connectivity.md),
and
[`summarise_connectivity()`](https://urbio-ecology.github.io/urbioconnect/reference/summarise-connectivity.md).

## Examples

``` r
# build `connectivity` objects cheaply (no spatial pipeline) and compare them
baseline <- summarise_connectivity(lizard_areas_connected)
# a scenario in which one connected patch (the first row) is lost
scenario <- summarise_connectivity(lizard_areas_connected[-1, ])
compare_connectivity(scenario = scenario, baseline = baseline)
#> # Connectivity comparison: baseline / scenario / change / pct_change
#> # A tibble: 4 × 10
#>   scenario_name measure    species             interpatch_distance n_patches
#>   <chr>         <chr>      <chr>                             <dbl>     <dbl>
#> 1 NA            baseline   Blue-tongued Lizard                  50     73   
#> 2 NA            scenario   Blue-tongued Lizard                  50     72   
#> 3 NA            change     Blue-tongued Lizard                  50     -1   
#> 4 NA            pct_change Blue-tongued Lizard                  50     -1.37
#>   effective_mesh_ha prob_connectedness patch_area_mean patch_area_total_ha
#>               <dbl>              <dbl>           <dbl>               <dbl>
#> 1         4.47                1.70e- 5         3600.               26.3   
#> 2         4.47                1.70e- 5         3648.               26.3   
#> 3        -0.0000113          -4.28e-11           47.6              -0.0172
#> 4        -0.000252           -2.52e- 4            1.32             -0.0654
#>   data_resolution
#>   <chr>          
#> 1 2x2            
#> 2 2x2            
#> 3 2x2            
#> 4 2x2            
#> # change = scenario - baseline (positive = scenario is higher)
#> # pct_change = 100 * change / baseline

# label the scenario so it can be told apart from others
compare_connectivity(
  scenario = scenario,
  baseline = baseline,
  scenario_name = "Bentley Project"
)
#> # Connectivity comparison: baseline / scenario / change / pct_change
#> # A tibble: 4 × 10
#>   scenario_name   measure    species             interpatch_distance n_patches
#>   <chr>           <chr>      <chr>                             <dbl>     <dbl>
#> 1 Bentley Project baseline   Blue-tongued Lizard                  50     73   
#> 2 Bentley Project scenario   Blue-tongued Lizard                  50     72   
#> 3 Bentley Project change     Blue-tongued Lizard                  50     -1   
#> 4 Bentley Project pct_change Blue-tongued Lizard                  50     -1.37
#>   effective_mesh_ha prob_connectedness patch_area_mean patch_area_total_ha
#>               <dbl>              <dbl>           <dbl>               <dbl>
#> 1         4.47                1.70e- 5         3600.               26.3   
#> 2         4.47                1.70e- 5         3648.               26.3   
#> 3        -0.0000113          -4.28e-11           47.6              -0.0172
#> 4        -0.000252           -2.52e- 4            1.32             -0.0654
#>   data_resolution
#>   <chr>          
#> 1 2x2            
#> 2 2x2            
#> 3 2x2            
#> 4 2x2            
#> # change = scenario - baseline (positive = scenario is higher)
#> # pct_change = 100 * change / baseline
```
