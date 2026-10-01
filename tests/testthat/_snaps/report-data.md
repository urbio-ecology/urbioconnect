# connectivity_report_data() keeps a summary and layers per distance

    Code
      names(report_data)
    Output
      [1] "connectivity"        "habitat"             "barrier"            
      [4] "buffered_habitat"    "patch_id_raster"     "species"            
      [7] "interpatch_distance"

# connectivity_report_data() checks its arguments

    Code
      connectivity_report_data(habitat = layers$habitat, barrier = layers$barrier,
      species = "Test Species", verbose = FALSE)
    Condition
      Error in `connectivity_report_data()`:
      ! Specify exactly one of `interpatch_distance` or `buffer_radius`.
      x Neither was supplied.
    Code
      connectivity_report_data(habitat = layers$habitat, barrier = layers$barrier,
      species = c("one", "two"), interpatch_distance = 40, verbose = FALSE)
    Condition
      Error in `connectivity_report_data()`:
      ! `species` must be a scalar (length 1), not length 2.
      i Did you mean to pass a single value?

