# habitat_connectivity_comparison() scalar distance gives one block of 4 rows

    Code
      results
    Output
      # Connectivity comparison: baseline / scenario / change / pct_change
      # A tibble: 4 x 9
        measure    species           interpatch_distance n_patches effective_mesh_ha
        <chr>      <chr>                           <dbl>     <dbl>             <dbl>
      1 baseline   Superb Fairy Wren                 200   282               334.   
      2 scenario   Superb Fairy Wren                 200   283               333.   
      3 change     Superb Fairy Wren                 200     1                -0.965
      4 pct_change Superb Fairy Wren                 200     0.355            -0.289
        prob_connectedness patch_area_mean patch_area_total_ha data_resolution 
                     <dbl>           <dbl>               <dbl> <chr>           
      1       0.0000225           52556.               1482.   9.99673x10.00151
      2       0.0000224           51828.               1467.   9.99673x10.00151
      3      -0.0000000651         -728.                -15.3  9.99673x10.00151
      4      -0.289                  -1.38               -1.04 9.99673x10.00151
      # change = scenario - baseline (positive = scenario is higher)
      # pct_change = 100 * change / baseline

# habitat_connectivity_comparison() vector distance stacks per distance

    Code
      results
    Output
      # Connectivity comparison: baseline / scenario / change / pct_change
      # A tibble: 8 x 9
        measure    species           interpatch_distance n_patches effective_mesh_ha
        <chr>      <chr>                           <dbl>     <dbl>             <dbl>
      1 baseline   Superb Fairy Wren                 100   439              327.    
      2 scenario   Superb Fairy Wren                 100   436              327.    
      3 change     Superb Fairy Wren                 100    -3               -0.244 
      4 pct_change Superb Fairy Wren                 100    -0.683           -0.0745
      5 baseline   Superb Fairy Wren                 200   282              334.    
      6 scenario   Superb Fairy Wren                 200   283              333.    
      7 change     Superb Fairy Wren                 200     1               -0.965 
      8 pct_change Superb Fairy Wren                 200     0.355           -0.289 
        prob_connectedness patch_area_mean patch_area_total_ha data_resolution 
                     <dbl>           <dbl>               <dbl> <chr>           
      1       0.0000221          33760.                1482.   9.99673x10.00151
      2       0.0000220          33641.                1467.   9.99673x10.00151
      3      -0.0000000164        -120.                 -15.3  9.99673x10.00151
      4      -0.0745                -0.354               -1.04 9.99673x10.00151
      5       0.0000225          52556.                1482.   9.99673x10.00151
      6       0.0000224          51828.                1467.   9.99673x10.00151
      7      -0.0000000651        -728.                 -15.3  9.99673x10.00151
      8      -0.289                 -1.38                -1.04 9.99673x10.00151
      # change = scenario - baseline (positive = scenario is higher)
      # pct_change = 100 * change / baseline

# habitat_connectivity_comparison() aborts when neither distance nor buffer supplied

    Code
      habitat_connectivity_comparison(habitat_scenario = wren_habitat,
        barrier_scenario = wren_barrier_scenario, habitat_baseline = wren_habitat,
        barrier_baseline = wren_barrier, species = "Superb Fairy Wren", verbose = FALSE)
    Condition
      Error in `habitat_connectivity_comparison()`:
      ! Specify exactly one of `interpatch_distance` or `buffer_radius`.
      x Neither was supplied.

# habitat_connectivity_comparison() aborts when both distance and buffer supplied

    Code
      habitat_connectivity_comparison(habitat_scenario = wren_habitat,
        barrier_scenario = wren_barrier_scenario, habitat_baseline = wren_habitat,
        barrier_baseline = wren_barrier, species = "Superb Fairy Wren",
        interpatch_distance = 200, buffer_radius = 100, verbose = FALSE)
    Condition
      Error in `habitat_connectivity_comparison()`:
      ! Specify exactly one of `interpatch_distance` or `buffer_radius`.
      x Both were supplied.

# habitat_connectivity_comparison() aborts when both layers differ

    Code
      habitat_connectivity_comparison(habitat_scenario = wren_habitat_scenario,
        barrier_scenario = wren_barrier_scenario, habitat_baseline = wren_habitat,
        barrier_baseline = wren_barrier, species = "Superb Fairy Wren",
        interpatch_distance = 200, verbose = FALSE)
    Condition
      Error in `habitat_connectivity_comparison()`:
      ! Both habitat and barrier differ from baseline.
      i Change only one at a time so the difference is attributable.

