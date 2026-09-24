library(urbioconnect)
library(terra)

# This tutorial walks through comparing a *scenario* against a *baseline*. A
# scenario isolates a single change — either the habitat layer OR the barrier
# layer — so its effect on connectivity can be measured cleanly. We demonstrate
# both the barrier-change case and the symmetric habitat-change case.

# Load the baseline habitat and barrier rasters
wren_habitat <- example_wren_habitat()
wren_barrier <- example_wren_barrier()

# Load the two scenario layers. Each is derived from a baseline layer with a
# single change applied: `wren_barrier_scenario` adds barriers, while
# `wren_habitat_scenario` removes a corner patch of habitat (a "development").
wren_barrier_scenario <- example_wren_barrier_scenario()
wren_habitat_scenario <- example_wren_habitat_scenario()

plot(
  wren_barrier,
  col = c("grey", "white"),
  legend = FALSE,
  main = "Wren Habitat and Barrier"
)
plot(wren_habitat, col = "darkgreen", legend = FALSE, add = TRUE)

plot(
  wren_barrier_scenario,
  col = c("grey", "white"),
  legend = FALSE,
  main = "Wren Habitat and Barrier scenario"
)
plot(wren_habitat, col = "darkgreen", legend = FALSE, add = TRUE)

plot(
  wren_barrier,
  col = c("grey", "white"),
  legend = FALSE,
  main = "Wren Habitat scenario and Barrier"
)
plot(wren_habitat_scenario, col = "darkgreen", legend = FALSE, add = TRUE)

terra::res(wren_habitat)
terra::res(wren_barrier)
terra::res(wren_barrier_scenario)
terra::res(wren_habitat_scenario)

# Build the two `connectivity` objects with `habitat_connectivity()`. This is a
# barrier-only scenario: the habitat layer is held constant and only the barrier
# layer changes (baseline barrier vs scenario barrier), both at the same
# interpatch distance.
wren_connectivity_baseline <- habitat_connectivity(
  habitat = wren_habitat,
  barrier = wren_barrier,
  species = "Superb Fairy Wren",
  interpatch_distance = 200
)

wren_connectivity_scenario <- habitat_connectivity(
  habitat = wren_habitat,
  barrier = wren_barrier_scenario,
  species = "Superb Fairy Wren",
  interpatch_distance = 200
)

wren_connectivity_baseline
wren_connectivity_scenario

# `patch_sizes()` retrieves the per-patch data (one row per patch) from a
# `connectivity` object, so the workflow can, for example, generate a patch_id
# plot from the underlying spatial data.
patch_sizes(wren_connectivity_baseline)
patch_sizes(wren_connectivity_scenario)

# `summarise_connectivity()` takes the per-patch table, not the summary, and
# measures it against itself. `habitat_connectivity()` already called it for
# you, so this returns the same summary you already have. Baseline-vs-scenario
# comparison is a separate operation, handled by the entry points below.
summarise_connectivity(patch_sizes(wren_connectivity_baseline)[[1]])

# --- Comparison, layer 1: object-in primitive --------------------------------
# `compare_connectivity()` takes two single-row `connectivity` objects (the
# output of `habitat_connectivity()`) and returns a 3-row `compare_connectivity`
# tibble: one `baseline` row, one `scenario` row, and one `change` row (scenario
# minus baseline; positive = scenario higher than baseline).
compare_connectivity(
  scenario = wren_connectivity_scenario,
  baseline = wren_connectivity_baseline
)

# --- Comparison, layer 2: spatial-in wrapper ---------------------------------
# `habitat_connectivity_comparison()` is the spatial-in wrapper over
# `compare_connectivity()`. It runs `habitat_connectivity()` on the baseline and
# on the scenario for you, then compares them.

# Barrier-change comparison: only the barrier layer differs (habitat is passed
# unchanged on both sides).
habitat_connectivity_comparison(
  habitat_scenario = wren_habitat,
  barrier_scenario = wren_barrier_scenario,
  habitat_baseline = wren_habitat,
  barrier_baseline = wren_barrier,
  species = "Superb Fairy Wren",
  interpatch_distance = 200
)

