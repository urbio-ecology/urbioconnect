# col2hex converts colour name to hex

    Code
      col2hex("forestgreen")
    Output
      [1] "#228B22"

---

    Code
      col2hex("blue")
    Output
      [1] "#0000FF"

# to_sentence converts snake_case to sentence case

    Code
      to_sentence("prob_connectedness")
    Output
      [1] "Prob connectedness"

---

    Code
      to_sentence(c("n_patches", "patch_area_mean"))
    Output
      [1] "N patches"       "Patch area mean"

# gg_layer rejects a layer it has no colours for

    Code
      gg_layer(example_habitat(), "interpatch")
    Condition
      Error in `gg_layer()`:
      ! `kind` must be one of "habitat" or "barrier", not "interpatch".

# plot_patches draws the barrier, and shades each patch's zone

    Code
      data.frame(inputs, barrier_only, with_zone)
    Output
        habitat barrier buffered barrier_only with_zone
      1       1       0        1      #E16A86   #E16A86
      2      NA       0        1         <NA>   #FFCAD3
      3      NA       1        1       grey55    grey55
      4      NA       0        1         <NA>      <NA>
      5      NA       1       NA       grey55    grey55
      6      NA       0        1         <NA>   #FFCE9A
      7       1       0        1      #C18500   #C18500
      8      NA       0        1         <NA>   #FFCE9A
      9      NA       0        1         <NA>   #FFCE9A

# plot_patches needs the barrier to draw the zone

    Code
      plot_patches(patch_id_raster, interpatch_dist, buffered = buffered)
    Condition
      Error in `plot_patches()`:
      ! `buffered` needs `barrier`, which cuts the buffer into zones.

# comparison_plot_data() has the baseline once, beside each scenario

    Code
      levels(drawn$series)
    Output
      [1] "Baseline"        "Bentley Project" "Barrier upgrade"

# comparison_plot_data() names an unnamed scenario

    Code
      levels(drawn$series)
    Output
      [1] "Baseline" "Scenario"

# plot_connectivity refuses scenarios it can't tell apart

    Code
      plot_connectivity(compare_scenarios(baseline, list(baseline = scenario)))
    Condition
      Error in `plot_connectivity()`:
      ! A scenario can't be called "baseline".
      i The plot draws the baseline under that name. Rename the scenario in scenario_name.

---

    Code
      plot_connectivity(compare_scenarios(baseline, rlang::set_names(rep(list(
        scenario), 6), LETTERS[1:6])))
    Condition
      Error in `plot_connectivity()`:
      ! Can only plot up to 5 scenarios at once, not 6.
      i Plot fewer at a time, for example with `dplyr::filter(x, scenario_name %in% c(...))`.

---

    Code
      plot_connectivity(dplyr::bind_rows(compare_connectivity(scenario, baseline),
      compare_connectivity(summarise_connectivity(lizard_areas_connected[-(1:5), ]),
      baseline)))
    Condition
      Error in `plot_connectivity()`:
      ! Can't draw "Scenario" as one bar per interpatch distance: more than one comparison gives a value at the same distance.
      i Give each scenario its own scenario_name, and compare every scenario against the same baseline.

