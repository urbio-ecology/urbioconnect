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
on the same scale. The scenario's `effective_mesh_ha` and
`prob_connectedness` are measured against the baseline's habitat area,
so they can differ from what
[`habitat_connectivity()`](https://urbio-ecology.github.io/urbioconnect/reference/habitat_connectivity.md)
gives the scenario on its own. Metric values are held at full
precision - they are not rounded - so `change` is exact.

## Details

If you have habitat and barrier rasters rather than `connectivity`
objects, use
[`habitat_connectivity_comparison()`](https://urbio-ecology.github.io/urbioconnect/reference/habitat_connectivity_comparison.md),
which runs
[`habitat_connectivity()`](https://urbio-ecology.github.io/urbioconnect/reference/habitat_connectivity.md)
on each scenario for you and then calls this function. Put vector layers
on a grid first, with
[`prepare_rasters()`](https://urbio-ecology.github.io/urbioconnect/reference/prepare_rasters.md)
and
[`onto_grid()`](https://urbio-ecology.github.io/urbioconnect/reference/onto_grid.md).

## See also

[`habitat_connectivity_comparison()`](https://urbio-ecology.github.io/urbioconnect/reference/habitat_connectivity_comparison.md),
which starts from habitat and barrier layers instead of `connectivity`
objects,
[`habitat_connectivity()`](https://urbio-ecology.github.io/urbioconnect/reference/habitat_connectivity.md),
and
[`summarise_connectivity()`](https://urbio-ecology.github.io/urbioconnect/reference/summarise-connectivity.md).

## Examples

``` r
# the lizard's landscape today
lizard_today <- habitat_connectivity(
  habitat = example_habitat(),
  barrier = example_barrier(),
  species = "Blue-tongued Lizard",
  interpatch_distance = 20,
  verbose = FALSE
)

lizard_today
#> # A tibble: 1 × 9
#>   species     interpatch_distance n_patches effective_mesh_ha prob_connectedness
#>   <chr>                     <dbl>     <int>             <dbl>              <dbl>
#> 1 Blue-tongu…                  20       163              4.42              0.168
#> # ℹ 4 more variables: patch_area_mean <dbl>, patch_area_total_ha <dbl>,
#> #   data_resolution <chr>, patch_size <list>

# and with a new road through the habitat
lizard_new_road <- habitat_connectivity(
  habitat = example_habitat(),
  barrier = example_barrier_scenario(),
  species = "Blue-tongued Lizard",
  interpatch_distance = 20,
  verbose = FALSE
)

lizard_new_road
#> # A tibble: 1 × 9
#>   species     interpatch_distance n_patches effective_mesh_ha prob_connectedness
#>   <chr>                     <dbl>     <int>             <dbl>              <dbl>
#> 1 Blue-tongu…                  20       170              2.16             0.0846
#> # ℹ 4 more variables: patch_area_mean <dbl>, patch_area_total_ha <dbl>,
#> #   data_resolution <chr>, patch_size <list>

# against today's habitat, so mesh and connectedness differ from above
lizard_road_comparison <- compare_connectivity(
  scenario = lizard_new_road,
  baseline = lizard_today,
  scenario_name = "New road"
)

lizard_road_comparison
#> # A tibble: 4 × 10
#>   scenario_name measure  species interpatch_distance n_patches effective_mesh_ha
#>   <chr>         <chr>    <chr>                 <dbl>     <dbl>             <dbl>
#> 1 New road      baseline Blue-t…                  20    163                 4.42
#> 2 New road      scenario Blue-t…                  20    170                 2.09
#> 3 New road      change   Blue-t…                  20      7                -2.33
#> 4 New road      pct_cha… Blue-t…                  20      4.29            -52.7 
#> # ℹ 4 more variables: prob_connectedness <dbl>, patch_area_mean <dbl>,
#> #   patch_area_total_ha <dbl>, data_resolution <chr>

# a row per metric, the baseline and scenario side by side
summary(lizard_road_comparison)
#> Scenario: New road
#> Interpatch distance: 20 m
#>   Metric          Baseline Scenario  Change % change
#>   Patches              163      170       7     4.29
#>   Mesh (ha)           4.42     2.09   -2.33    -52.7
#>   P(connected)       0.168   0.0795 -0.0887    -52.7
#>   Mean area (m2)      1610     1500    -114    -7.05
#>   Total area (ha)     26.3     25.5  -0.802    -3.05
```
