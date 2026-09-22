# Derive a synthetic *habitat scenario* from the baseline wren habitat by
# removing a corner patch of habitat — a legible "a development removes a patch
# of habitat" change. Only the habitat values change: the CRS, extent and
# resolution are inherited unchanged from `example_wren_habitat()`, mirroring
# the barrier scenario in `wren-example.R`.
library(terra)
library(urbioconnect)

wren_habitat <- example_wren_habitat()

# North-east corner development block: the eastern-most 30% of the study width
# and the northern-most 30% of its height.
habitat_extent <- terra::ext(wren_habitat)
development <- terra::ext(
  habitat_extent$xmax - 0.30 * (habitat_extent$xmax - habitat_extent$xmin),
  habitat_extent$xmax,
  habitat_extent$ymax - 0.30 * (habitat_extent$ymax - habitat_extent$ymin),
  habitat_extent$ymax
)
development_poly <- terra::vect(development, crs = terra::crs(wren_habitat))

# `inverse = TRUE` sets the habitat cells *inside* the development polygon to
# NA, leaving all habitat outside the block untouched.
wren_habitat_scenario <- terra::mask(
  wren_habitat,
  development_poly,
  inverse = TRUE
)

terra::writeRaster(
  x = wren_habitat_scenario,
  filename = "inst/ex/wren_habitat_scenario_rast.tif",
  filetype = "COG",
  overwrite = TRUE
)
