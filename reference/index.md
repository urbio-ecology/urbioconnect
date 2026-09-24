# Package index

## Main functions

- [`habitat_connectivity()`](https://urbio-ecology.github.io/urbioconnect/reference/habitat_connectivity.md)
  : Calculate habitat connectivity using terra
- [`summarise_connectivity()`](https://urbio-ecology.github.io/urbioconnect/reference/summarise-connectivity.md)
  : Summarise connectivity metrics
- [`compare_connectivity()`](https://urbio-ecology.github.io/urbioconnect/reference/compare_connectivity.md)
  : Compare the connectivity of two scenarios
- [`compare_scenarios()`](https://urbio-ecology.github.io/urbioconnect/reference/compare_scenarios.md)
  : Compare several scenarios against one baseline
- [`habitat_connectivity_comparison()`](https://urbio-ecology.github.io/urbioconnect/reference/habitat_connectivity_comparison.md)
  : Compare habitat connectivity of a scenario against a baseline
- [`habitat_connectivity_scenarios()`](https://urbio-ecology.github.io/urbioconnect/reference/habitat_connectivity_scenarios.md)
  : Compare several scenarios against one baseline, starting from layers
- [`effective_mesh_size()`](https://urbio-ecology.github.io/urbioconnect/reference/effective_mesh_size.md)
  : Calculate effective mesh size
- [`connectivity_probability()`](https://urbio-ecology.github.io/urbioconnect/reference/connectivity_probability.md)
  : Calculate connectivity probability
- [`mean_patch_size()`](https://urbio-ecology.github.io/urbioconnect/reference/mean_patch_size.md)
  : Calculate mean patch size
- [`n_patches()`](https://urbio-ecology.github.io/urbioconnect/reference/n_patches.md)
  : Count number of habitat patches
- [`total_habitat_area()`](https://urbio-ecology.github.io/urbioconnect/reference/total_habitat_area.md)
  : Calculate total habitat area
- [`habitat_connectivity_full()`](https://urbio-ecology.github.io/urbioconnect/reference/habitat_connectivity_full.md)
  : Calculate habitat connectivity with visualization data

## Patch connectivity class

- [`patch_sizes()`](https://urbio-ecology.github.io/urbioconnect/reference/patch_sizes.md)
  :

  Extract the per-patch tables from a `connectivity` object

- [`pc_species()`](https://urbio-ecology.github.io/urbioconnect/reference/pc-getters.md)
  [`pc_patches()`](https://urbio-ecology.github.io/urbioconnect/reference/pc-getters.md)
  [`pc_res()`](https://urbio-ecology.github.io/urbioconnect/reference/pc-getters.md)
  [`pc_interpatch_distance()`](https://urbio-ecology.github.io/urbioconnect/reference/pc-getters.md)
  :

  Metadata from a `patch_size_tbl` object

- [`new_patch_size_tbl()`](https://urbio-ecology.github.io/urbioconnect/reference/new_patch_size_tbl.md)
  [`patch_size_tbl()`](https://urbio-ecology.github.io/urbioconnect/reference/new_patch_size_tbl.md)
  : A set of connected habitat patches

## Raster functions

- [`create_barrier_mask()`](https://urbio-ecology.github.io/urbioconnect/reference/create_barrier_mask.md)
  : Create barrier mask
- [`drop_habitat_under_barrier()`](https://urbio-ecology.github.io/urbioconnect/reference/drop_habitat_under_barrier.md)
  : Remove habitat under barriers
- [`habitat_buffer()`](https://urbio-ecology.github.io/urbioconnect/reference/habitat_buffer.md)
  : Buffer habitat raster
- [`fragment_habitat()`](https://urbio-ecology.github.io/urbioconnect/reference/fragment_habitat.md)
  : Fragment habitat
- [`assign_patches_to_fragments()`](https://urbio-ecology.github.io/urbioconnect/reference/assign_patches_to_fragments.md)
  : Assign patches to fragments
- [`add_patch_area()`](https://urbio-ecology.github.io/urbioconnect/reference/add_patch_area.md)
  : Add patch area layer
- [`aggregate_connected_patches()`](https://urbio-ecology.github.io/urbioconnect/reference/aggregate_connected_patches.md)
  : Aggregate connected patch areas

## Vector (shapefile) functions

- [`prepare_rasters()`](https://urbio-ecology.github.io/urbioconnect/reference/prepare_rasters.md)
  : Prepare habitat and barrier rasters
- [`read_geometry()`](https://urbio-ecology.github.io/urbioconnect/reference/read_geometry.md)
  : Read shapefile geometry
- [`sf_habitat_buffer()`](https://urbio-ecology.github.io/urbioconnect/reference/sf_habitat_buffer.md)
  : Buffer habitat by distance
- [`sf_fragment_habitat()`](https://urbio-ecology.github.io/urbioconnect/reference/sf_fragment_habitat.md)
  : Fragment habitat along barriers
- [`sf_drop_habitat_under_barrier()`](https://urbio-ecology.github.io/urbioconnect/reference/sf_drop_habitat_under_barrier.md)
  : Remove habitat underneath barriers
- [`sf_assign_patches_to_fragments()`](https://urbio-ecology.github.io/urbioconnect/reference/sf_assign_patches_to_fragments.md)
  : Assign habitat patches to fragment IDs
- [`sf_add_patch_area()`](https://urbio-ecology.github.io/urbioconnect/reference/sf_add_patch_area.md)
  : Add patch area column
- [`sf_aggregate_connected_patches()`](https://urbio-ecology.github.io/urbioconnect/reference/sf_aggregate_connected_patches.md)
  : Aggregate connected patch areas
- [`sf_habitat_connectivity()`](https://urbio-ecology.github.io/urbioconnect/reference/sf_habitat_connectivity.md)
  : Calculate habitat connectivity

## Visualisation

- [`gg_barrier_habitat_interpatch_dist()`](https://urbio-ecology.github.io/urbioconnect/reference/gg_barrier_habitat_interpatch_dist.md)
  : Plot barrier, habitat, and interpatch distance layers
- [`plot_barrier_habitat_interpatch_dist()`](https://urbio-ecology.github.io/urbioconnect/reference/plot_barrier_habitat_interpatch_dist.md)
  : Save barrier habitat interpatch distance plot
- [`plot_connectivity()`](https://urbio-ecology.github.io/urbioconnect/reference/plot_connectivity.md)
  : Plot connectivity metrics across interpatch distances
- [`plot_patches()`](https://urbio-ecology.github.io/urbioconnect/reference/plot_patches.md)
  : Plot connected habitat patches

## Data sources

- [`example_habitat()`](https://urbio-ecology.github.io/urbioconnect/reference/example-lizard-data.md)
  [`example_barrier_shp()`](https://urbio-ecology.github.io/urbioconnect/reference/example-lizard-data.md)
  [`example_barrier()`](https://urbio-ecology.github.io/urbioconnect/reference/example-lizard-data.md)
  : Lizard Habitat and Barrier Data from Melbourne.
- [`example_wren_habitat()`](https://urbio-ecology.github.io/urbioconnect/reference/example-wren-data.md)
  [`example_wren_habitat_scenario()`](https://urbio-ecology.github.io/urbioconnect/reference/example-wren-data.md)
  [`example_wren_barrier()`](https://urbio-ecology.github.io/urbioconnect/reference/example-wren-data.md)
  [`example_wren_barrier_scenario()`](https://urbio-ecology.github.io/urbioconnect/reference/example-wren-data.md)
  : Fair Wren Habitat, Barrier, and scenario Data from City of Knox.
- [`lizard_areas_connected`](https://urbio-ecology.github.io/urbioconnect/reference/lizard_areas_connected.md)
  : Connected habitat patch areas for Blue-tongued Lizard

## General

- [`clean()`](https://urbio-ecology.github.io/urbioconnect/reference/clean.md)
  : Clean any spatial data layer (shape file)
- [`empty_grid()`](https://urbio-ecology.github.io/urbioconnect/reference/empty_grid.md)
  : Create Empty terra raster grid
- [`generate_connectivity_report()`](https://urbio-ecology.github.io/urbioconnect/reference/generate_connectivity_report.md)
  : Generate Connectivity Report
- [`col2hex()`](https://urbio-ecology.github.io/urbioconnect/reference/col2hex.md)
  : Convert color name to hexadecimal

## Shiny app

- [`run_connectivity_app()`](https://urbio-ecology.github.io/urbioconnect/reference/run_connectivity_app.md)
  : Launch the Connectivity Shiny App
