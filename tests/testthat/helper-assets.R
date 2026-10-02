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

skip_if_no_quarto <- function() {
  skip_on_cran()
  skip_if_not(quarto::quarto_available(), "the Quarto CLI is not installed")
}

# A rendered report, read back as one string. Each render costs ~15s, so tests
# share one where they can.
test_report_text <- function(path) {
  paste(readLines(path, warn = FALSE), collapse = " ")
}
