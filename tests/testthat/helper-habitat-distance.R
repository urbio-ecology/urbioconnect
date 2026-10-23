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

# Exact distance from every cell centre to the nearest habitat centre
brute_force_distance <- function(habitat) {
  centres <- terra::xyFromCell(habitat, seq_len(terra::ncell(habitat)))
  habitat_centres <- centres[
    is_habitat(terra::values(habitat)[, 1]),
    ,
    drop = FALSE
  ]

  purrr::map_dbl(seq_len(nrow(centres)), function(cell) {
    min(sqrt(
      (habitat_centres[, 1] - centres[cell, 1])^2 +
        (habitat_centres[, 2] - centres[cell, 2])^2
    ))
  })
}

# Count the distance surfaces measured while the calling test runs. Returns
# a function that reads the count.
local_surface_count <- function(env = rlang::caller_env()) {
  measure <- nearest_habitat_distance
  calls <- new.env()
  calls$n <- 0

  local_mocked_bindings(
    nearest_habitat_distance = function(...) {
      calls$n <- calls$n + 1
      measure(...)
    },
    .env = env
  )

  function() calls$n
}
