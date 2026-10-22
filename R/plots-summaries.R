#' Convert color name to hexadecimal
#'
#' @param color_name Character. Color name recognized by R.
#'
#' @returns Character. Hexadecimal color code.
#'
#' @examples
#' col2hex("forestgreen")
#' col2hex("blue")
#' @export
col2hex <- function(color_name) {
  grDevices::rgb(t(grDevices::col2rgb(color_name)), maxColorValue = 255)
}

#' Plot barrier, habitat, and interpatch distance layers
#'
#' Creates a visualisation of habitat, interpatch distance zone, and barriers
#' using terra rasters.
#'
#' @param barrier Terra SpatRaster. Barrier layer (e.g., roads).
#' @param buffered Terra SpatRaster. Buffered habitat layer.
#' @param habitat Terra SpatRaster. Original habitat layer.
#' @param interpatch_distance Numeric. The distance (in meters) where habitat
#'   patches are considered connected. E.g., if set to 500, patches 498m apart
#'   are connected, those 501m apart are not connected. This is passed
#'   internally to a spatial operation known as "buffering", where this
#'   distance is used as a radius from the edge of the habitat zone. This means
#'   the specified `interpatch_distance` is halved exactly. So an interpatch
#'   distance of 500 will be converted to 250.
#' @param species Character. Species name for plot title.
#' @param col_barrier Character. Colour for barrier layer. Defaults to the
#'   package palette, so a map drawn here matches the app, the downloads and
#'   the report. See [urbio_colours()].
#' @param col_interpatch_dist Character. Colour for interpatch distance zone.
#' @param col_habitat Character. Colour for habitat patches.
#' @param col_paper Character. Background color (default: "white").
#'
#' @returns A ggplot2 object.
#' @export
#' @examples
#' lizard_habitat <- example_habitat()
#' lizard_barrier <- example_barrier()
#' lizard_buffered <- habitat_buffer(lizard_habitat, buffer_radius =10)
#' gg_bar_hab_buf <- gg_barrier_habitat_interpatch_dist(
#'   barrier = lizard_barrier,
#'   buffered = lizard_buffered,
#'   habitat = lizard_habitat,
#'   interpatch_distance = 10,
#'   species = "Blue Tongue Lizard",
#'   col_barrier = "black",
#'   col_interpatch_dist = "lightgreen",
#'   col_habitat = "seagreen"
#' )
#' gg_bar_hab_buf
#'
#' # add north arrow and scale bar with ggspatial
#' library(ggspatial)
#' library(tidyterra)
#' gg_bar_hab_buf +
#'  annotation_north_arrow(
#'    style = north_arrow_fancy_orienteering()
#'   ) +
#'   annotation_scale()
gg_barrier_habitat_interpatch_dist <- function(
  barrier,
  buffered,
  habitat,
  interpatch_distance,
  species,
  col_barrier = urbio_colours()$barrier,
  col_interpatch_dist = urbio_colours()$interpatch_distance,
  col_habitat = urbio_colours()$habitat,
  col_paper = "grey96"
) {
  # First, reclassify your rasters to assign actual color values
  barrier_coloured <- terra::subst(barrier, 1, col_barrier)
  interpatch_coloured <- terra::subst(buffered, 1, col_interpatch_dist)
  habitat_coloured <- terra::subst(habitat, 1, col_habitat)

  # Now plot them in layers (bottom to top)
  ggplot2::ggplot() +
    tidyterra::geom_spatraster(data = interpatch_coloured) +
    tidyterra::geom_spatraster(data = barrier_coloured) +
    tidyterra::geom_spatraster(data = habitat_coloured) +
    ggplot2::theme_minimal(paper = col_paper) +
    ggplot2::scale_fill_identity(
      name = "",
      guide = "legend",
      labels = c(
        stats::setNames("Habitat", col_habitat),
        stats::setNames("Interpatch", col_interpatch_dist),
        stats::setNames("Barrier", col_barrier)
      ),
      breaks = c(
        col_habitat,
        col_interpatch_dist,
        col_barrier
      ),
      na.value = NA,
      na.translate = FALSE
    ) +
    ggplot2::labs(
      title = glue::glue("{species} Habitat"),
      subtitle = glue::glue(
        "With a {interpatch_distance}m interpatch distance, and barrier shown"
      )
    ) +
    ggplot2::theme_sub_axis(
      text = ggplot2::element_blank(),
      ticks = ggplot2::element_blank()
    ) +
    ggplot2::theme_sub_panel(
      grid.major = ggplot2::element_blank(),
      grid.minor = ggplot2::element_blank()
    )
}

