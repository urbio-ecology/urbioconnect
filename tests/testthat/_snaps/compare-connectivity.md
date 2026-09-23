# compare_connectivity() identifies changes in baseline/scenario

    Code
      results_compare
    Output
      # Connectivity comparison: baseline / scenario / change / pct_change
      # A tibble: 4 x 10
        scenario_name measure    species           interpatch_distance n_patches
        <chr>         <chr>      <chr>                           <dbl>     <dbl>
      1 <NA>          baseline   Superb Fairy Wren                 200   282    
      2 <NA>          scenario   Superb Fairy Wren                 200   283    
      3 <NA>          change     Superb Fairy Wren                 200     1    
      4 <NA>          pct_change Superb Fairy Wren                 200     0.355
        effective_mesh_ha prob_connectedness patch_area_mean patch_area_total_ha
                    <dbl>              <dbl>           <dbl>               <dbl>
      1           334.          0.0000225           52556.               1482.  
      2           333.          0.0000224           51828.               1467.  
      3            -0.965      -0.0000000651         -728.                -15.3 
      4            -0.289      -0.289                  -1.38               -1.04
        data_resolution 
        <chr>           
      1 9.99673x10.00151
      2 9.99673x10.00151
      3 9.99673x10.00151
      4 9.99673x10.00151
      # change = scenario - baseline (positive = scenario is higher)
      # pct_change = 100 * change / baseline

# compare_connectivity() against itself gives a zero change row

    Code
      results_self
    Output
      # Connectivity comparison: baseline / scenario / change / pct_change
      # A tibble: 4 x 10
        scenario_name measure    species             interpatch_distance n_patches
        <chr>         <chr>      <chr>                             <dbl>     <dbl>
      1 <NA>          baseline   Blue-tongued Lizard                  50        73
      2 <NA>          scenario   Blue-tongued Lizard                  50        73
      3 <NA>          change     Blue-tongued Lizard                  50         0
      4 <NA>          pct_change Blue-tongued Lizard                  50         0
        effective_mesh_ha prob_connectedness patch_area_mean patch_area_total_ha
                    <dbl>              <dbl>           <dbl>               <dbl>
      1              4.47          0.0000170           3600.                26.3
      2              4.47          0.0000170           3600.                26.3
      3              0             0                      0                  0  
      4              0             0                      0                  0  
        data_resolution
        <chr>          
      1 2x2            
      2 2x2            
      3 2x2            
      4 2x2            
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

# compare_connectivity() labels every row with scenario_name

    Code
      names(labelled)
    Output
       [1] "scenario_name"       "measure"             "species"            
       [4] "interpatch_distance" "n_patches"           "effective_mesh_ha"  
       [7] "prob_connectedness"  "patch_area_mean"     "patch_area_total_ha"
      [10] "data_resolution"    

# compare_connectivity() rejects a scenario_name that isn't one string

    Code
      compare_connectivity(scen, base, scenario_name = c("one", "two"))
    Condition
      Error in `compare_connectivity()`:
      ! `scenario_name` must be a scalar (length 1), not length 2.
      i Did you mean to pass a single value?
    Code
      compare_connectivity(scen, base, scenario_name = 1)
    Condition
      Error in `compare_connectivity()`:
      ! `scenario_name` must be <character>, not <numeric>.
      i You supplied: a number

# compare_connectivity() works on default-method connectivity

    Code
      compare_connectivity(scenario = scen, baseline = base)
    Output
      # Connectivity comparison: baseline / scenario / change / pct_change
      # A tibble: 4 x 10
        scenario_name measure    species      interpatch_distance n_patches
        <chr>         <chr>      <chr>                      <dbl>     <dbl>
      1 <NA>          baseline   Test Species                  10       3  
      2 <NA>          scenario   Test Species                  10       2  
      3 <NA>          change     Test Species                  10      -1  
      4 <NA>          pct_change Test Species                  10     -33.3
        effective_mesh_ha prob_connectedness patch_area_mean patch_area_total_ha
                    <dbl>              <dbl>           <dbl>               <dbl>
      1           0.0233           0.0000389             200                0.06
      2           0.00833          0.0000139             150                0.03
      3          -0.015           -0.000025              -50               -0.03
      4         -64.3            -64.3                   -25              -50   
        data_resolution
                  <dbl>
      1               2
      2               2
      3               2
      4               2
      # change = scenario - baseline (positive = scenario is higher)
      # pct_change = 100 * change / baseline

