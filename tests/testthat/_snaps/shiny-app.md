# the app's downloads produce files with content

    Code
      names(summary_csv)
    Output
      [1] "species"             "interpatch_distance" "n_patches"          
      [4] "effective_mesh_ha"   "prob_connectedness"  "patch_area_mean"    
      [7] "patch_area_total_ha" "data_resolution"    

# a scenario that can't match the baseline says so by name

    Code
      check_scenario_choice()
    Condition
      Error in `check_scenario_choice()`:
      ! The "knox_barrier" scenario doesn't go with these layers.
      x A supplied scenario belongs to the example dataset it was drawn on.
      i Choose that dataset under Example data, or Upload my own scenario covering your own layers.

---

    Code
      check_scenario_choice()
    Condition
      Error in `check_scenario_choice()`:
      ! The "knox_barrier" scenario doesn't go with these layers.
      x A supplied scenario belongs to the example dataset it was drawn on.
      i Choose that dataset under Example data, or Upload my own scenario covering your own layers.

---

    Code
      check_scenario_choice()
    Condition
      Error in `check_scenario_choice()`:
      ! No scenario file chosen.
      i Upload one under Scenario Layer, or pick one of the supplied scenarios, or set it back to None.

