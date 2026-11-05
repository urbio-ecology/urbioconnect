# habitat_connectivity_comparison() scalar distance gives one block of 4 rows

    Code
      print(results, width = Inf)
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

# habitat_connectivity_comparison() vector distance stacks per distance

    Code
      print(results, width = Inf)
    Output
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
      1             0.915              0.367           8322.                2.50
      2             0.915              0.367           8322.                2.50
      3             0                  0                  0                 0   
      4             0                  0                  0                 0   
      5             0.915              0.367           8322.                2.50
      6             0.915              0.367           8322.                2.50
      7             0                  0                  0                 0   
      8             0                  0                  0                 0   
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

# habitat_connectivity_comparison() rejects a missing, empty or unusable distance

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
    Code
      comparison_at(interpatch_distance = c(100, -50, NA, -50, NA))
    Condition
      Error in `habitat_connectivity_comparison()`:
      ! `interpatch_distance` must be finite and not negative.
      x Not usable: -50 and NA.

# habitat_connectivity_comparison() needs a scenario layer

    Code
      habitat_connectivity_comparison(habitat_baseline = layers$habitat,
      barrier_baseline = layers$barrier, species = "Test Species",
      interpatch_distance = 40, verbose = FALSE)
    Condition
      Error in `habitat_connectivity_comparison()`:
      ! Give `habitat_scenario`, `barrier_scenario`, or both: the layers your planned change replaces.

# habitat_connectivity_comparison() aborts on a scenario elsewhere

    Code
      habitat_connectivity_comparison(habitat_baseline = layers$habitat,
      barrier_baseline = layers$barrier, species = "Superb Fairy Wren",
      interpatch_distance = 40, barrier_scenario = elsewhere, verbose = FALSE)
    Condition
      Error in `habitat_connectivity_comparison()`:
      ! `barrier_scenario` and `barrier_baseline` are not the same landscape.
      x Their extent differs.
      i Put `barrier_scenario` on the grid of `barrier_baseline` first, with `onto_grid()`.

---

    Code
      habitat_connectivity_comparison(habitat_baseline = layers$habitat,
      barrier_baseline = layers$barrier, species = "Superb Fairy Wren",
      interpatch_distance = 40, habitat_scenario = coarser, verbose = FALSE)
    Condition
      Error in `habitat_connectivity_comparison()`:
      ! `habitat_scenario` and `habitat_baseline` are not the same landscape.
      x Their resolution differs.
      i Put `habitat_scenario` on the grid of `habitat_baseline` first, with `onto_grid()`.

# habitat_connectivity_comparison() rejects a scenario that isn't a raster

    Code
      comparison_with(road)
    Condition
      Error in `habitat_connectivity_comparison()`:
      ! `barrier_scenario` must be a <SpatRaster>, not a <SpatVector> object.
      i Put it on the grid of `barrier_baseline` first, with `onto_grid()`.
    Code
      comparison_with(sf::st_as_sf(road))
    Condition
      Error in `habitat_connectivity_comparison()`:
      ! `barrier_scenario` must be a <SpatRaster>, not a <sf> object.
      i Put it on the grid of `barrier_baseline` first, with `onto_grid()`.