# Habitat-change comparison: the symmetric case. Only the habitat layer differs
# (a development removes a corner patch); the barrier is passed unchanged on both
# sides.
habitat_connectivity_comparison(
  habitat_scenario = wren_habitat_scenario,
  barrier_scenario = wren_barrier,
  habitat_baseline = wren_habitat,
  barrier_baseline = wren_barrier,
  species = "Superb Fairy Wren",
  interpatch_distance = 200
)

# `interpatch_distance` accepts a vector: the wrapper sweeps over each distance
# and binds the per-distance comparisons. A length-3 vector returns 12 rows
# (3 distances x baseline/scenario/change/pct_change).
habitat_connectivity_comparison(
  habitat_scenario = wren_habitat,
  barrier_scenario = wren_barrier_scenario,
  habitat_baseline = wren_habitat,
  barrier_baseline = wren_barrier,
  species = "Superb Fairy Wren",
  interpatch_distance = c(100, 200, 400)
)

# One variable at a time: a comparison must isolate a single change. If BOTH the
# habitat AND the barrier differ from baseline, the wrapper aborts. The call
# below intentionally errors ("Both habitat and barrier differ from baseline.
# Change only one at a time.") — `try()` lets the tutorial run past it so you can
# see the error message.
try(
  habitat_connectivity_comparison(
    habitat_scenario = wren_habitat_scenario,
    barrier_scenario = wren_barrier_scenario,
    habitat_baseline = wren_habitat,
    barrier_baseline = wren_barrier,
    species = "Superb Fairy Wren",
    interpatch_distance = 200
  )
)

# --- Naming a scenario -------------------------------------------------------
# A comparison can carry a label, which travels in the `scenario_name` column.
# Without one that column is NA. This matters as soon as there is more than one
# scenario in a table, since the label is the only thing telling them apart.
habitat_connectivity_comparison(
  habitat_scenario = wren_habitat_scenario,
  barrier_scenario = wren_barrier,
  habitat_baseline = wren_habitat,
  barrier_baseline = wren_barrier,
  species = "Superb Fairy Wren",
  interpatch_distance = 200,
  scenario_name = "Bentley Project"
)

# --- Comparison, layer 3: several scenarios at once --------------------------
# `habitat_connectivity_scenarios()` compares many scenarios against one
# baseline. Scenarios are grouped by the layer they change: habitat scenarios
# run against the baseline barrier, barrier scenarios against the baseline
# habitat. A scenario that changes both layers cannot be written, so the
# one-variable-at-a-time rule is enforced by the shape of the call rather than
# by the error you saw above.
#
# The baseline is run once per distance and reused by every scenario, so this
# runs the pipeline three times, not four.
wren_scenarios <- habitat_connectivity_scenarios(
  habitat_baseline = wren_habitat,
  barrier_baseline = wren_barrier,
  species = "Superb Fairy Wren",
  habitat_scenarios = list("Bentley Project" = wren_habitat_scenario),
  barrier_scenarios = list("Barrier upgrade" = wren_barrier_scenario),
  interpatch_distance = 200
)

wren_scenarios

# --- Reading across scenarios ------------------------------------------------
# Four rows per scenario is a lot to read. Filtering to one measure gives one
# row per scenario: `pct_change` is usually the readable one, since the absolute
# changes in `prob_connectedness` are very small numbers.
wren_scenarios |>
  dplyr::filter(measure == "pct_change") |>
  dplyr::select(
    scenario_name,
    n_patches,
    effective_mesh_ha,
    prob_connectedness
  )

# --- Comparison from objects you already have --------------------------------
# If the connectivity objects are already built, `compare_scenarios()` skips
# the spatial pipeline entirely. This is the entry point the shiny app uses,
# since it has already run `habitat_connectivity()` on each uploaded layer.
wren_connectivity_habitat_scenario <- habitat_connectivity(
  habitat = wren_habitat_scenario,
  barrier = wren_barrier,
  species = "Superb Fairy Wren",
  interpatch_distance = 200
)

compare_scenarios(
  baseline = wren_connectivity_baseline,
  scenarios = list(
    "Bentley Project" = wren_connectivity_habitat_scenario,
    "Barrier upgrade" = wren_connectivity_scenario
  )
)
