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
#> # A tibble: 8 × 10
#>   scenario_name  measure species interpatch_distance n_patches effective_mesh_ha
#>   <chr>          <chr>   <chr>                 <dbl>     <dbl>             <dbl>
#> 1 Bentley Proje… baseli… Blue-t…                  50     73            4.47     
#> 2 Bentley Proje… scenar… Blue-t…                  50     72            4.47     
#> 3 Bentley Proje… change  Blue-t…                  50     -1           -0.0000113
#> 4 Bentley Proje… pct_ch… Blue-t…                  50     -1.37        -0.000252 
#> 5 Barrier upgra… baseli… Blue-t…                  50     73            4.47     
#> 6 Barrier upgra… scenar… Blue-t…                  50     68            0.815    
#> 7 Barrier upgra… change  Blue-t…                  50     -5           -3.66     
#> 8 Barrier upgra… pct_ch… Blue-t…                  50     -6.85       -81.8      
#> # ℹ 4 more variables: prob_connectedness <dbl>, patch_area_mean <dbl>,
#> #   patch_area_total_ha <dbl>, data_resolution <chr>

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
#> # A tibble: 4 × 10
#>   scenario_name  measure species interpatch_distance n_patches effective_mesh_ha
#>   <chr>          <chr>   <chr>                 <dbl>     <dbl>             <dbl>
#> 1 Bentley Proje… baseli… Superb…                 200    282                334. 
#> 2 Bentley Proje… scenar… Superb…                 200    267                280. 
#> 3 Bentley Proje… change  Superb…                 200    -15                -53.6
#> 4 Bentley Proje… pct_ch… Superb…                 200     -5.32             -16.1
#> # ℹ 4 more variables: prob_connectedness <dbl>, patch_area_mean <dbl>,
#> #   patch_area_total_ha <dbl>, data_resolution <chr>
# }
```
