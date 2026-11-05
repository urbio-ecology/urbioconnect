# A projected test raster, `cell` metres wide and high (x then y), filled with
# `fill`
test_raster <- function(nrows, ncols, cell = c(10, 10), fill = NA) {
  layer <- terra::rast(
    nrows = nrows,
    ncols = ncols,
    extent = terra::ext(0, ncols * cell[1], 0, nrows * cell[2]),
    crs = "EPSG:28355"
  )
  terra::values(layer) <- fill
  layer
}
