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
that same change as `100 * change / baseline`, which puts every metric
on the same scale. Metric values are held at full precision - they are
not rounded - so `change` is exact.

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
#> # A tibble: 4 × 10
#>   scenario_name measure  species interpatch_distance n_patches effective_mesh_ha
#>   <chr>         <chr>    <chr>                 <dbl>     <dbl>             <dbl>
#> 1 NA            baseline Blue-t…                  50     73            4.47     
#> 2 NA            scenario Blue-t…                  50     72            4.47     
#> 3 NA            change   Blue-t…                  50     -1           -0.0000113
#> 4 NA            pct_cha… Blue-t…                  50     -1.37        -0.000252 
#> # ℹ 4 more variables: prob_connectedness <dbl>, patch_area_mean <dbl>,
#> #   patch_area_total_ha <dbl>, data_resolution <chr>

# label the scenario so it can be told apart from others
compare_connectivity(
  scenario = scenario,
  baseline = baseline,
  scenario_name = "Bentley Project"
)
#> # A tibble: 4 × 10
#>   scenario_name  measure species interpatch_distance n_patches effective_mesh_ha
#>   <chr>          <chr>   <chr>                 <dbl>     <dbl>             <dbl>
#> 1 Bentley Proje… baseli… Blue-t…                  50     73            4.47     
#> 2 Bentley Proje… scenar… Blue-t…                  50     72            4.47     
#> 3 Bentley Proje… change  Blue-t…                  50     -1           -0.0000113
#> 4 Bentley Proje… pct_ch… Blue-t…                  50     -1.37        -0.000252 
#> # ℹ 4 more variables: prob_connectedness <dbl>, patch_area_mean <dbl>,
#> #   patch_area_total_ha <dbl>, data_resolution <chr>
```
