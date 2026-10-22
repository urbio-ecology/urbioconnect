# add_patch_area returns a two-layer raster named patch_id and area

    Code
      names(result)
    Output
      [1] "patch_id" "area"    

# aggregate_connected_patches returns tibble with correct columns

    Code
      names(res_con_patch)
    Output
      [1] "patch_id" "area"    

# habitat_connectivity returns a data frame with expected columns

    Code
      names(hc_quiet)
    Output
      [1] "patch_id" "area"    

# habitat_connectivity_full returns list with expected elements

    Code
      names(hcf_quiet)
    Output
      [1] "buffered_habitat"  "patch_id_raster"   "areas_connected"  
      [4] "barrier_mask"      "remaining_habitat"

