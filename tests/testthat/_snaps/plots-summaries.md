# col2hex converts colour name to hex

    Code
      col2hex("forestgreen")
    Output
      [1] "#228B22"

---

    Code
      col2hex("blue")
    Output
      [1] "#0000FF"

# to_sentence converts snake_case to sentence case

    Code
      to_sentence("prob_connectedness")
    Output
      [1] "Prob connectedness"

---

    Code
      to_sentence(c("n_patches", "patch_area_mean"))
    Output
      [1] "N patches"       "Patch area mean"

# gg_layer rejects a layer it has no colours for

    Code
      gg_layer(example_habitat(), "interpatch")
    Condition
      Error in `gg_layer()`:
      ! `kind` must be one of "habitat" or "barrier", not "interpatch".

# plot_patches draws the barrier, and shades each patch's zone

    Code
      data.frame(inputs, barrier_only, with_zone)
    Output
        habitat barrier buffered barrier_only with_zone
      1       1       0        1      #E16A86   #E16A86
      2      NA       0        1         <NA>   #FFCAD3
      3      NA       1        1       grey55    grey55
      4      NA       0        1         <NA>      <NA>
      5      NA       1       NA       grey55    grey55
      6      NA       0        1         <NA>   #BFE476
      7       1       0        1      #799D00   #799D00
      8      NA       0        1         <NA>   #BFE476
      9      NA       0        1         <NA>   #BFE476

# plot_patches needs the barrier to draw the zone

    Code
      plot_patches(patch_id_raster, interpatch_dist, buffered = buffered)
    Condition
      Error in `plot_patches()`:
      ! `buffered` needs `barrier`, which cuts the buffer into zones.

