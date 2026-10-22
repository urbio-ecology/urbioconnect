library(urbioconnect)
lizard_habitat <- example_habitat()
lizard_barrier <- example_barrier()

results <- purrr::map(
  c(10, 20),
  function(d) {
    full <- habitat_connectivity_full(
      lizard_habitat,
      lizard_barrier,
      interpatch_distance = d,
      verbose = FALSE
    )
    summarise_connectivity(
      connectivity = full$areas_connected$area,
      interpatch_distance = d,
      data_resolution = 10,
      species = "Blue-tongued Lizard"
    )
  }
) |>
  purrr::list_rbind()

plot_connectivity(results)

# Now let's do this for scenarios

lizard_barrier_scenario <- example_barrier_scenario()

comparison_multiple_distances <- purrr::map(
  .x = c(80, 160, 320),
  .f = function(distance) {
    habitat_connectivity_comparison(
      habitat_baseline = lizard_habitat,
      barrier_baseline = lizard_barrier,
      habitat_scenario = lizard_habitat,
      barrier_scenario = lizard_barrier_scenario,
      species = "Blue-tongued Lizard",
      interpatch_distance = distance,
      scenario_name = "one"
    )
  }
)

comparison_multiple_distances_df <- purrr::list_rbind(
  comparison_multiple_distances
)

library(tidyverse)
comparison_multiple_distances_df_short <- comparison_multiple_distances_df |>
  filter(
    measure %in% c("baseline", "scenario")
  )

results

comparison_multiple_distances_df_short |>
  select(scenario)

ggplot(
  comparison_multiple_distances_df_short,
  aes(
    x = interpatch_distance,
    y = n_patches,
    colour = measure
  )
) +
  geom_point() +
  geom_line()

plot_connectivity(results)
