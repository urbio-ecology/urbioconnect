# Changelog

## urbioconnect (development version)

- The shiny app gains a Reports card, with buttons for the HTML report,
  the PDF report, and both as a zip. The two report buttons existed but
  had no handlers, so they did nothing. Without the Quarto command line
  tool the three are disabled and the card says where to get it; every
  other download still works.
  ([\#61](https://github.com/urbio-ecology/urbioconnect/issues/61),
  [\#62](https://github.com/urbio-ecology/urbioconnect/issues/62))

- Warnings about a distance that the raster resolution can’t represent
  now talk in interpatch distances, matching the argument you supplied.

- Functions taking a `dir` to fill create it if it doesn’t exist;
  functions taking a `path` to one file error if that file’s directory
  doesn’t, as
  [`ggplot2::ggsave()`](https://ggplot2.tidyverse.org/reference/ggsave.html)
  and
  [`readr::write_csv()`](https://readr.tidyverse.org/reference/write_delim.html)
  do.
  [`generate_connectivity_report()`](https://urbio-ecology.github.io/urbioconnect/reference/generate_connectivity_report.md)
  therefore no longer creates its output directory, which the old
  `output_dir` argument did.

- New
  [`connectivity_file_stem()`](https://urbio-ecology.github.io/urbioconnect/reference/connectivity_file_stem.md)
  gives the species-and-date name every download takes, so a report, a
  zip and the folder inside that zip agree.

- New
  [`generate_connectivity_report()`](https://urbio-ecology.github.io/urbioconnect/reference/generate_connectivity_report.md)
  renders one document holding the maps, tables and summary for an
  analysis. The format comes from the file extension, as it does for
  [`ggplot2::ggsave()`](https://ggplot2.tidyverse.org/reference/ggsave.html):
  `generate_connectivity_report(x, "report.pdf")` writes a PDF,
  `"report.html"` an HTML file, and any other single-file format Quarto
  can write, such as `.docx`, also works. A `.pdf` goes through Typst,
  so no LaTeX is needed, and the figures are drawn from the data rather
  than embedded as images. Needs the Quarto command line tool.
  ([\#54](https://github.com/urbio-ecology/urbioconnect/issues/54),
  [\#61](https://github.com/urbio-ecology/urbioconnect/issues/61))

- [`gg_barrier_habitat_interpatch_dist()`](https://urbio-ecology.github.io/urbioconnect/reference/gg_barrier_habitat_interpatch_dist.md)
  and
  [`plot_barrier_habitat_interpatch_dist()`](https://urbio-ecology.github.io/urbioconnect/reference/plot_barrier_habitat_interpatch_dist.md)
  now default `col_barrier`, `col_interpatch_dist` and `col_habitat` to
  the package palette, so the app, the downloads and the report can’t
  drift apart.
  ([\#54](https://github.com/urbio-ecology/urbioconnect/issues/54))

- [`habitat_connectivity()`](https://urbio-ecology.github.io/urbioconnect/reference/habitat_connectivity.md),
  [`habitat_connectivity_full()`](https://urbio-ecology.github.io/urbioconnect/reference/habitat_connectivity_full.md),
  [`sf_habitat_connectivity()`](https://urbio-ecology.github.io/urbioconnect/reference/sf_habitat_connectivity.md),
  [`habitat_connectivity_comparison()`](https://urbio-ecology.github.io/urbioconnect/reference/habitat_connectivity_comparison.md),
  [`habitat_connectivity_scenarios()`](https://urbio-ecology.github.io/urbioconnect/reference/habitat_connectivity_scenarios.md)
  and
  [`connectivity_report_data()`](https://urbio-ecology.github.io/urbioconnect/reference/connectivity_report_data.md)
  now take `interpatch_distance` only. The buffer radius is half the
  interpatch distance, so offering both was two ways to say the same
  thing;
  [`habitat_buffer()`](https://urbio-ecology.github.io/urbioconnect/reference/habitat_buffer.md)
  and
  [`sf_habitat_buffer()`](https://urbio-ecology.github.io/urbioconnect/reference/sf_habitat_buffer.md)
  still take `buffer_radius`, since that is the operation they perform.

- [`plot_barrier_habitat_interpatch_dist()`](https://urbio-ecology.github.io/urbioconnect/reference/plot_barrier_habitat_interpatch_dist.md)
  now saves at the shared figure size rather than whatever size the last
  graphics device happened to be, and slugifies the species in the file
  name, so a species with a space no longer produces a file name with
  one. ([\#54](https://github.com/urbio-ecology/urbioconnect/issues/54))

- New
  [`quarto_available()`](https://urbio-ecology.github.io/urbioconnect/reference/quarto_available.md)
  says whether the Quarto command line tool is installed, which is what
  the reports need and nothing else does.
  ([\#61](https://github.com/urbio-ecology/urbioconnect/issues/61))

- New
  [`urbio_figure_size()`](https://urbio-ecology.github.io/urbioconnect/reference/urbio_figure_size.md)
  gives the figure width, height and resolution the downloadable PNGs
  and the report share.
  ([\#54](https://github.com/urbio-ecology/urbioconnect/issues/54))

- [`write_connectivity_assets()`](https://urbio-ecology.github.io/urbioconnect/reference/write_connectivity_assets.md)
  and
  [`zip_connectivity_assets()`](https://urbio-ecology.github.io/urbioconnect/reference/zip_connectivity_assets.md)
  gain a `reports` argument, and include the HTML and PDF reports by
  default. It defaults to
  [`quarto_available()`](https://urbio-ecology.github.io/urbioconnect/reference/quarto_available.md):
  without Quarto the maps, tables and GIS layers are still written and a
  message says the reports were skipped, so a missing Quarto costs the
  reports rather than the whole download.
  ([\#61](https://github.com/urbio-ecology/urbioconnect/issues/61),
  [\#62](https://github.com/urbio-ecology/urbioconnect/issues/62))

- New
  [`write_connectivity_report()`](https://urbio-ecology.github.io/urbioconnect/reference/write_connectivity_report.md)
  and
  [`render_connectivity_report()`](https://urbio-ecology.github.io/urbioconnect/reference/render_connectivity_report.md)
  split report rendering into its two steps, so the Quarto source can be
  kept and changed rather than thrown away.
  [`write_connectivity_report()`](https://urbio-ecology.github.io/urbioconnect/reference/write_connectivity_report.md)
  writes the document and the analysis beside it, and the pair renders
  on its own with the Render button or
  [`quarto::quarto_render()`](https://quarto-dev.github.io/quarto-r/reference/quarto_render.html),
  giving the same figures the package does.
  [`generate_connectivity_report()`](https://urbio-ecology.github.io/urbioconnect/reference/generate_connectivity_report.md)
  is now the two of them in one call.
  ([\#61](https://github.com/urbio-ecology/urbioconnect/issues/61))

- New
  [`write_report_data()`](https://urbio-ecology.github.io/urbioconnect/reference/write_report_data.md)
  and
  [`read_report_data()`](https://urbio-ecology.github.io/urbioconnect/reference/write_report_data.md)
  save a
  [`connectivity_report_data()`](https://urbio-ecology.github.io/urbioconnect/reference/connectivity_report_data.md)
  to a file and read it back, packing the rasters so they survive the
  trip. This is how an analysis reaches the separate R session the
  report renders in.
  ([\#54](https://github.com/urbio-ecology/urbioconnect/issues/54))

- New
  [`zip_connectivity_reports()`](https://urbio-ecology.github.io/urbioconnect/reference/zip_connectivity_reports.md)
  archives just the two reports, for someone who wants the write-up
  without the GIS layers.
  ([\#62](https://github.com/urbio-ecology/urbioconnect/issues/62))

- The shiny app gains a “Download everything” button, returning one
  archive of every map, table and GIS layer, and its analysis now builds
  a single
  [`connectivity_report_data()`](https://urbio-ecology.github.io/urbioconnect/reference/connectivity_report_data.md)
  rather than assembling the pieces itself.
  ([\#153](https://github.com/urbio-ecology/urbioconnect/issues/153))

- New
  [`connectivity_report_data()`](https://urbio-ecology.github.io/urbioconnect/reference/connectivity_report_data.md)
  holds everything one analysis produces: the summary for every
  interpatch distance, plus the buffered habitat and patch-ID raster
  each distance produced.
  ([\#153](https://github.com/urbio-ecology/urbioconnect/issues/153))

- New
  [`write_connectivity_assets()`](https://urbio-ecology.github.io/urbioconnect/reference/write_connectivity_assets.md)
  writes the downloadable assets - maps, tables, and patch polygons as
  GeoPackage and shapefile - in folders by interpatch distance, with a
  README describing each file and the run that produced it.
  ([\#153](https://github.com/urbio-ecology/urbioconnect/issues/153))

- New
  [`zip_connectivity_assets()`](https://urbio-ecology.github.io/urbioconnect/reference/zip_connectivity_assets.md)
  archives those assets under a folder named for the species and date.
  ([\#153](https://github.com/urbio-ecology/urbioconnect/issues/153))

- New
  [`urbio_colours()`](https://urbio-ecology.github.io/urbioconnect/reference/urbio_colours.md)
  and
  [`format_resolution()`](https://urbio-ecology.github.io/urbioconnect/reference/format_resolution.md):
  the map palette and the raster resolution formatting, so the app and
  the downloads can’t drift apart.
  ([\#153](https://github.com/urbio-ecology/urbioconnect/issues/153))

- urbioconnect now requires terra \>= 1.8-70. Earlier versions of
  [`terra::identical()`](https://rspatial.github.io/terra/reference/identical.html)
  ignore NA cells, so a scenario that only moved NA cells would compare
  as unchanged.
  ([\#140](https://github.com/urbio-ecology/urbioconnect/issues/140))

- Use GPL (\>= 3) License.

- drop `terra_` prefix and move `rast_` functions into `scratch` where
  we test the LOO method. \* Add `sf_` prefix to vector based
  approaches.

- Add datasets and dataset loading function

- Add legend to habitat buffer barrier plot -
  [\#66](https://github.com/urbio-ecology/urbioconnect/issues/66)

- Resolve internal issue where raster might not be exactly aligned, add
  internal function `align_to()` in
  [`drop_habitat_under_barrier()`](https://urbio-ecology.github.io/urbioconnect/reference/drop_habitat_under_barrier.md),
  [`fragment_habitat()`](https://urbio-ecology.github.io/urbioconnect/reference/fragment_habitat.md),
  and
  [`assign_patches_to_fragments()`](https://urbio-ecology.github.io/urbioconnect/reference/assign_patches_to_fragments.md).

- update
  [`effective_mesh_size()`](https://urbio-ecology.github.io/urbioconnect/reference/effective_mesh_size.md)
  and
  [`connectivity_probability()`](https://urbio-ecology.github.io/urbioconnect/reference/connectivity_probability.md)
  to go from area_squared –\> area_baseline.
  [\#128](https://github.com/urbio-ecology/urbioconnect/issues/128).
  This will help facilitate
  [\#124](https://github.com/urbio-ecology/urbioconnect/issues/124).

- [`habitat_connectivity()`](https://urbio-ecology.github.io/urbioconnect/reference/habitat_connectivity.md),
  [`habitat_connectivity_full()`](https://urbio-ecology.github.io/urbioconnect/reference/habitat_connectivity_full.md),
  and
  [`sf_habitat_connectivity()`](https://urbio-ecology.github.io/urbioconnect/reference/sf_habitat_connectivity.md)
  now take either `interpatch_distance` or `buffer_radius` (supply
  exactly one). The lower-level
  [`habitat_buffer()`](https://urbio-ecology.github.io/urbioconnect/reference/habitat_buffer.md)
  and
  [`sf_habitat_buffer()`](https://urbio-ecology.github.io/urbioconnect/reference/sf_habitat_buffer.md)
  take `buffer_radius` directly.
  ([\#131](https://github.com/urbio-ecology/urbioconnect/issues/131))

- [`habitat_buffer()`](https://urbio-ecology.github.io/urbioconnect/reference/habitat_buffer.md)
  now warns when the buffer radius is too fine for the raster resolution
  (smaller than one cell, or not a clean multiple of it) and returns the
  habitat unchanged instead of erroring.
  ([\#131](https://github.com/urbio-ecology/urbioconnect/issues/131))

- New vignette
  [`vignette("interpatch-distance-and-resolution")`](https://urbio-ecology.github.io/urbioconnect/articles/interpatch-distance-and-resolution.md)
  on how interpatch distance, buffer radius, and raster resolution
  interact.

- Fix the shiny app’s interpatch-distance input, which was read under
  the wrong id.
  ([\#131](https://github.com/urbio-ecology/urbioconnect/issues/131))

- Add “patch_size” class to
  [`habitat_connectivity()`](https://urbio-ecology.github.io/urbioconnect/reference/habitat_connectivity.md)
  function, to pave the way for attaching useful metadata to these data.
  ([\#133](https://github.com/urbio-ecology/urbioconnect/issues/133)).

- Add `patch_size` S3 class:

  - add pc\_\* accessor functions to get: interpatch_distance, patches,
    res, species.
  - Extend `patch_size` onto tibble
  - Add various checking functions to ensure you can compare the same
    species, and metrics together.
  - change `area` parameter for summarise/compare_connectivity to be
    `connectivity`
  - remove use of arguments, `target_resolution` and
    `aggregation_factor` from many functions as it is only really
    relevant to the spatial processing, and we really only care about
    the resolution at the end of the day

- [`habitat_connectivity()`](https://urbio-ecology.github.io/urbioconnect/reference/habitat_connectivity.md)
  now returns a one-row `connectivity`-class landscape summary
  (`n_patches`, `effective_mesh_ha`, `prob_connectedness`,
  `patch_area_mean`, `patch_area_total_ha`, …) instead of the raw
  per-patch table. The per-patch areas travel with it in a `patch_size`
  list-column, retrievable with the new
  [`patch_sizes()`](https://urbio-ecology.github.io/urbioconnect/reference/patch_sizes.md)
  accessor.
  [`sf_habitat_connectivity()`](https://urbio-ecology.github.io/urbioconnect/reference/sf_habitat_connectivity.md)
  still returns the per-patch table directly for now.
  ([\#141](https://github.com/urbio-ecology/urbioconnect/issues/141))

- Rename the per-patch class and constructor `patch_size()` -\>
  [`patch_size_tbl()`](https://urbio-ecology.github.io/urbioconnect/reference/new_patch_size_tbl.md)
  (and internal `new_patch_size()` -\>
  [`new_patch_size_tbl()`](https://urbio-ecology.github.io/urbioconnect/reference/new_patch_size_tbl.md)),
  freeing up the `patch_sizes` name for the new accessor above.
  ([\#138](https://github.com/urbio-ecology/urbioconnect/issues/138))

- New
  [`habitat_connectivity_comparison()`](https://urbio-ecology.github.io/urbioconnect/reference/habitat_connectivity_comparison.md)
  compares a scenario against a baseline, for one or more interpatch
  distances (or buffer radii). Only one of habitat or barrier may differ
  from the baseline, so any change can be attributed to that layer. It
  errors if both differ, and warns if neither does.
  ([\#140](https://github.com/urbio-ecology/urbioconnect/issues/140))

- New example data
  [`example_wren_habitat_scenario()`](https://urbio-ecology.github.io/urbioconnect/reference/example-wren-data.md),
  a habitat scenario to pair with
  [`example_wren_habitat()`](https://urbio-ecology.github.io/urbioconnect/reference/example-wren-data.md).
  ([\#140](https://github.com/urbio-ecology/urbioconnect/issues/140))

- [`summarise_connectivity()`](https://urbio-ecology.github.io/urbioconnect/reference/summarise-connectivity.md)
  and
  [`habitat_connectivity()`](https://urbio-ecology.github.io/urbioconnect/reference/habitat_connectivity.md)
  now return metrics at full precision. `prob_connectedness` was rounded
  to 6 decimal places, which was coarse enough to hide the small changes
  a scenario produces.
  ([\#140](https://github.com/urbio-ecology/urbioconnect/issues/140))

- Argument checks use call and arg to name the function and argument
  that failed, and that they are called in.

- [`compare_connectivity()`](https://urbio-ecology.github.io/urbioconnect/reference/compare_connectivity.md)
  gains a `scenario_name` argument: an optional label, e.g. “Scenario
  A”, that appears as the first column on every row. It is `NA` when not
  supplied, so labelled and unlabelled comparisons stack.
  ([\#35](https://github.com/urbio-ecology/urbioconnect/issues/35))

- New
  [`compare_scenarios()`](https://urbio-ecology.github.io/urbioconnect/reference/compare_scenarios.md)
  compares several scenarios against one baseline, taking a named list
  of `connectivity` objects where the names become the labels, and
  returning four rows per scenario.
  ([\#35](https://github.com/urbio-ecology/urbioconnect/issues/35))

- [`habitat_connectivity_comparison()`](https://urbio-ecology.github.io/urbioconnect/reference/habitat_connectivity_comparison.md)
  gains `scenario_name`, passed through to
  [`compare_connectivity()`](https://urbio-ecology.github.io/urbioconnect/reference/compare_connectivity.md).
  ([\#35](https://github.com/urbio-ecology/urbioconnect/issues/35))

- New
  [`habitat_connectivity_scenarios()`](https://urbio-ecology.github.io/urbioconnect/reference/habitat_connectivity_scenarios.md)
  compares several scenarios against one baseline starting from layers,
  taking named lists of habitat and barrier scenario layers. A scenario
  changes exactly one layer, and the baseline is computed once per
  distance and shared by every scenario.
  ([\#35](https://github.com/urbio-ecology/urbioconnect/issues/35))

- [`summarise_connectivity()`](https://urbio-ecology.github.io/urbioconnect/reference/summarise-connectivity.md)’s
  default method now stores a `patch_size_tbl` in `patch_size`, the same
  as its `patch_size_tbl` method, so
  [`compare_connectivity()`](https://urbio-ecology.github.io/urbioconnect/reference/compare_connectivity.md)
  works on a `connectivity` object built from a plain vector of areas.
  ([\#35](https://github.com/urbio-ecology/urbioconnect/issues/35))

### Breaking changes

- `buffer_radius` is gone from every function above
  [`habitat_buffer()`](https://urbio-ecology.github.io/urbioconnect/reference/habitat_buffer.md).
  Code passing `buffer_radius = r` should pass
  `interpatch_distance = 2 * r`.

- `interpatch_distance` is now the full edge-to-edge distance below
  which two patches count as connected. It is halved internally to the
  buffer radius, so connectivity results differ from previous versions;
  reproduce old output by passing `buffer_radius =` the old value.
  ([\#131](https://github.com/urbio-ecology/urbioconnect/issues/131))

- [`habitat_connectivity()`](https://urbio-ecology.github.io/urbioconnect/reference/habitat_connectivity.md)
  return type changed from a per-patch `patch_size_tbl` to a one-row
  `connectivity` summary. Code relying on per-patch columns
  (e.g. `habitat_connectivity(...)$area`) should instead use
  `patch_sizes(habitat_connectivity(...))[[1]]`.
  ([\#141](https://github.com/urbio-ecology/urbioconnect/issues/141))

- [`compare_connectivity()`](https://urbio-ecology.github.io/urbioconnect/reference/compare_connectivity.md)
  is now `compare_connectivity(scenario, baseline)`. It takes two
  one-row `connectivity` objects, such as the output of
  [`habitat_connectivity()`](https://urbio-ecology.github.io/urbioconnect/reference/habitat_connectivity.md)
  or
  [`summarise_connectivity()`](https://urbio-ecology.github.io/urbioconnect/reference/summarise-connectivity.md),
  and returns four rows: `baseline`, `scenario`, `change` (scenario
  minus baseline) and `pct_change`. It is no longer an S3 generic, and
  its `patch_size_tbl` and default methods are gone.
  ([\#140](https://github.com/urbio-ecology/urbioconnect/issues/140))

- [`summarise_connectivity()`](https://urbio-ecology.github.io/urbioconnect/reference/summarise-connectivity.md)
  no longer takes `connectivity_baseline`. Use
  [`compare_connectivity()`](https://urbio-ecology.github.io/urbioconnect/reference/compare_connectivity.md)
  to compare against a baseline instead.
  ([\#140](https://github.com/urbio-ecology/urbioconnect/issues/140))

## urbioconnect 0.1.0

- Make a NEWS file to monitor changes.
