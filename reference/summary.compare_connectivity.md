# Summarise a comparison for reading

A `compare_connectivity` object has a column per metric, so printed in
the console it hides the metrics that don't fit.
[`summary()`](https://rspatial.github.io/terra/reference/summary.html)
turns it round: one row per metric, with the baseline, the scenario, the
change and the per cent change side by side, rounded as
[`connectivity_display()`](https://urbio-ecology.github.io/urbioconnect/reference/connectivity_display.md)
describes.

## Usage

``` r
# S3 method for class 'compare_connectivity'
summary(object, ...)
```

## Arguments

- object:

  A `compare_connectivity` object, from
  [`compare_connectivity()`](https://urbio-ecology.github.io/urbioconnect/reference/compare_connectivity.md),
  [`compare_scenarios()`](https://urbio-ecology.github.io/urbioconnect/reference/compare_scenarios.md),
  [`habitat_connectivity_comparison()`](https://urbio-ecology.github.io/urbioconnect/reference/habitat_connectivity_comparison.md)
  or
  [`habitat_connectivity_scenarios()`](https://urbio-ecology.github.io/urbioconnect/reference/habitat_connectivity_scenarios.md).

- ...:

  Not used. Must be empty.

## Value

A `summary_compare_connectivity` object: a tibble with one row per
metric for each scenario and interpatch distance. Its columns are
`Scenario` (only when a scenario is named), `Distance (m)`, `Metric`,
`Baseline`, `Scenario value`, `Change` and `% change`. The values are
rounded but stay numeric, so they can be filtered, sorted or plotted.

It prints one table per scenario and interpatch distance, each under a
line naming the scenario and a line giving the distance, with the
scenarios in the order given and then by distance. An unnamed scenario
has the distance line only. Since the heading names the scenario, the
printed table heads its values "Scenario" rather than "Scenario value".

## See also

[`compare_connectivity()`](https://urbio-ecology.github.io/urbioconnect/reference/compare_connectivity.md),
and `round_by(connectivity_display(x))`, which gives the same table as a
plain tibble.

## Examples

``` r
# a new road through the lizard's habitat, against the landscape today
lizard_road_comparison <- habitat_connectivity_comparison(
  habitat_baseline = example_habitat(),
  barrier_baseline = example_barrier(),
  species = "Blue-tongued Lizard",
  interpatch_distance = 20,
  barrier_scenario = example_barrier_scenario(),
  scenario_name = "New road",
  verbose = FALSE
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
lizard_road_summary <- summary(lizard_road_comparison)

lizard_road_summary
#> Scenario: New road
#> Interpatch distance: 20 m
#>   Metric          Baseline Scenario  Change % change
#>   Patches              163      170       7     4.29
#>   Mesh (ha)           4.42     2.09   -2.33    -52.7
#>   P(connected)       0.168   0.0795 -0.0887    -52.7
#>   Mean area (m2)      1610     1500    -114    -7.05
#>   Total area (ha)     26.3     25.5  -0.802    -3.05

# the values are still numbers
lizard_road_summary[["% change"]]
#> [1]   4.29 -52.70 -52.70  -7.05  -3.05
```
