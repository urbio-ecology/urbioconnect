# connectivity_probability errors unless given two single numbers

    Code
      connectivity_probability(effective_mesh_ha = c(1, 2), area_baseline_ha = 1)
    Condition
      Error in `connectivity_probability()`:
      ! `effective_mesh_ha` must be a scalar (length 1), not length 2.
      i Did you mean to pass a single value?

---

    Code
      connectivity_probability(effective_mesh_ha = 1, area_baseline_ha = lizard_areas_connected$
        area)
    Condition
      Error in `connectivity_probability()`:
      ! `area_baseline_ha` must be a scalar (length 1), not length 73.
      i Did you mean to pass a single value?

---

    Code
      connectivity_probability(effective_mesh_ha = "1", area_baseline_ha = 1)
    Condition
      Error in `connectivity_probability()`:
      ! `effective_mesh_ha` must be <numeric>, not <character>.
      i You supplied: a string

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
      1 Test Speci~                 100         1                 1                  1
      # i 4 more variables: patch_area_mean <dbl>, patch_area_total_ha <dbl>,
      #   data_resolution <dbl>, patch_size <list>

# summarise_connectivity works with patch_size data

    Code
      summarise_connectivity(lizard_areas_connected)
    Output
      # A tibble: 1 x 9
        species     interpatch_distance n_patches effective_mesh_ha prob_connectedness
        <chr>                     <dbl>     <int>             <dbl>              <dbl>
      1 Blue-tongu~                  50        73              4.47              0.170
      # i 4 more variables: patch_area_mean <dbl>, patch_area_total_ha <dbl>,
      #   data_resolution <chr>, patch_size <list>

---

    Code
      summarise_connectivity(connectivity = lizard_areas_connected)
    Output
      # A tibble: 1 x 9
        species     interpatch_distance n_patches effective_mesh_ha prob_connectedness
        <chr>                     <dbl>     <int>             <dbl>              <dbl>
      1 Blue-tongu~                  50        73              4.47              0.170
      # i 4 more variables: patch_area_mean <dbl>, patch_area_total_ha <dbl>,
      #   data_resolution <chr>, patch_size <list>

