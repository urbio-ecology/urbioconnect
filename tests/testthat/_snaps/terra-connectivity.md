# fragment_habitat rejects a buffer with several layers

    Code
      fragment_habitat(habitat_buffer(habitat, c(10, 20)), barrier_mask)
    Condition
      Error in `fragment_habitat()`:
      ! `buffered_habitat` must have one layer, not 2.

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

# habitat_connectivity() reports each step once

    Code
      invisible(habitat_connectivity(habitat, barrier, "lizard", c(20, 40)))
    Message
      i Creating barrier mask
      v Creating barrier mask [time]
      
      i Removing habitat underneath barrier
      v Removing habitat underneath barrier [time]
      
      i Measuring the distance to the nearest habitat
      v Measuring the distance to the nearest habitat [time]
      
      i Buffering habitat for an interpatch distance of 20m
      v Buffering habitat for an interpatch distance of 20m [time]
      
      i Fragmenting habitat layer along barrier intersection
      v Fragmenting habitat layer along barrier intersection [time]
      
      i Assigning patches ID to fragments
      v Assigning patches ID to fragments [time]
      
      i Summarising area in each patch
      v Summarising area in each patch [time]
      
      i Buffering habitat for an interpatch distance of 40m
      v Buffering habitat for an interpatch distance of 40m [time]
      
      i Fragmenting habitat layer along barrier intersection
      v Fragmenting habitat layer along barrier intersection [time]
      
      i Assigning patches ID to fragments
      v Assigning patches ID to fragments [time]
      
      i Summarising area in each patch
      v Summarising area in each patch [time]
      

# habitat_connectivity returns a data frame with expected columns

    Code
      names(hc_quiet)
    Output
      [1] "patch_id" "area"    

# a sweep on the lizard grid gives the patch counts per distance

    Code
      as.data.frame(sweep[c("interpatch_distance", "n_patches", "effective_mesh_ha")])
    Output
        interpatch_distance n_patches effective_mesh_ha
      1                  20       479          2.317227
      2                  40       140          4.260359
      3                 100        57          4.561874
      4                 250        46          5.444837
      5                 400        46          5.444837

# habitat_connectivity() checks species before any work

    Code
      habitat_connectivity(small_habitat, small_barrier, species = 1,
        interpatch_distance = 200, verbose = FALSE)
    Condition
      Error in `habitat_connectivity()`:
      ! `species` must be <character>, not <numeric>.
      i You supplied: a number

# habitat_connectivity_full returns list with expected elements

    Code
      names(hcf_quiet)
    Output
      [1] "buffered_habitat"  "patch_id_raster"   "areas_connected"  
      [4] "barrier_mask"      "remaining_habitat"

