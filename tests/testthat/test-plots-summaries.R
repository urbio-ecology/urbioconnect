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

# gg_layer --------------------------------------------------------------

test_that("gg_layer draws a barrier on the interpatch colour", {
  # a barrier is white, so alone on white paper it would be invisible. The
  # pairing lives in the function rather than in whatever calls it.
  built <- ggplot2::ggplot_build(gg_layer(example_barrier(), "barrier"))

  expect_equal(built$plot$labels$title, "Barrier")
  expect_equal(
    built$plot$theme$plot.background$fill,
    urbio_colours()$interpatch_distance
  )
})

test_that("gg_layer titles itself from the layer, or from what it is told", {
  expect_equal(
    ggplot2::ggplot_build(gg_layer(
      example_habitat(),
      "habitat"
    ))$plot$labels$title,
    "Habitat"
  )
  expect_equal(
    ggplot2::ggplot_build(
      gg_layer(example_barrier(), "barrier", title = "Scenario: barrier")
    )$plot$labels$title,
    "Scenario: barrier"
  )
})

test_that("gg_layer rejects a layer it has no colours for", {
  expect_snapshot(gg_layer(example_habitat(), "interpatch"), error = TRUE)
})

test_that("gg_layer renders correctly", {
  skip_on_ci()
  vdiffr::expect_doppelganger(
    "gg-layer-barrier",
    gg_layer(example_barrier(), "barrier")
  )
})

# plot_patches ----------------------------------------------------------

test_that("plot_patches returns a ggplot", {
  result <- plot_patches(
    patch_id_raster,
    interpatch_distance = interpatch_dist
  )
  expect_s3_class(result, "ggplot")
})

test_that("plot_patches counts the patches the summary counts", {
  summary <- summarise_connectivity(
    connectivity = aggregate_connected_patches(patch_id_raster)$area,
    interpatch_distance = interpatch_dist,
    data_resolution = 10,
    species = "Blue Tongue Lizard"
  )
  result <- plot_patches(patch_id_raster, interpatch_distance = interpatch_dist)

  expect_match(
    result$labels$subtitle,
    paste0("# patches: ", summary$n_patches, "\n"),
    fixed = TRUE
  )
})

test_that("plot_patches does not count NA or NaN cells as patches", {
  patches <- terra::rast(
    nrows = 3,
    ncols = 3,
    extent = terra::ext(0, 30, 0, 30),
    crs = terra::crs(lizard_habitat),
    vals = c(1, 1, NA, NaN, 2, 2, NA, 4, 4)
  )
  result <- plot_patches(add_patch_area(patches), interpatch_distance = 10)

  expect_match(result$labels$subtitle, "# patches: 3\n", fixed = TRUE)
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

test_that("plot_connectivity draws a comparison's baseline once, beside each scenario", {
  comparison <- scenario_test_comparison()
  drawn <- plot_connectivity(comparison)$data

  expect_snapshot(levels(drawn$series))

  # every scenario carries its own copy of the baseline rows
  expect_equal(nrow(drawn), 3 * 2 * 4)

  expect_equal(
    drawn$value[
      drawn$series == "Barrier upgrade" & drawn$name == "n_patches"
    ],
    comparison$n_patches[
      comparison$scenario_name == "Barrier upgrade" &
        comparison$measure == "scenario"
    ]
  )
})

test_that("plot_connectivity names an unnamed scenario", {
  drawn <- plot_connectivity(test_comparison())$data

  expect_snapshot(levels(drawn$series))
})

test_that("plot_connectivity draws a P(connected) above 1 as it is", {
  comparison <- pc_above_one_comparison()
  measured <- comparison$measure %in% c("baseline", "scenario")

  # if P(connected) stops being able to exceed 1, this plot needs rethinking
  expect_gt(
    comparison$prob_connectedness[comparison$measure == "scenario"],
    1
  )

  # a value outside the scale's limits would be dropped from the built layer
  built <- ggplot2::ggplot_build(plot_connectivity(comparison))
  points <- dplyr::left_join(
    built$data[[1]],
    built$layout$layout,
    by = "PANEL"
  )

  expect_setequal(
    points$y[points$name == "prob_connectedness"],
    comparison$prob_connectedness[measured]
  )
})

test_that("plot_connectivity at one distance draws its points quietly", {
  plot <- plot_connectivity(pc_above_one_comparison())

  expect_no_message(ggplot2::ggplot_build(plot))
  expect_length(plot$layers, 1)
})

test_that("plot_connectivity refuses scenarios it can't tell apart", {
  baseline <- summarise_connectivity(lizard_areas_connected)
  scenario <- summarise_connectivity(lizard_areas_connected[-1, ])

  expect_snapshot(
    plot_connectivity(
      compare_scenarios(baseline, list(Baseline = scenario))
    ),
    error = TRUE
  )
  expect_snapshot(
    plot_connectivity(
      compare_scenarios(
        baseline,
        rlang::set_names(rep(list(scenario), 6), LETTERS[1:6])
      )
    ),
    error = TRUE
  )
})

test_that("plot_connectivity renders a comparison correctly", {
  skip_on_ci()
  vdiffr::expect_doppelganger(
    "plot-connectivity-comparison",
    plot_connectivity(lizard_road_comparison())
  )

  # several scenarios, and a single distance, which draws no line
  vdiffr::expect_doppelganger(
    "plot-connectivity-comparison-one-distance",
    plot_connectivity(compare_scenarios(
      baseline = summarise_connectivity(lizard_areas_connected),
      scenarios = list(
        "Bentley Project" = summarise_connectivity(
          lizard_areas_connected[-1, ]
        ),
        "Barrier upgrade" = summarise_connectivity(
          lizard_areas_connected[-(1:5), ]
        )
      )
    ))
  )
})
