# Plot connectivity metrics across interpatch distances

Draws how the connectivity metrics change with the interpatch distance,
a panel per metric, each on its own scale.

## Usage

``` r
plot_connectivity(x, ...)

# Default S3 method
plot_connectivity(x, ...)

# S3 method for class 'compare_connectivity'
plot_connectivity(x, ...)
```

## Arguments

- x:

  A `connectivity` object, from
  [`habitat_connectivity()`](https://urbio-ecology.github.io/urbioconnect/reference/habitat_connectivity.md)
  or
  [`summarise_connectivity()`](https://urbio-ecology.github.io/urbioconnect/reference/summarise-connectivity.md),
  with a row per interpatch distance. Or a `compare_connectivity`
  object, from
  [`compare_connectivity()`](https://urbio-ecology.github.io/urbioconnect/reference/compare_connectivity.md),
  [`compare_scenarios()`](https://urbio-ecology.github.io/urbioconnect/reference/compare_scenarios.md),
  [`habitat_connectivity_comparison()`](https://urbio-ecology.github.io/urbioconnect/reference/habitat_connectivity_comparison.md)
  or
  [`habitat_connectivity_scenarios()`](https://urbio-ecology.github.io/urbioconnect/reference/habitat_connectivity_scenarios.md),
  with up to five scenarios. A scenario is labelled by its
  `scenario_name`, or "Scenario" when it has none.

- ...:

  Not used.

## Value

A ggplot2 object with a panel per connectivity metric.

## Details

Given a `connectivity` object, it draws a point per distance joined by a
line. A single distance is a single point.

Given a `compare_connectivity` object, it draws a bar for the baseline
and for each scenario at every interpatch distance, side by side, so you
can see where a scenario departs from the baseline and whether that
holds across distances.

The four metrics are `n_patches`, `prob_connectedness`,
`patch_area_mean` and `patch_area_total_ha`. `effective_mesh_ha` is left
out because it is `prob_connectedness` multiplied by the habitat area,
which is the same at every distance, so its panel would have the same
shape.

Values are drawn as they are. In a comparison, `prob_connectedness` is
measured against the baseline's habitat area, so a scenario that adds
habitat can score above 1, and the plot shows that rather than capping
it.

## See also

[`connectivity_display()`](https://urbio-ecology.github.io/urbioconnect/reference/connectivity_display.md)
for a comparison as a table.

## Examples

``` r
lizard_habitat <- example_habitat()
lizard_barrier <- example_barrier()
results <- purrr::map(
  c(10, 20),
  function(d) {
    full <- habitat_connectivity_full(lizard_habitat, lizard_barrier,
      interpatch_distance = d, verbose = FALSE)
    summarise_connectivity(
      connectivity = full$areas_connected$area,
      interpatch_distance = d,
      data_resolution = 10,
      species = "Blue-tongued Lizard"
    )
  }
) |> purrr::list_rbind()
plot_connectivity(results)


# a scenario against its baseline
baseline <- summarise_connectivity(lizard_areas_connected)
compare_scenarios(
  baseline = baseline,
  scenarios = list(
    "Bentley Project" = summarise_connectivity(lizard_areas_connected[-1, ]),
    "Barrier upgrade" = summarise_connectivity(
      lizard_areas_connected[-(1:5), ]
    )
  )
) |>
  plot_connectivity()
```
