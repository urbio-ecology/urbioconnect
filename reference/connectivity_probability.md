# Calculate connectivity probability

Computes the probability that two randomly chosen points within habitat
are connected, accounting for fragmentation. This is the effective mesh
size divided by the total habitat area, both in hectares.

## Usage

``` r
connectivity_probability(effective_mesh_ha, area_baseline_ha)
```

## Arguments

- effective_mesh_ha:

  Number. Effective mesh size in hectares, as returned by
  [`effective_mesh_size()`](https://urbio-ecology.github.io/urbioconnect/reference/effective_mesh_size.md).

- area_baseline_ha:

  Number. Total habitat area of the baseline landscape in hectares, as
  returned by
  [`total_habitat_area()`](https://urbio-ecology.github.io/urbioconnect/reference/total_habitat_area.md).

## Value

Numeric. Probability of connectedness: between 0 and 1 for a landscape
measured against itself.

## Details

To compare a design scenario against a baseline, pass the scenario's
effective mesh size, measured against the baseline areas, and the
baseline's total habitat area. A scenario that adds habitat can then
score above 1.

## Examples

``` r
area <- lizard_areas_connected$area
connectivity_probability(
  effective_mesh_ha = effective_mesh_size(area),
  area_baseline_ha = total_habitat_area(area)
)
#> [1] 0.1702211
# a scenario that loses the first patch, measured against the baseline
scenario_area <- area[-1]
scenario_mesh_ha <- effective_mesh_size(scenario_area, area_baseline = area)
connectivity_probability(
  effective_mesh_ha = scenario_mesh_ha,
  area_baseline_ha = total_habitat_area(area)
)
#> [1] 0.1702206
```
