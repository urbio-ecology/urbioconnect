# Compare habitat connectivity of a scenario against a baseline

Starts from habitat and barrier layers, rather than the `connectivity`
objects
[`compare_connectivity()`](https://urbio-ecology.github.io/urbioconnect/reference/compare_connectivity.md)
takes. Give it a scenario habitat/barrier pair and a baseline
habitat/barrier pair and it runs the full connectivity pipeline on each
(via
[`habitat_connectivity()`](https://urbio-ecology.github.io/urbioconnect/reference/habitat_connectivity.md))
and compares them. Provide either an `interpatch_distance` or a
`buffer_radius` (as with
[`habitat_connectivity()`](https://urbio-ecology.github.io/urbioconnect/reference/habitat_connectivity.md));
`interpatch_distance` may be a vector, in which case the comparison is
run once per distance and the per-distance results are stacked.

## Usage

``` r
habitat_connectivity_comparison(
  habitat_scenario,
  barrier_scenario,
  habitat_baseline,
  barrier_baseline,
  species,
  interpatch_distance = NULL,
  buffer_radius = NULL,
  scenario_name = NULL,
  verbose = TRUE
)
```

## Arguments

- habitat_scenario:

  Terra SpatRaster. The scenario habitat layer.

- barrier_scenario:

  Terra SpatRaster. The scenario barrier layer.

- habitat_baseline:

  Terra SpatRaster. The baseline habitat layer.

- barrier_baseline:

  Terra SpatRaster. The baseline barrier layer.

- species:

  Species name. E.g., "Superb Fairy Wren".

- interpatch_distance:

  Numeric. The distance (in metres) at which habitat patches are
  considered connected. May be a scalar or a vector; a vector runs the
  comparison once per distance. Provide exactly one of
  `interpatch_distance` or `buffer_radius`. See
  [`habitat_connectivity()`](https://urbio-ecology.github.io/urbioconnect/reference/habitat_connectivity.md)
  for the interpatch distance / buffer radius relationship.

- buffer_radius:

  Numeric. The radius in metres around the habitat, an alternative to
  `interpatch_distance`. Provide exactly one of `interpatch_distance` or
  `buffer_radius`. See
  [`habitat_connectivity()`](https://urbio-ecology.github.io/urbioconnect/reference/habitat_connectivity.md).

- scenario_name:

  Character. An optional label for the scenario, for example "Bentley
  Project". Passed to
  [`compare_connectivity()`](https://urbio-ecology.github.io/urbioconnect/reference/compare_connectivity.md),
  and appears in the `scenario_name` column on every row. Defaults to
  `NULL`, which gives `NA`.

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

Change exactly one layer between baseline and scenario so the difference
is attributable to a single variable. To assess a barrier change, pass
the same habitat to both `habitat_baseline` and `habitat_scenario`; to
assess a habitat change, pass the same barrier to both
`barrier_baseline` and `barrier_scenario`. If both the habitat *and* the
barrier differ the function aborts; if neither differs it warns (the
scenario equals the baseline, so every `change` value is zero).

Note that this runs the full connectivity pipeline
`2 * length(interpatch_distance)` times (buffering is the slow step), so
a long vector of distances will take proportionally longer.

## See also

[`compare_connectivity()`](https://urbio-ecology.github.io/urbioconnect/reference/compare_connectivity.md),
[`habitat_connectivity()`](https://urbio-ecology.github.io/urbioconnect/reference/habitat_connectivity.md)

## Examples

``` r
# \donttest{
habitat_connectivity_comparison(
  habitat_scenario = example_wren_habitat(),
  barrier_scenario = example_wren_barrier_scenario(),
  habitat_baseline = example_wren_habitat(),
  barrier_baseline = example_wren_barrier(),
  species = "Superb Fairy Wren",
  interpatch_distance = 200,
  verbose = FALSE
)
#> # Connectivity comparison: baseline / scenario / change / pct_change
#> # A tibble: 4 × 10
#>   scenario_name measure    species           interpatch_distance n_patches
#>   <chr>         <chr>      <chr>                           <dbl>     <dbl>
#> 1 NA            baseline   Superb Fairy Wren                 200   282    
#> 2 NA            scenario   Superb Fairy Wren                 200   283    
#> 3 NA            change     Superb Fairy Wren                 200     1    
#> 4 NA            pct_change Superb Fairy Wren                 200     0.355
#>   effective_mesh_ha prob_connectedness patch_area_mean patch_area_total_ha
#>               <dbl>              <dbl>           <dbl>               <dbl>
#> 1           334.          0.0000225           52556.               1482.  
#> 2           333.          0.0000224           51828.               1467.  
#> 3            -0.965      -0.0000000651         -728.                -15.3 
#> 4            -0.289      -0.289                  -1.38               -1.04
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
