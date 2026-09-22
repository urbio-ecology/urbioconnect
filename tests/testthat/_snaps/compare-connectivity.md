# compare_connectivity() identifies changes in baseline/scenario

    Code
      results_compare
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

# compare_connectivity() against itself gives a zero change row

    Code
      results_self
    Output
      # Connectivity comparison: baseline / scenario / change / pct_change
      # A tibble: 4 x 9
        measure    species             interpatch_distance n_patches effective_mesh_ha
        <chr>      <chr>                             <dbl>     <dbl>             <dbl>
      1 baseline   Blue-tongued Lizard                  50        73              4.47
      2 scenario   Blue-tongued Lizard                  50        73              4.47
      3 change     Blue-tongued Lizard                  50         0              0   
      4 pct_change Blue-tongued Lizard                  50         0              0   
        prob_connectedness patch_area_mean patch_area_total_ha data_resolution
                     <dbl>           <dbl>               <dbl> <chr>          
      1          0.0000170           3600.                26.3 2x2            
      2          0.0000170           3600.                26.3 2x2            
      3          0                      0                  0   2x2            
      4          0                      0                  0   2x2            
      # change = scenario - baseline (positive = scenario is higher)
      # pct_change = 100 * change / baseline

# compare_connectivity() rejects multi-row input

    Code
      compare_connectivity(dplyr::bind_rows(base, base), base)
    Condition
      Error in `compare_connectivity()`:
      ! `scenario` and `baseline` must each be a single-row <connectivity> object.
      i `scenario` has 2 rows; `baseline` has 1 row.

# compare_connectivity() rejects non-connectivity input

    Code
      compare_connectivity(scenario = lizard_areas_connected$area, baseline = base)
    Condition
      Error in `compare_connectivity()`:
      ! `scenario` must be a <connectivity> object, not <numeric>.