#' Plot one layer on its own
#'
#' The habitat or the barrier by itself, rather than combined as
#' [gg_barrier_habitat_interpatch_dist()] draws them. For looking at what went
#' into an analysis, and at a scenario layer against the layer it replaces.
#'
#' `kind` picks the colours, so a layer looks the same here as it does in the
#' combined map. A barrier is white there, read as cuts through the interpatch
#' zone, so a barrier drawn alone is white on that same green: white on white
#' would be nothing at all.
#'
#' @param layer A `SpatRaster`. Cells equal to 1 are the layer; everything
#'   else is background, whether it is 0 or `NA`.
#' @param kind Which layer this is, `"habitat"` or `"barrier"`. Decides the
#'   fill and the background.
#' @param title Plot title. Defaults to `kind`, sentence case.
#'
#' @returns A ggplot.
#' @seealso [gg_barrier_habitat_interpatch_dist()] for the combined map, and
#'   [urbio_colours()] for the palette this draws from.
#' @export
#'
#' @examples
#' gg_layer(example_habitat(), "habitat")
#'
#' gg_layer(example_barrier(), "barrier")
#'
#' # a scenario layer, titled for what it changes
#' gg_layer(example_barrier(), "barrier", title = "Scenario: new roads")
gg_layer <- function(layer, kind = c("habitat", "barrier"), title = NULL) {
  kind <- rlang::arg_match(kind)

  colours <- urbio_colours()
  fill <- colours[[kind]]
  paper <- if (kind == "barrier") colours$interpatch_distance else NA
  label <- to_sentence(kind)

  # anything that isn't the layer is background, so 0 and NA read alike
  present <- terra::ifel(layer == 1, 1, NA)

  ggplot2::ggplot() +
    tidyterra::geom_spatraster(data = terra::subst(present, 1, fill)) +
    ggplot2::theme_minimal(paper = paper) +
    ggplot2::scale_fill_identity(
      name = "",
      guide = "legend",
      labels = stats::setNames(label, fill),
      breaks = fill,
      na.value = NA,
      na.translate = FALSE
    ) +
    ggplot2::labs(title = title %||% label) +
    ggplot2::theme_sub_axis(
      text = ggplot2::element_blank(),
      ticks = ggplot2::element_blank()
    ) +
    ggplot2::theme_sub_panel(
      grid.major = ggplot2::element_blank(),
      grid.minor = ggplot2::element_blank()
    )
}

#' Convert snake_case to sentence case
#'
#' @param x Character vector. Text in snake_case format.
#'
#' @returns Character vector. Text converted to sentence case.
#' @examples
#' to_sentence("prob_connectedness")
#' to_sentence(c("n_patches", "patch_area_mean", "effective_mesh_ha"))
#' @noRd
#' @note internal
to_sentence <- function(x) {
  x |>
    stringr::str_replace_all("_", " ") |>
    stringr::str_to_sentence()
}

