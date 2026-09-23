# compare_scenarios() stacks four labelled rows per scenario

    Code
      results
    Output
      # Connectivity comparison: baseline / scenario / change / pct_change
      # A tibble: 8 x 10
        scenario_name   measure    species             interpatch_distance n_patches
        <chr>           <chr>      <chr>                             <dbl>     <dbl>
      1 Bentley Project baseline   Blue-tongued Lizard                  50     73   
      2 Bentley Project scenario   Blue-tongued Lizard                  50     72   
      3 Bentley Project change     Blue-tongued Lizard                  50     -1   
      4 Bentley Project pct_change Blue-tongued Lizard                  50     -1.37
      5 Barrier upgrade baseline   Blue-tongued Lizard                  50     73   
      6 Barrier upgrade scenario   Blue-tongued Lizard                  50     68   
      7 Barrier upgrade change     Blue-tongued Lizard                  50     -5   
      8 Barrier upgrade pct_change Blue-tongued Lizard                  50     -6.85
        effective_mesh_ha prob_connectedness patch_area_mean patch_area_total_ha
                    <dbl>              <dbl>           <dbl>               <dbl>
      1         4.47                1.70e- 5         3600.               26.3   
      2         4.47                1.70e- 5         3648.               26.3   
      3        -0.0000113          -4.28e-11           47.6              -0.0172
      4        -0.000252           -2.52e- 4            1.32             -0.0654
      5         4.47                1.70e- 5         3600.               26.3   
      6         0.815               3.10e- 6         2343.               15.9   
      7        -3.66               -1.39e- 5        -1257.              -10.3   
      8       -81.8                -8.18e+ 1          -34.9             -39.4   
        data_resolution
        <chr>          
      1 2x2            
      2 2x2            
      3 2x2            
      4 2x2            
      5 2x2            
      6 2x2            
      7 2x2            
      8 2x2            
      # change = scenario - baseline (positive = scenario is higher)
      # pct_change = 100 * change / baseline

# compare_scenarios() rejects badly named scenarios

    Code
      compare_scenarios(baseline, list(scenario))
    Condition
      Error in `compare_scenarios()`:
      ! Every scenario in `scenarios` must be named.
      x No name at position 1.
      i Names become the scenario_name column.
    Code
      compare_scenarios(baseline, list(a = scenario, scenario))
    Condition
      Error in `compare_scenarios()`:
      ! Every scenario in `scenarios` must be named.
      x No name at position 2.
      i Names become the scenario_name column.
    Code
      compare_scenarios(baseline, list(a = scenario, a = scenario))
    Condition
      Error in `compare_scenarios()`:
      ! Scenario names in `scenarios` must be unique.
      x Duplicated: "a".
    Code
      compare_scenarios(baseline, list())
    Condition
      Error in `compare_scenarios()`:
      ! `scenarios` must contain at least one <connectivity> object.

# compare_scenarios() rejects scenarios that aren't connectivity

    Code
      compare_scenarios(baseline, list(`Bentley Project` = lizard_areas_connected$
      area))
    Condition
      Error in `compare_scenarios()`:
      ! Every scenario in `scenarios` must be a <connectivity> object.
      x Not connectivity: "Bentley Project".

# compare_scenarios() rejects a scenario that mismatches the baseline

    Code
      compare_scenarios(baseline, list(`Bentley Project` = other_species))
    Condition
      Error in `map2()`:
      i In index: 1.
      i With name: Bentley Project.
      Caused by error in `compare_connectivity()`:
      ! `scenario` and `baseline` must have the same resolution, species, and interpatch_distance.
      ! One or more of these do not match:
      resolution
      * scenario = "2"
      * baseline = "2x2"
      species
      * scenario = "Superb Fairy Wren"
      * baseline = "Blue-tongued Lizard"
      interpatch_distance
      * scenario = "10"
      * baseline = "50"

