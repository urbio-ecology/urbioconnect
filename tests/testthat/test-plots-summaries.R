lizard_habitat <- example_habitat()
lizard_barrier <- example_barrier()
interpatch_dist <- 10
buffered <- habitat_buffer(lizard_habitat, interpatch_dist)
barrier_mask <- create_barrier_mask(lizard_barrier)
fragmented <- fragment_habitat(buffered, barrier_mask)
remaining <- drop_habitat_under_barrier(lizard_habitat, barrier_mask)
patch_id_raster <- assign_patches_to_fragments(remaining, fragmented) |>
  add_patch_area()

# Small rasters for results_connect - plot_connectivity only needs summary
# stats, not realistic habitat geometry
small_habitat <- terra::rast(
  nrows = 20,
  ncols = 20,
  extent = terra::ext(0, 2000, 0, 2000),
  crs = terra::crs(lizard_habitat),
  vals = 1
)
small_barrier <- terra::rast(
  nrows = 20,
  ncols = 20,
  extent = terra::ext(0, 2000, 0, 2000),
  crs = terra::crs(lizard_habitat),
  vals = NA
)
small_barrier[10, 10] <- 1

results_connect <- purrr::map(
  c(100, 200),
  function(d) {
    full <- habitat_connectivity_full(
      small_habitat,
      small_barrier,
      interpatch_distance = d,
      verbose = FALSE
    )
    summarise_connectivity(
      connectivity = full$areas_connected$area,
      interpatch_distance = d,
      data_resolution = 10,
      species = "Lizard"
    )
  }
) |>
  purrr::list_rbind()

# col2hex ---------------------------------------------------------------

test_that("col2hex converts colour name to hex", {
  expect_snapshot(col2hex("forestgreen"))
  expect_snapshot(col2hex("blue"))
})

# to_sentence -----------------------------------------------------------

test_that("to_sentence converts snake_case to sentence case", {
  expect_snapshot(to_sentence("prob_connectedness"))
  expect_snapshot(to_sentence(c("n_patches", "patch_area_mean")))
})

# gg_barrier_habitat_interpatch_dist ---------------------------------------------

gg_buffer_plot <- gg_barrier_habitat_interpatch_dist(
  barrier = lizard_barrier,
  buffered = buffered,
  habitat = lizard_habitat,
  interpatch_distance = interpatch_dist,
  species = "Blue Tongue Lizard",
  col_barrier = "white",
  col_interpatch_dist = "lightgreen",
  col_habitat = "seagreen",
  col_paper = "grey50"
)

test_that("gg_barrier_habitat_interpatch_dist returns a ggplot", {
  expect_s3_class(gg_buffer_plot, "ggplot")
})

test_that("gg_barrier_habitat_interpatch_dist defaults to the palette", {
  # the app, the downloads and the report all rely on this default rather than
  # passing the colours themselves
  defaults <- formals(gg_barrier_habitat_interpatch_dist)

  expect_equal(
    purrr::map(
      defaults[c("col_barrier", "col_interpatch_dist", "col_habitat")],
      eval
    ),
    urbio_colours()[c("barrier", "interpatch_distance", "habitat")],
    ignore_attr = "names"
  )
})

test_that("gg_barrier_habitat_interpatch_dist renders correctly", {
  skip_on_ci()
  vdiffr::expect_doppelganger("gg-barrier-habitat-interpatch", gg_buffer_plot)
})

# plot_patches ----------------------------------------------------------

test_that("plot_patches returns a ggplot", {
  result <- plot_patches(
    patch_id_raster,
    interpatch_distance = interpatch_dist
  )
  expect_s3_class(result, "ggplot")
})

test_that("plot_patches renders correctly", {
  skip_on_ci()
  vdiffr::expect_doppelganger(
    "plot-patches",
    plot_patches(
      patch_id_raster,
      interpatch_distance = interpatch_dist,
      species = "Blue Tongue Lizard"
    )
  )
})

# plot_connectivity -----------------------------------------------------

test_that("plot_connectivity returns a ggplot", {
  result <- plot_connectivity(results_connect)
  expect_s3_class(result, "ggplot")
})

test_that("plot_connectivity renders correctly", {
  skip_on_ci()
  vdiffr::expect_doppelganger(
    "plot-connectivity",
    plot_connectivity(results_connect)
  )
})