#' Plot connected habitat patches
#'
#' Visualizes habitat patches colored by their connected fragment ID.
#'
#' @param patch_id Terra SpatRaster. Raster with patch IDs.
#' @param interpatch_distance Numeric. The distance (in meters) where habitat
#'   patches are considered connected. E.g., if set to 500, patches 498m apart
#'   are connected, those 501m apart are not connected. This is passed
#'   internally to a spatial operation known as "buffering", where this
#'   distance is used as a radius from the edge of the habitat zone. This means
#'   the specified `interpatch_distance` is halved exactly. So an interpatch
#'   distance of 500 will be converted to 250.
#' @param species Character. Species name (default: "Species").
#' @param n_cols Integer. Number of colors to cycle through (default: 7).
#'
#' @returns A ggplot2 object showing patches with distinct colors.
#' @export
#' @examples
#' lizard_habitat <- example_habitat()
#' lizard_barrier <- example_barrier()
#' interpatch_distance <- 20
#' buffer_radius <- interpatch_distance / 2
#' buffered_habitat <- habitat_buffer(lizard_habitat, buffer_radius)
#' barrier_mask <- create_barrier_mask(lizard_barrier)
#' fragmented <- fragment_habitat(buffered_habitat, barrier_mask)
#' remaining_habitat <- drop_habitat_under_barrier(
#'   habitat = lizard_habitat,
#'   barrier = lizard_barrier
#'   )
#' fragment_patches <- assign_patches_to_fragments(
#'   remaining_habitat = remaining_habitat,
#'   fragment = fragmented
#'   ) |> add_patch_area()
#'
#' plot_patches(fragment_patches, interpatch_distance = interpatch_distance)
#'
#' #' add north arrow and scale bar with ggspatial
#' library(ggspatial)
#' library(tidyterra)
#' plot_patches(fragment_patches, interpatch_distance = interpatch_distance) +
#'  annotation_north_arrow(
#'    style = north_arrow_fancy_orienteering()
#'   ) +
#'   annotation_scale()
plot_patches <- function(
  patch_id,
  interpatch_distance,
  species = "Species",
  n_cols = 7
) {
  raster_patches <- patch_id$patch_id |> terra::values()

  n_patches <- patch_id$patch_id |> terra::values() |> unique() |> nrow()

  my_colours <- colorspace::qualitative_hcl(n = n_cols)

  unique_vals <- unique(raster_patches)
  unique_vals <- unique_vals[!is.na(unique_vals)]

  # assign colours cyclically
  colour_indices <- ((unique_vals - 1) %% n_cols) + 1
  colour_map <- my_colours[colour_indices]
  names(colour_map) <- unique_vals

  patch_raster <- terra::as.factor(patch_id$patch_id)

  ggplot2::ggplot() +
    tidyterra::geom_spatraster(data = patch_raster) +
    ggplot2::scale_fill_manual(values = colour_map, na.value = NA) +
    ggplot2::theme_minimal() +
    ggplot2::theme(legend.position = "none", aspect.ratio = 1) +
    ggplot2::theme_sub_panel(
      border = ggplot2::element_rect(
        colour = "grey85"
      ),
      grid.major = ggplot2::element_blank(),
      grid.minor = ggplot2::element_blank()
    ) +
    ggplot2::labs(
      title = glue::glue(
        "Patches of {species} habitat"
      ),
      subtitle = glue::glue(
        "# patches: {n_patches}\nInterpatch Distance size:\\
        {interpatch_distance}m\n{n_cols} colours"
      )
    ) +
    ggplot2::theme_sub_axis(
      text = ggplot2::element_blank(),
      ticks = ggplot2::element_blank()
    )
}


