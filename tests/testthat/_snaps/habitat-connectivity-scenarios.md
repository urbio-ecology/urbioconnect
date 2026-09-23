# habitat_connectivity_scenarios() stacks habitat then barrier scenarios

    Code
      results
    Output
      # Connectivity comparison: baseline / scenario / change / pct_change
      # A tibble: 8 x 10
        scenario_name   measure    species      interpatch_distance n_patches
        <chr>           <chr>      <chr>                      <dbl>     <dbl>
      1 Bentley Project baseline   Test Species                  40       3  
      2 Bentley Project scenario   Test Species                  40       2  
      3 Bentley Project change     Test Species                  40      -1  
      4 Bentley Project pct_change Test Species                  40     -33.3
      5 Barrier upgrade baseline   Test Species                  40       3  
      6 Barrier upgrade scenario   Test Species                  40       3  
      7 Barrier upgrade change     Test Species                  40       0  
      8 Barrier upgrade pct_change Test Species                  40       0  
        effective_mesh_ha prob_connectedness patch_area_mean patch_area_total_ha
                    <dbl>              <dbl>           <dbl>               <dbl>
      1             0.915         0.0000367           8322.                2.50 
      2             0.743         0.0000297           9201.                1.84 
      3            -0.173        -0.00000691           879.               -0.657
      4           -18.9         -18.9                   10.6             -26.3  
      5             0.915         0.0000367           8322.                2.50 
      6             0.915         0.0000367           8322.                2.50 
      7             0             0                      0                 0    
      8             0             0                      0                 0    
        data_resolution
        <chr>          
      1 10x10          
      2 10x10          
      3 10x10          
      4 10x10          
      5 10x10          
      6 10x10          
      7 10x10          
      8 10x10          
      # change = scenario - baseline (positive = scenario is higher)
      # pct_change = 100 * change / baseline

# habitat_connectivity_scenarios() warns on a scenario matching baseline

    Code
      results <- habitat_connectivity_scenarios(habitat_baseline = layers$habitat,
      barrier_baseline = layers$barrier, species = "Test Species", habitat_scenarios = list(
        `No change` = layers$habitat), interpatch_distance = 40, verbose = FALSE)
    Condition
      Warning:
      Scenarios identical to the baseline: "No change".
      i Every change value will be zero for them.

# habitat_connectivity_scenarios() rejects a layer passed outside a list

    Code
      habitat_connectivity_scenarios(habitat_baseline = layers$habitat,
      barrier_baseline = layers$barrier, species = "Test Species", habitat_scenarios = layers$
        habitat_scenario, interpatch_distance = 40, verbose = FALSE)
    Condition
      Error in `habitat_connectivity_scenarios()`:
      ! `habitat_scenarios` must be a named list, one element per scenario.
      i You supplied: a <SpatRaster> object.
      i For a single scenario: `habitat_scenarios = list("name" = x)`.
    Code
      habitat_connectivity_scenarios(habitat_baseline = layers$habitat,
      barrier_baseline = layers$barrier, species = "Test Species", barrier_scenarios = layers$
        barrier_scenario, interpatch_distance = 40, verbose = FALSE)
    Condition
      Error in `habitat_connectivity_scenarios()`:
      ! `barrier_scenarios` must be a named list, one element per scenario.
      i You supplied: a <SpatRaster> object.
      i For a single scenario: `barrier_scenarios = list("name" = x)`.

# habitat_connectivity_scenarios() rejects missing or clashing names

    Code
      habitat_connectivity_scenarios(habitat_baseline = layers$habitat,
      barrier_baseline = layers$barrier, species = "Test Species",
      interpatch_distance = 40, verbose = FALSE)
    Condition
      Error in `habitat_connectivity_scenarios()`:
      ! Supply `habitat_scenarios`, `barrier_scenarios`, or both.
      i Each is a named list of layers, one element per scenario.
    Code
      habitat_connectivity_scenarios(habitat_baseline = layers$habitat,
      barrier_baseline = layers$barrier, species = "Test Species", habitat_scenarios = list(
        `Stage 2` = layers$habitat_scenario), barrier_scenarios = list(`Stage 2` = layers$
        barrier_scenario), interpatch_distance = 40, verbose = FALSE)
    Condition
      Error in `habitat_connectivity_scenarios()`:
      ! Scenario names must be unique across `habitat_scenarios` and `barrier_scenarios`.
      x Used in both: "Stage 2".
    Code
      habitat_connectivity_scenarios(habitat_baseline = layers$habitat,
      barrier_baseline = layers$barrier, species = "Test Species", habitat_scenarios = list(
        layers$habitat_scenario), interpatch_distance = 40, verbose = FALSE)
    Condition
      Error in `habitat_connectivity_scenarios()`:
      ! Every scenario in `habitat_scenarios` must be named.
      x No name at position 1.
      i Names become the scenario_name column.

