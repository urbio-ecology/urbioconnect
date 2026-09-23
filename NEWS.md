# urbioconnect (development version)

* urbioconnect now requires terra >= 1.8-70. Earlier versions of `terra::identical()` ignore NA cells, so a scenario that only moved NA cells would compare as unchanged. (#140)
* Use GPL (>= 3) License.
* drop `terra_` prefix and move `rast_` functions into `scratch` where we test the LOO method. * Add `sf_` prefix to vector based approaches.
* Add datasets and dataset loading function
* Add legend to habitat buffer barrier plot - [#66](https://github.com/urbio-ecology/urbioconnect/issues/66)
* Resolve internal issue where raster might not be exactly aligned, add internal function `align_to()` in  `drop_habitat_under_barrier()`, `fragment_habitat()`, and `assign_patches_to_fragments()`.
* update `effective_mesh_size()` and `connectivity_probability()` to go from area_squared --> area_baseline. #128. This will help facilitate #124.
* `habitat_connectivity()`, `habitat_connectivity_full()`, and `sf_habitat_connectivity()` now take either `interpatch_distance` or `buffer_radius` (supply exactly one). The lower-level `habitat_buffer()` and `sf_habitat_buffer()` take `buffer_radius` directly. (#131)

* `habitat_buffer()` now warns when the buffer radius is too fine for the raster resolution (smaller than one cell, or not a clean multiple of it) and returns the habitat unchanged instead of erroring. (#131)

* New vignette `vignette("interpatch-distance-and-resolution")` on how interpatch distance, buffer radius, and raster resolution interact.

* Fix the shiny app's interpatch-distance input, which was read under the wrong id. (#131)

* Add "patch_size" class to `habitat_connectivity()` function, to pave the way for attaching useful metadata to these data. (#133).
* Add `patch_size` S3 class:
    - add pc_* accessor functions to get: interpatch_distance, patches, res, species.
    - Extend `patch_size` onto tibble
    - Add various checking functions to ensure you can compare the same species, and metrics together.
    - change `area` parameter for summarise/compare_connectivity to be `connectivity`
    - remove use of arguments, `target_resolution` and  `aggregation_factor` from many functions as it is only really relevant to the spatial processing, and we really only care about the resolution at the end of the day

* `habitat_connectivity()` now returns a one-row `connectivity`-class landscape summary (`n_patches`, `effective_mesh_ha`, `prob_connectedness`, `patch_area_mean`, `patch_area_total_ha`, ...) instead of the raw per-patch table. The per-patch areas travel with it in a `patch_size` list-column, retrievable with the new `patch_sizes()` accessor. `sf_habitat_connectivity()` still returns the per-patch table directly for now. (#141)
* Rename the per-patch class and constructor `patch_size()` -> `patch_size_tbl()` (and internal `new_patch_size()` -> `new_patch_size_tbl()`), freeing up the `patch_sizes` name for the new accessor above. (#138)
* New `habitat_connectivity_comparison()` compares a scenario against a baseline, for one or more interpatch distances (or buffer radii). Only one of habitat or barrier may differ from the baseline, so any change can be attributed to that layer. It errors if both differ, and warns if neither does. (#140)
* New example data `example_wren_habitat_scenario()`, a habitat scenario to pair with `example_wren_habitat()`. (#140)
* `summarise_connectivity()` and `habitat_connectivity()` now return metrics at full precision. `prob_connectedness` was rounded to 6 decimal places, which was coarse enough to hide the small changes a scenario produces. (#140)
* Argument checks use call and arg to name the function and argument that failed, and that they are called in.
* `compare_connectivity()` gains a `scenario_name` argument: an optional label, e.g. "Scenario A", that appears as the first column on every row. It is `NA` when not supplied, so labelled and unlabelled comparisons stack. (#35)
* New `compare_scenarios()` compares several scenarios against one baseline, taking a named list of `connectivity` objects where the names become the labels, and returning four rows per scenario. (#35)
* `habitat_connectivity_comparison()` gains `scenario_name`, passed through to `compare_connectivity()`. (#35)
* New `habitat_connectivity_scenarios()` compares several scenarios against one baseline starting from layers, taking named lists of habitat and barrier scenario layers. A scenario changes exactly one layer, and the baseline is computed once per distance and shared by every scenario. (#35)
* `summarise_connectivity()`'s default method now stores a `patch_size_tbl` in `patch_size`, the same as its `patch_size_tbl` method, so `compare_connectivity()` works on a `connectivity` object built from a plain vector of areas. (#35)

## Breaking changes

* `interpatch_distance` is now the full edge-to-edge distance below which two patches count as connected. It is halved internally to the buffer radius, so connectivity results differ from previous versions; reproduce old output by passing `buffer_radius =` the old value. (#131)
* `habitat_connectivity()` return type changed from a per-patch `patch_size_tbl` to a one-row `connectivity` summary. Code relying on per-patch columns (e.g. `habitat_connectivity(...)$area`) should instead use `patch_sizes(habitat_connectivity(...))[[1]]`. (#141)
* `compare_connectivity()` is now `compare_connectivity(scenario, baseline)`. It takes two one-row `connectivity` objects, such as the output of `habitat_connectivity()` or `summarise_connectivity()`, and returns four rows: `baseline`, `scenario`, `change` (scenario minus baseline) and `pct_change`. It is no longer an S3 generic, and its `patch_size_tbl` and default methods are gone. (#140)
* `summarise_connectivity()` no longer takes `connectivity_baseline`. Use `compare_connectivity()` to compare against a baseline instead. (#140)
 
# urbioconnect 0.1.0

* Make a NEWS file to monitor changes.
