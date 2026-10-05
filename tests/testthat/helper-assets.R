# synthetic layers: ~0.1s per distance, against ~4.7s on the wren rasters
test_report_data <- function(interpatch_distance = 40) {
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
  skip_if_not(quarto_available(), "the Quarto CLI is not installed")
}

test_report_text <- function(path) {
  paste(readLines(path, warn = FALSE), collapse = " ")
}
