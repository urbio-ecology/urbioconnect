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

# plot_connectivity draws a comparison's baseline once, beside each scenario

    Code
      levels(drawn$series)
    Output
      [1] "Baseline"        "Bentley Project" "Barrier upgrade"

# plot_connectivity names an unnamed scenario

    Code
      levels(drawn$series)
    Output
      [1] "Baseline" "Scenario"

# plot_connectivity refuses scenarios it can't tell apart

    Code
      plot_connectivity(compare_scenarios(baseline, list(Baseline = scenario)))
    Condition
      Error in `plot_connectivity()`:
      ! A scenario can't be called "Baseline".
      i The plot draws the baseline under that name. Rename the scenario in scenario_name.

---

    Code
      plot_connectivity(compare_scenarios(baseline, rlang::set_names(rep(list(
        scenario), 6), LETTERS[1:6])))
    Condition
      Error in `plot_connectivity()`:
      ! Can only plot up to 5 scenarios at once, not 6.
      i Plot fewer at a time, for example with `dplyr::filter(x, scenario_name %in% c(...))`.

