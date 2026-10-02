small_habitat <- terra::rast(
  nrows = 20,
  ncols = 20,
  extent = terra::ext(0, 2000, 0, 2000),
  crs = "EPSG:32755",
  vals = 1
)
small_barrier <- terra::rast(
  nrows = 20,
  ncols = 20,
  extent = terra::ext(0, 2000, 0, 2000),
  crs = "EPSG:32755",
  vals = NA
)
small_barrier[10, 10] <- 1
buffered <- habitat_buffer(small_habitat, buffer_radius = 100)

test_that("plot_barrier_habitat_interpatch_dist saves a file and returns a named path", {
  withr::with_tempdir({
    dir.create("doc")
    result <- plot_barrier_habitat_interpatch_dist(
      barrier = small_barrier,
      buffered = buffered,
      habitat = small_habitat,
      interpatch_distance = 10,
      species = "Lizard",
      col_barrier = "white",
      col_interpatch_dist = "lightgreen",
      col_habitat = "seagreen",
      col_paper = "grey50"
    )
    expect_true(file.exists(result))
    expect_named(result, "10")
  })
})

test_that("plot_barrier_habitat_interpatch_dist defaults colours and slugs", {
  withr::with_tempdir({
    result <- plot_barrier_habitat_interpatch_dist(
      barrier = small_barrier,
      buffered = buffered,
      habitat = small_habitat,
      interpatch_distance = 10,
      species = "Blue Tongue Lizard"
    )
    expect_true(file.exists(result))
    expect_snapshot(unname(result))
  })
})
