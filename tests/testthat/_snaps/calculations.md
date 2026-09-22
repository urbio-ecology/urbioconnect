# summarise_connectivity returns a tibble with expected columns

    Code
      names(result)
    Output
      [1] "species"             "interpatch_distance" "n_patches"          
      [4] "effective_mesh_ha"   "prob_connectedness"  "patch_area_mean"    
      [7] "patch_area_total_ha" "data_resolution"     "patch_size"         

---

    Code
      result
    Output
      # A tibble: 1 x 9
        species     interpatch_distance n_patches effective_mesh_ha prob_connectedness
        <chr>                     <dbl>     <int>             <dbl>              <dbl>
      1 Test Speci~                 100         1                 1             0.0001
      # i 4 more variables: patch_area_mean <dbl>, patch_area_total_ha <dbl>,
      #   data_resolution <dbl>, patch_size <list>

# summarise_connectivity works with patch_size data

    Code
      summarise_connectivity(lizard_areas_connected)
    Output
      # A tibble: 1 x 9
        species     interpatch_distance n_patches effective_mesh_ha prob_connectedness
        <chr>                     <dbl>     <int>             <dbl>              <dbl>
      1 Blue-tongu~                  50        73              4.47          0.0000170
      # i 4 more variables: patch_area_mean <dbl>, patch_area_total_ha <dbl>,
      #   data_resolution <chr>, patch_size <list>

---

    Code
      summarise_connectivity(connectivity = lizard_areas_connected)
    Output
      # A tibble: 1 x 9
        species     interpatch_distance n_patches effective_mesh_ha prob_connectedness
        <chr>                     <dbl>     <int>             <dbl>              <dbl>
      1 Blue-tongu~                  50        73              4.47          0.0000170
      # i 4 more variables: patch_area_mean <dbl>, patch_area_total_ha <dbl>,
      #   data_resolution <chr>, patch_size <list>