#' Plot connectivity metrics across interpatch distances
#'
#' Draws how the connectivity metrics change with the interpatch distance: a
#'   panel per metric, each on its own scale, with a point per distance joined
#'   by a line. A single distance is a single point.
#'
#'   Given a `connectivity` object, it draws one line. Given a
#'   `compare_connectivity` object, it draws the baseline and each scenario as
#'   a line of its own, in the same panels, so you can see where a scenario
#'   departs from the baseline and whether that holds across distances.
#'
#'   The four metrics are `n_patches`, `prob_connectedness`, `patch_area_mean`
#'   and `patch_area_total_ha`. `effective_mesh_ha` is left out because it is
#'   `prob_connectedness` multiplied by the habitat area, which is the same at
#'   every distance, so its panel would have the same shape.
#'
#'   Values are drawn as they are. In a comparison, `prob_connectedness` is
#'   measured against the baseline's habitat area, so a scenario that adds
#'   habitat can score above 1, and the plot shows that rather than capping it.
#'
#' @param x A `connectivity` object, from [habitat_connectivity()] or
#'   [summarise_connectivity()], with a row per interpatch distance. Or a
#'   `compare_connectivity` object, from [compare_connectivity()],
#'   [compare_scenarios()], [habitat_connectivity_comparison()] or
#'   [habitat_connectivity_scenarios()], with up to five scenarios. A scenario
#'   is labelled by its `scenario_name`, or "Scenario" when it has none.
#' @param ... Not used.
#'
#' @returns A ggplot2 object with a panel per connectivity metric.
#' @seealso [connectivity_display()] for a comparison as a table.
#' @examples
#' lizard_habitat <- example_habitat()
#' lizard_barrier <- example_barrier()
#' results <- purrr::map(
#'   c(10, 20),
#'   function(d) {
#'     full <- habitat_connectivity_full(lizard_habitat, lizard_barrier,
#'       interpatch_distance = d, verbose = FALSE)
#'     summarise_connectivity(
#'       connectivity = full$areas_connected$area,
#'       interpatch_distance = d,
#'       data_resolution = 10,
#'       species = "Blue-tongued Lizard"
#'     )
#'   }
#' ) |> purrr::list_rbind()
#' plot_connectivity(results)
#'
#' # a scenario against its baseline
#' baseline <- summarise_connectivity(lizard_areas_connected)
#' compare_scenarios(
#'   baseline = baseline,
#'   scenarios = list(
#'     "Bentley Project" = summarise_connectivity(lizard_areas_connected[-1, ]),
#'     "Barrier upgrade" = summarise_connectivity(
#'       lizard_areas_connected[-(1:5), ]
#'     )
#'   )
#' ) |>
#'   plot_connectivity()
#' @export
plot_connectivity <- function(x, ...) {
  UseMethod("plot_connectivity")
}

#' @rdname plot_connectivity
#' @export
plot_connectivity.default <- function(x, ...) {
  rlang::check_dots_empty()

  plot_data <- x |>
    dplyr::select("interpatch_distance", dplyr::all_of(plotted_metrics())) |>
    tidyr::pivot_longer(cols = -"interpatch_distance")

  ggplot2::ggplot(
    data = plot_data,
    ggplot2::aes(
      x = .data$interpatch_distance,
      y = .data$value
    )
  ) +
    ggplot2::geom_point() +
    distance_line(x$interpatch_distance, colour = series_colours()[[1]]) +
    connectivity_plot_layout(x$interpatch_distance)
}

#' @rdname plot_connectivity
#' @export
plot_connectivity.compare_connectivity <- function(x, ...) {
  rlang::check_dots_empty()

  check_plot_scenarios(x)

  plot_data <- comparison_plot_data(x)
  series <- levels(plot_data$series)

  ggplot2::ggplot(
    data = plot_data,
    ggplot2::aes(
      x = .data$interpatch_distance,
      y = .data$value,
      colour = .data$series,
      shape = .data$series
    )
  ) +
    ggplot2::geom_point(size = 2) +
    distance_line(x$interpatch_distance) +
    # shape as well as colour, so the lines part without colour vision
    ggplot2::scale_colour_manual(
      values = series_colours()[seq_along(series)],
      name = NULL
    ) +
    ggplot2::scale_shape_manual(
      values = series_shapes()[seq_along(series)],
      name = NULL
    ) +
    connectivity_plot_layout(x$interpatch_distance) +
    ggplot2::theme(legend.position = "bottom")
}

#' @noRd
plotted_metrics <- function() {
  c("n_patches", "prob_connectedness", "patch_area_mean", "patch_area_total_ha")
}

#' One row per series, distance and metric
#'
#' Each scenario carries its own copy of the baseline, so the baseline is
#' kept once. It comes first, so it takes the first colour.
#'
#' @noRd
comparison_plot_data <- function(x, call = rlang::caller_env()) {
  rows <- tibble::as_tibble(x)

  baseline <- rows |>
    dplyr::filter(.data$measure == "baseline") |>
    dplyr::mutate(series = "Baseline")

  scenarios <- rows |>
    dplyr::filter(.data$measure == "scenario") |>
    dplyr::mutate(series = scenario_labels(.data$scenario_name))

  lines <- dplyr::bind_rows(baseline, scenarios) |>
    dplyr::select(
      "series",
      "interpatch_distance",
      dplyr::all_of(plotted_metrics())
    ) |>
    dplyr::distinct()

  check_one_value_per_point(lines, call = call)

  lines |>
    dplyr::mutate(
      series = factor(.data$series, levels = unique(.data$series))
    ) |>
    tidyr::pivot_longer(
      cols = dplyr::all_of(plotted_metrics()),
      names_to = "name",
      values_to = "value"
    )
}

