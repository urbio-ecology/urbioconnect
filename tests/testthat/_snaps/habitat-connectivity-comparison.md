# habitat_connectivity_comparison() scalar distance gives one block of 4 rows

    Code
      results
    Output
      # Connectivity comparison: baseline / scenario / change / pct_change
      # A tibble: 4 x 10
        scenario_name measure    species            interpatch_distance n_patches
        <chr>         <chr>      <chr>                            <dbl>     <dbl>
      1 <NA>          baseline   Blue Tongue Lizard                  40     81   
      2 <NA>          scenario   Blue Tongue Lizard                  40     85   
      3 <NA>          change     Blue Tongue Lizard                  40      4   
      4 <NA>          pct_change Blue Tongue Lizard                  40      4.94
        effective_mesh_ha prob_connectedness patch_area_mean patch_area_total_ha
                    <dbl>              <dbl>           <dbl>               <dbl>
      1              4.45         0.0000169          3245.                26.3  
      2              2.34         0.00000890         3042.                25.9  
      3             -2.11        -0.00000802         -203.                -0.426
      4            -47.4        -47.4                  -6.25              -1.62 
        data_resolution
        <chr>          
      1 2x2            
      2 2x2            
      3 2x2            
      4 2x2            
      # change = scenario - baseline (positive = scenario is higher)
      # pct_change = 100 * change / baseline

# habitat_connectivity_comparison() vector distance stacks per distance

    Code
      results
    Output
      # Connectivity comparison: baseline / scenario / change / pct_change
      # A tibble: 8 x 10
        scenario_name measure    species           interpatch_distance n_patches
        <chr>         <chr>      <chr>                           <dbl>     <dbl>
      1 <NA>          baseline   Superb Fairy Wren                  40         3
      2 <NA>          scenario   Superb Fairy Wren                  40         3
      3 <NA>          change     Superb Fairy Wren                  40         0
      4 <NA>          pct_change Superb Fairy Wren                  40         0
      5 <NA>          baseline   Superb Fairy Wren                  80         3
      6 <NA>          scenario   Superb Fairy Wren                  80         3
      7 <NA>          change     Superb Fairy Wren                  80         0
      8 <NA>          pct_change Superb Fairy Wren                  80         0
        effective_mesh_ha prob_connectedness patch_area_mean patch_area_total_ha
                    <dbl>              <dbl>           <dbl>               <dbl>
      1             0.915          0.0000367           8322.                2.50
      2             0.915          0.0000367           8322.                2.50
      3             0              0                      0                 0   
      4             0              0                      0                 0   
      5             0.915          0.0000367           8322.                2.50
      6             0.915          0.0000367           8322.                2.50
      7             0              0                      0                 0   
      8             0              0                      0                 0   
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

# habitat_connectivity_comparison() rejects a missing or empty distance

    Code
      comparison_at()
    Condition
      Error in `habitat_connectivity_comparison()`:
      ! `interpatch_distance` is absent but must be supplied.
    Code
      comparison_at(interpatch_distance = numeric(0))
    Condition
      Error in `habitat_connectivity_comparison()`:
      ! `interpatch_distance` must contain at least one distance.
      x You supplied a zero-length value.

# habitat_connectivity_comparison() aborts when both layers differ

    Code
      habitat_connectivity_comparison(habitat_scenario = layers$habitat_scenario,
      barrier_scenario = layers$barrier_scenario, habitat_baseline = layers$habitat,
      barrier_baseline = layers$barrier, species = "Superb Fairy Wren",
      interpatch_distance = 40, verbose = FALSE)
    Condition
      Error in `habitat_connectivity_comparison()`:
      ! Both habitat and barrier differ from baseline.
      i Change only one at a time so the difference is attributable.

# habitat_connectivity_comparison() aborts on a scenario elsewhere

    Code
      habitat_connectivity_comparison(habitat_scenario = layers$habitat,
      barrier_scenario = elsewhere, habitat_baseline = layers$habitat,
      barrier_baseline = layers$barrier, species = "Superb Fairy Wren",
      interpatch_distance = 40, verbose = FALSE)
    Condition
      Error in `habitat_connectivity_comparison()`:
      ! `barrier_scenario` and `barrier_baseline` are not the same landscape.
      x Their extent differs.
      i Put both on one grid first: rasterise or resample the scenario onto the baseline.

---

    Code
      habitat_connectivity_comparison(habitat_scenario = layers$habitat,
      barrier_scenario = coarser, habitat_baseline = layers$habitat,
      barrier_baseline = layers$barrier, species = "Superb Fairy Wren",
      interpatch_distance = 40, verbose = FALSE)
    Condition
      Error in `habitat_connectivity_comparison()`:
      ! `barrier_scenario` and `barrier_baseline` are not the same landscape.
      x Their resolution differs.
      i Put both on one grid first: rasterise or resample the scenario onto the baseline.

