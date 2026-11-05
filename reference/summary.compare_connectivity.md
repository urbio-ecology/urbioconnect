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
baseline <- summarise_connectivity(lizard_areas_connected)
# a scenario in which five connected patches (the first five rows) are lost
scenario <- summarise_connectivity(lizard_areas_connected[-(1:5), ])

comparison <- compare_connectivity(
  scenario = scenario,
  baseline = baseline,
  scenario_name = "Bentley Project"
)

comparison_summary <- summary(comparison)
comparison_summary
#> Scenario: Bentley Project
#> Interpatch distance: 50 m
#>   Metric          Baseline Scenario Change % change
#>   Patches               73       68     -5    -6.85
#>   Mesh (ha)           4.47    0.815  -3.66    -81.8
#>   P(connected)        0.17    0.031 -0.139    -81.8
#>   Mean area (m2)      3600     2340  -1260    -34.9
#>   Total area (ha)     26.3     15.9  -10.3    -39.4

# the values are still numbers
comparison_summary[["% change"]]
#> [1]  -6.85 -81.80 -81.80 -34.90 -39.40
```