#' The baseline's colour, then one per scenario
#'
#' The baseline keeps the over-distance plot's green. The scenarios take
#' Okabe-Ito's colour-blind-safe hues, less its green, too close to the
#' baseline's, and its yellow, too pale to see on white.
#'
#' @noRd
series_colours <- function() {
  c(
    scico::scico(n = 6, palette = "bukavu")[[4]],
    "#0072B2",
    "#D55E00",
    "#CC79A7",
    "#E69F00",
    "#56B4E9"
  )
}

#' Filled, so a point reads at the same weight as its colour
#'
#' @noRd
series_shapes <- function() {
  c(16, 17, 15, 18, 8, 4)
}

#' @noRd
scenario_labels <- function(scenario_name) {
  dplyr::coalesce(scenario_name, "Scenario")
}

#' Checked on the names rather than the drawn lines: a scenario called
#' "Baseline" with the baseline's values would be dropped as a duplicate
#'
#' @noRd
check_plot_scenarios <- function(x, call = rlang::caller_env()) {
  scenarios <- unique(scenario_labels(x$scenario_name))
  most <- min(length(series_colours()), length(series_shapes())) - 1
  baseline <- scenarios[tolower(scenarios) == "baseline"]

  if (length(baseline) > 0) {
    cli::cli_abort(
      c(
        "A scenario can't be called {.val {baseline}}.",
        "i" = "The plot draws the baseline under that name. Rename the
               scenario in {.field scenario_name}."
      ),
      call = call
    )
  }

  if (length(scenarios) > most) {
    cli::cli_abort(
      c(
        "Can only plot up to {most} scenarios at once, not
         {length(scenarios)}.",
        "i" = "Plot fewer at a time, for example with
               {.code dplyr::filter(x, scenario_name %in% c(...))}."
      ),
      call = call
    )
  }

  invisible(x)
}

#' Two scenarios sharing a label, or comparisons against different
#' baselines, would otherwise draw as one line zigzagging between them
#'
#' @noRd
check_one_value_per_point <- function(lines, call = rlang::caller_env()) {
  clashes <- lines |>
    dplyr::count(.data$series, .data$interpatch_distance) |>
    dplyr::filter(.data$n > 1)

  if (nrow(clashes) > 0) {
    cli::cli_abort(
      c(
        "Can't draw {.val {unique(clashes$series)}} as one line each: more
         than one comparison gives a value at the same interpatch distance.",
        "i" = "Give each scenario its own {.field scenario_name}, and compare
               every scenario against the same baseline."
      ),
      call = call
    )
  }

  invisible(lines)
}

#' A line, unless there is a single distance to join
#'
#' A line of one point makes ggplot2 message when the plot is drawn.
#'
#' @noRd
distance_line <- function(distances, ...) {
  if (dplyr::n_distinct(distances) > 1) {
    ggplot2::geom_line(...)
  }
}

#' What both plots share: the panels, the axes and the theme
#'
#' @noRd
connectivity_plot_layout <- function(distances) {
  list(
    ggplot2::facet_wrap(
      ~name,
      scales = "free",
      ncol = 2,
      labeller = ggplot2::labeller(name = to_sentence)
    ),
    ggplot2::scale_x_continuous(
      breaks = unique(distances),
      labels = \(x) glue::glue("{x}m")
    ),
    ggplot2::scale_y_continuous(
      labels = scales::label_number(scale_cut = scales::cut_short_scale())
    ),
    ggplot2::labs(
      x = "Interpatch distance (m)"
    ),
    ggplot2::theme_bw(),
    ggplot2::theme_sub_panel(
      border = ggplot2::element_rect(
        colour = "grey85",
        fill = NA
      )
    ),
    ggplot2::theme(
      text = ggplot2::element_text(size = 14)
    )
  )
}
