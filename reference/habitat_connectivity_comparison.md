# Compare habitat connectivity of a scenario against a baseline

Starts from habitat and barrier layers, rather than the `connectivity`
objects
[`compare_connectivity()`](https://urbio-ecology.github.io/urbioconnect/reference/compare_connectivity.md)
takes. Give it the baseline's habitat and barrier, and the layers a
planned change replaces, and it runs the full connectivity pipeline (via
[`habitat_connectivity()`](https://urbio-ecology.github.io/urbioconnect/reference/habitat_connectivity.md))
on the baseline and on the scenario and compares them.
`interpatch_distance` may be a vector, in which case the comparison is
run once per distance and the per-distance results are stacked.

## Usage

``` r
habitat_connectivity_comparison(
  habitat_baseline,
  barrier_baseline,
  species,
  interpatch_distance,
  habitat_scenario = NULL,
  barrier_scenario = NULL,
  scenario_name = NULL,
  directions = 4,
  verbose = TRUE
)
```

## Arguments

- habitat_baseline:

  Terra SpatRaster. The baseline habitat layer: the landscape as it is
  today.

- barrier_baseline:

  Terra SpatRaster. The baseline barrier layer.

- species:

  Species name. E.g., "Superb Fairy Wren".

- interpatch_distance:

  Numeric. The distance (in metres) at which habitat patches are
  considered connected. May be a scalar or a vector; a vector runs the
  comparison once per distance. See
  [`habitat_connectivity()`](https://urbio-ecology.github.io/urbioconnect/reference/habitat_connectivity.md).

- habitat_scenario:

  Terra SpatRaster, or `NULL`. The whole habitat layer after the planned
  change, on the same grid as `habitat_baseline`.

- barrier_scenario:

  Terra SpatRaster, or `NULL`. The whole barrier layer after the planned
  change, on the same grid as `barrier_baseline`.

- scenario_name:

  Character. An optional label for the scenario, for example "Bentley
  Project". Passed to
  [`compare_connectivity()`](https://urbio-ecology.github.io/urbioconnect/reference/compare_connectivity.md),
  and appears in the `scenario_name` column on every row. Defaults to
  `NULL`, which gives `NA`.

- directions:

  Which neighbouring raster cells join into one patch, passed to
  [`terra::patches()`](https://rspatial.github.io/terra/reference/patches.html).
  `4`, the default, is the rook's case: cells join only through a shared
  edge. `8` is the queen's case: cells that touch only at a corner join
  as well. It applies to rasters only, not to
  [`sf_habitat_connectivity()`](https://urbio-ecology.github.io/urbioconnect/reference/sf_habitat_connectivity.md).

- verbose:

  Logical. Display progress messages (default: TRUE).

## Value

A `compare_connectivity` object: a tibble with four rows (`baseline`,
`scenario`, `change`, `pct_change`) per interpatch distance. A scalar
`interpatch_distance` gives four rows; a length-3 vector gives twelve
rows (four per distance). See
[`compare_connectivity()`](https://urbio-ecology.github.io/urbioconnect/reference/compare_connectivity.md)
for the columns.

## Details

A scenario is the landscape after a planned change. Give the layers the
plan changes, and the function takes the rest from the baseline:

|                    |                        |                        |
|--------------------|------------------------|------------------------|
| You give           | The scenario's habitat | The scenario's barrier |
| `habitat_scenario` | `habitat_scenario`     | `barrier_baseline`     |
| `barrier_scenario` | `habitat_baseline`     | `barrier_scenario`     |
| both               | `habitat_scenario`     | `barrier_scenario`     |

Each layer you give must be the whole layer after the change, not just
the part that changes: a barrier scenario holding only a new road drops
every existing road. If you give both, the comparison shows their
combined effect, not how much came from each; to see each one's share,
run it again with one layer at a time. The shares won't add up exactly,
because changes interact: a new road beside new habitat matters more
than either alone.

A scenario layer must be on the same grid as the layer it replaces, or
this gives an error: put it there with
[`onto_grid()`](https://urbio-ecology.github.io/urbioconnect/reference/onto_grid.md).
A scenario identical to the baseline gives a warning, since every
`change` value will be zero.

This runs the full connectivity pipeline
`2 * length(interpatch_distance)` times (buffering is the slow step), so
a long vector of distances will take proportionally longer.

## See also

[`habitat_connectivity_scenarios()`](https://urbio-ecology.github.io/urbioconnect/reference/habitat_connectivity_scenarios.md)
for several scenarios at once,
[`compare_connectivity()`](https://urbio-ecology.github.io/urbioconnect/reference/compare_connectivity.md),
[`habitat_connectivity()`](https://urbio-ecology.github.io/urbioconnect/reference/habitat_connectivity.md),
and
[`vignette("scenario-comparison")`](https://urbio-ecology.github.io/urbioconnect/articles/scenario-comparison.md).

## Examples

``` r
# a new road changes the barrier; the habitat stays as it is today
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
