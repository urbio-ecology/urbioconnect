# urbioconnect (development version)

* The shiny app gains a Reports card, with buttons for the HTML report, the PDF report, and both as a zip. The two report buttons existed but had no handlers, so they did nothing. Without the Quarto command line tool the three are disabled and the card says where to get it; every other download still works. (#61, #62)
* Warnings about a distance that the raster resolution can't represent now talk in interpatch distances, matching the argument you supplied.
* Functions taking a `dir` to fill create it if it doesn't exist; functions taking a `path` to one file error if that file's directory doesn't, as `ggplot2::ggsave()` and `readr::write_csv()` do. `generate_connectivity_report()` therefore no longer creates its output directory, which the old `output_dir` argument did.
* New `connectivity_file_stem()` gives the species-and-date name every download takes, so a report, a zip and the folder inside that zip agree.
* New `generate_connectivity_report()` renders one document holding the maps, tables and summary for an analysis. The format comes from the file extension, as it does for `ggplot2::ggsave()`: `generate_connectivity_report(x, "report.pdf")` writes a PDF, `"report.html"` an HTML file, and any other single-file format Quarto can write, such as `.docx`, also works. A `.pdf` goes through Typst, so no LaTeX is needed, and the figures are drawn from the data rather than embedded as images. Needs the Quarto command line tool. (#54, #61)
* `gg_barrier_habitat_interpatch_dist()` and `plot_barrier_habitat_interpatch_dist()` now default `col_barrier`, `col_interpatch_dist` and `col_habitat` to the package palette, so the app, the downloads and the report can't drift apart. (#54)
* `habitat_connectivity()`, `habitat_connectivity_full()`, `sf_habitat_connectivity()`, `habitat_connectivity_comparison()`, `habitat_connectivity_scenarios()` and `connectivity_report_data()` now take `interpatch_distance` only. The buffer radius is half the interpatch distance, so offering both was two ways to say the same thing; `habitat_buffer()` and `sf_habitat_buffer()` still take `buffer_radius`, since that is the operation they perform.
* `plot_barrier_habitat_interpatch_dist()` now saves at the shared figure size rather than whatever size the last graphics device happened to be, and slugifies the species in the file name, so a species with a space no longer produces a file name with one. (#54)
* New `quarto_available()` says whether the Quarto command line tool is installed, which is what the reports need and nothing else does. (#61)
* New `urbio_figure_size()` gives the figure width, height and resolution the downloadable PNGs and the report share. (#54)
* `write_connectivity_assets()` and `zip_connectivity_assets()` gain a `reports` argument, and include the HTML and PDF reports by default. It defaults to `quarto_available()`: without Quarto the maps, tables and GIS layers are still written and a message says the reports were skipped, so a missing Quarto costs the reports rather than the whole download. (#61, #62)
* New `write_connectivity_report()` and `render_connectivity_report()` split report rendering into its two steps, so the Quarto source can be kept and changed rather than thrown away. `write_connectivity_report()` writes the document and the analysis beside it, and the pair renders on its own with the Render button or `quarto::quarto_render()`, giving the same figures the package does. `generate_connectivity_report()` is now the two of them in one call. (#61)
* New `write_report_data()` and `read_report_data()` save a `connectivity_report_data()` to a file and read it back, packing the rasters so they survive the trip. This is how an analysis reaches the separate R session the report renders in. (#54)
* New `zip_connectivity_reports()` archives just the two reports, for someone who wants the write-up without the GIS layers. (#62)

* The shiny app gains a "Download everything" button, returning one archive of every map, table and GIS layer, and its analysis now builds a single `connectivity_report_data()` rather than assembling the pieces itself. (#153)
* New `connectivity_report_data()` holds everything one analysis produces: the summary for every interpatch distance, plus the buffered habitat and patch-ID raster each distance produced. (#153)
* New `write_connectivity_assets()` writes the downloadable assets - maps, tables, and patch polygons as GeoPackage and shapefile - in folders by interpatch distance, with a README describing each file and the run that produced it. (#153)
* New `zip_connectivity_assets()` archives those assets under a folder named for the species and date. (#153)
* New `urbio_colours()` and `format_resolution()`: the map palette and the raster resolution formatting, so the app and the downloads can't drift apart. (#153)
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

* `buffer_radius` is gone from every function above `habitat_buffer()`. Code passing `buffer_radius = r` should pass `interpatch_distance = 2 * r`.

* `interpatch_distance` is now the full edge-to-edge distance below which two patches count as connected. It is halved internally to the buffer radius, so connectivity results differ from previous versions; reproduce old output by passing `buffer_radius =` the old value. (#131)
* `habitat_connectivity()` return type changed from a per-patch `patch_size_tbl` to a one-row `connectivity` summary. Code relying on per-patch columns (e.g. `habitat_connectivity(...)$area`) should instead use `patch_sizes(habitat_connectivity(...))[[1]]`. (#141)
* `compare_connectivity()` is now `compare_connectivity(scenario, baseline)`. It takes two one-row `connectivity` objects, such as the output of `habitat_connectivity()` or `summarise_connectivity()`, and returns four rows: `baseline`, `scenario`, `change` (scenario minus baseline) and `pct_change`. It is no longer an S3 generic, and its `patch_size_tbl` and default methods are gone. (#140)
* `summarise_connectivity()` no longer takes `connectivity_baseline`. Use `compare_connectivity()` to compare against a baseline instead. (#140)
 
# urbioconnect 0.1.0

* Make a NEWS file to monitor changes.
