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

If you have habitat and barrier rasters rather than `connectivity`
objects, run
[`habitat_connectivity()`](https://urbio-ecology.github.io/urbioconnect/reference/habitat_connectivity.md)
on each one first, as in the example below, or give the rasters to
[`habitat_connectivity_scenarios()`](https://urbio-ecology.github.io/urbioconnect/reference/habitat_connectivity_scenarios.md).
Put vector layers on a grid first, with
[`prepare_rasters()`](https://urbio-ecology.github.io/urbioconnect/reference/prepare_rasters.md)
and
[`onto_grid()`](https://urbio-ecology.github.io/urbioconnect/reference/onto_grid.md).

## See also

[`compare_connectivity()`](https://urbio-ecology.github.io/urbioconnect/reference/compare_connectivity.md)
for a single scenario, and
[`habitat_connectivity_comparison()`](https://urbio-ecology.github.io/urbioconnect/reference/habitat_connectivity_comparison.md),
which starts from habitat and barrier layers instead of `connectivity`
objects.

## Examples

``` r
# a `connectivity` object for the baseline, the lizard's landscape today
lizard_today <- habitat_connectivity(
  habitat = example_habitat(),
  barrier = example_barrier(),
  species = "Blue-tongued Lizard",
  interpatch_distance = 20,
  verbose = FALSE
)

# and one for each scenario, here a new road through the habitat
lizard_new_road <- habitat_connectivity(
  habitat = example_habitat(),
  barrier = example_barrier_scenario(),
  species = "Blue-tongued Lizard",
  interpatch_distance = 20,
  verbose = FALSE
)

# each scenario is compared against the baseline and labelled by its name
lizard_scenarios <- compare_scenarios(
  baseline = lizard_today,
  scenarios = list("New road" = lizard_new_road)
)

lizard_scenarios
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
summary(lizard_scenarios)
#> Scenario: New road
#> Interpatch distance: 20 m
#>   Metric          Baseline Scenario  Change % change
#>   Patches              163      170       7     4.29
#>   Mesh (ha)           4.42     2.09   -2.33    -52.7
#>   P(connected)       0.168   0.0795 -0.0887    -52.7
#>   Mean area (m2)      1610     1500    -114    -7.05
#>   Total area (ha)     26.3     25.5  -0.802    -3.05
```
