# A bundle built from the synthetic layers: ~0.1s per distance, against ~4.7s
# per distance on the wren rasters.
test_asset_bundle <- function(interpatch_distance = 40) {
  layers <- scenario_test_layers()

  connectivity_report_data(
    habitat = layers$habitat,
    barrier = layers$barrier,
    species = "Superb Fairy Wren",
    interpatch_distance = interpatch_distance,
    verbose = FALSE
  )
}
