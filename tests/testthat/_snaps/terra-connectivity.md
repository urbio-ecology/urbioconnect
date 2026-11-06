# habitat_connectivity rejects a habitat with several layers

    Code
      habitat_connectivity(stacked, barrier, "lizard", 60, verbose = FALSE)
    Condition
      Error in `drop_habitat_under_barrier()`:
      ! `habitat` must have one layer, not 2.

# habitat_buffer() measures rows by the cell height on non-square cells

    Code
      buffered <- habitat_buffer(habitat, 19)
    Condition
      Warning:
      `interpatch_distance` doesn't align with the raster resolution.
      x 38 m isn't a multiple of 20 m.
      i It snaps to 20 m across and 38 m up and down.
      i Connectivity may shift for patches near the cut-off.
      i See `vignette(urbioconnect::interpatch-distance-and-resolution)`.

---

    Code
      terra::as.matrix(!is.na(buffered), wide = TRUE)
    Output
            [,1]  [,2] [,3]  [,4]  [,5]
      [1,] FALSE FALSE TRUE FALSE FALSE
      [2,] FALSE  TRUE TRUE  TRUE FALSE
      [3,] FALSE  TRUE TRUE  TRUE FALSE
      [4,] FALSE  TRUE TRUE  TRUE FALSE
      [5,] FALSE FALSE TRUE FALSE FALSE

# habitat_buffer() judges 'below one cell' by the smaller cell side

    Code
      buffered <- habitat_buffer(habitat, 9.7)
    Condition
      Warning:
      `interpatch_distance` doesn't align with the raster resolution.
      x 19.4 m isn't a multiple of 20 or 19 m.
      i It snaps to 0 m across and 19 m up and down.
      i Connectivity may shift for patches near the cut-off.
      i See `vignette(urbioconnect::interpatch-distance-and-resolution)`.

---

    Code
      terra::as.matrix(!is.na(buffered), wide = TRUE)
    Output
            [,1]  [,2]  [,3]  [,4]  [,5]
      [1,] FALSE FALSE FALSE FALSE FALSE
      [2,] FALSE FALSE  TRUE FALSE FALSE
      [3,] FALSE FALSE  TRUE FALSE FALSE
      [4,] FALSE FALSE  TRUE FALSE FALSE
      [5,] FALSE FALSE FALSE FALSE FALSE

# habitat_buffer() takes a habitat with one layer only

    Code
      habitat_buffer(c(layer, layer), 20)
    Condition
      Error in `habitat_buffer()`:
      ! `habitat` must have one layer, not 2.

# habitat_buffer() warns below one cell and keeps only the habitat

    Code
      buffered <- habitat_buffer(layer, 5)
    Condition
      Warning:
      Can't represent an `interpatch_distance` of 10m at a resolution of 10m.
      x Half that distance (5m) is smaller than one raster cell.
      i Gaps between patches aren't bridged; only touching patches are linked.
      i Rule of thumb: keep resolution <= interpatch_distance / 2 (use finer cells, or a larger interpatch distance).
      i See `vignette(urbioconnect::interpatch-distance-and-resolution)`.

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

