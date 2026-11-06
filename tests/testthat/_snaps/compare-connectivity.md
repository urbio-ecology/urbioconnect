# compare_connectivity() identifies changes in baseline/scenario

    Code
      print(results_compare, width = Inf)
    Output
      # A tibble: 4 x 10
        scenario_name measure    species            interpatch_distance n_patches
        <chr>         <chr>      <chr>                            <dbl>     <dbl>
      1 <NA>          baseline   Blue Tongue Lizard                  40     81   
      2 <NA>          scenario   Blue Tongue Lizard                  40     85   
      3 <NA>          change     Blue Tongue Lizard                  40      4   
      4 <NA>          pct_change Blue Tongue Lizard                  40      4.94
        effective_mesh_ha prob_connectedness patch_area_mean patch_area_total_ha
                    <dbl>              <dbl>           <dbl>               <dbl>
      1              4.45             0.169          3245.                26.3  
      2              2.34             0.0890         3042.                25.9  
      3             -2.11            -0.0802         -203.                -0.426
      4            -47.4            -47.4              -6.25              -1.62 
        data_resolution
        <chr>          
      1 2x2            
      2 2x2            
      3 2x2            
      4 2x2            

# compare_connectivity() against itself gives a zero change row

    Code
      print(results_self, width = Inf)
    Output
      # A tibble: 4 x 10
        scenario_name measure    species             interpatch_distance n_patches
        <chr>         <chr>      <chr>                             <dbl>     <dbl>
      1 <NA>          baseline   Blue-tongued Lizard                  50        73
      2 <NA>          scenario   Blue-tongued Lizard                  50        73
      3 <NA>          change     Blue-tongued Lizard                  50         0
      4 <NA>          pct_change Blue-tongued Lizard                  50         0
        effective_mesh_ha prob_connectedness patch_area_mean patch_area_total_ha
                    <dbl>              <dbl>           <dbl>               <dbl>
      1              4.47              0.170           3600.                26.3
      2              4.47              0.170           3600.                26.3
      3              0                 0                  0                  0  
      4              0                 0                  0                  0  
        data_resolution
        <chr>          
      1 2x2            
      2 2x2            
      3 2x2            
      4 2x2            

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
      print(comparison, width = Inf)
    Output
      # A tibble: 4 x 10
        scenario_name measure    species      interpatch_distance n_patches
        <chr>         <chr>      <chr>                      <dbl>     <dbl>
      1 <NA>          baseline   Test Species                  10       3  
      2 <NA>          scenario   Test Species                  10       2  
      3 <NA>          change     Test Species                  10      -1  
      4 <NA>          pct_change Test Species                  10     -33.3
        effective_mesh_ha prob_connectedness patch_area_mean patch_area_total_ha
                    <dbl>              <dbl>           <dbl>               <dbl>
      1           0.0233               0.389             200                0.06
      2           0.00833              0.139             150                0.03
      3          -0.015               -0.25              -50               -0.03
      4         -64.3                -64.3               -25              -50   
        data_resolution
                  <dbl>
      1               2
      2               2
      3               2
      4               2

# summary() prints a named scenario as one table

    Code
      summary(comparison)
    Output
      Scenario: Bentley Project
      Interpatch distance: 50 m
        Metric          Baseline Scenario Change % change
        Patches               73       68     -5    -6.85
        Mesh (ha)           4.47    0.815  -3.66    -81.8
        P(connected)        0.17    0.031 -0.139    -81.8
        Mean area (m2)      3600     2340  -1260    -34.9
        Total area (ha)     26.3     15.9  -10.3    -39.4

# summary() heads an unnamed scenario with its distance only

    Code
      summary(comparison)
    Output
      Interpatch distance: 50 m
        Metric          Baseline Scenario Change % change
        Patches               73       68     -5    -6.85
        Mesh (ha)           4.47    0.815  -3.66    -81.8
        P(connected)        0.17    0.031 -0.139    -81.8
        Mean area (m2)      3600     2340  -1260    -34.9
        Total area (ha)     26.3     15.9  -10.3    -39.4

# summary() prints a table per scenario

    Code
      summary(comparison)
    Output
      Scenario: Bentley Project
      Interpatch distance: 50 m
        Metric          Baseline Scenario    Change  % change
        Patches               73       72        -1     -1.37
        Mesh (ha)           4.47     4.47 -1.13e-05 -0.000252
        P(connected)        0.17     0.17 -4.28e-07 -0.000252
        Mean area (m2)      3600     3650      47.6      1.32
        Total area (ha)     26.3     26.3   -0.0172   -0.0654
      
      Scenario: Barrier upgrade
      Interpatch distance: 50 m
        Metric          Baseline Scenario Change % change
        Patches               73       68     -5    -6.85
        Mesh (ha)           4.47    0.815  -3.66    -81.8
        P(connected)        0.17    0.031 -0.139    -81.8
        Mean area (m2)      3600     2340  -1260    -34.9
        Total area (ha)     26.3     15.9  -10.3    -39.4

# summary() prints a table per interpatch distance

    Code
      summary(comparison)
    Output
      Scenario: A new road
      Interpatch distance: 40 m
        Metric          Baseline Scenario  Change % change
        Patches              140      144       4     2.86
        Mesh (ha)           4.26     1.96    -2.3      -54
        P(connected)       0.158   0.0725 -0.0851      -54
        Mean area (m2)      1930     1810    -118    -6.12
        Total area (ha)       27     26.1  -0.929    -3.44
      
      Scenario: A new road
      Interpatch distance: 80 m
        Metric          Baseline Scenario  Change % change
        Patches               73       77       4     5.48
        Mesh (ha)            4.5     2.09   -2.41    -53.6
        P(connected)       0.167   0.0773 -0.0893    -53.6
        Mean area (m2)      3700     3390    -313    -8.45
        Total area (ha)       27     26.1  -0.929    -3.44

# a summary cut down past its tables prints as a tibble

    Code
      dplyr::select(summarised, "Metric", "Baseline")
    Output
      # A tibble: 5 x 2
        Metric          Baseline
        <chr>              <dbl>
      1 Patches            73   
      2 Mesh (ha)           4.47
      3 P(connected)        0.17
      4 Mean area (m2)   3600   
      5 Total area (ha)    26.3 
    Code
      summarised["Distance (m)"]
    Output
      # A tibble: 5 x 1
        `Distance (m)`
                 <dbl>
      1             50
      2             50
      3             50
      4             50
      5             50

