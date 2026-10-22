# the app's downloads produce files with content

    Code
      names(summary_csv)
    Output
      [1] "species"             "interpatch_distance" "n_patches"          
      [4] "effective_mesh_ha"   "prob_connectedness"  "patch_area_mean"    
      [7] "patch_area_total_ha" "data_resolution"    

---

    Code
      settings_csv$setting
    Output
       [1] "species"               "interpatch_distance_m" "habitat_source"       
       [4] "barrier_source"        "data_resolution_m"     "target_resolution_m"  
       [7] "grid_resolution_m"     "grid_dimensions"       "crs"                  
      [10] "crs_code"              "scenario_kind"         "scenario_name"        
      [13] "run_time"              "urbioconnect_version"  "terra_version"        
      [16] "r_version"             "platform"             

# uploaded layers and an uploaded scenario reach the analysis

    Code
      names(connectivity_display(results$comparison)$data)
    Output
      [1] "Scenario"       "Distance (m)"   "Metric"         "Baseline"      
      [5] "Scenario value" "Change"         "% change"      

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
      i Upload one under Your scenario layer, or pick one of the supplied scenarios, or set it back to None.

# interpatch distances that aren't numbers are an error, not dropped

    Code
      interpatch_distances_parsed()
    Condition
      Error:
      ! Interpatch distances must be numbers, and "abc" isn't.

---

    Code
      interpatch_distances_parsed()
    Condition
      Error:
      ! Interpatch distances must be numbers, and "abc", "def" aren't.

---

    Code
      interpatch_distances_parsed()
    Condition
      Error:
      ! Interpatch distances must be positive numbers

---

    Code
      interpatch_distances_parsed()
    Condition
      Error:
      ! Please enter at least one valid interpatch distance

