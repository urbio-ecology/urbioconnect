#' Convert colour name to hexadecimal
#'
#' @param color_name Character. Colour name recognised by R.
#'
#' @returns Character. Hexadecimal colour code.
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
#' @param habitat Terra SpatRaster. Original habitat layer. Habitat is any cell
#'   that is neither `NA` nor `0`.
#' @param interpatch_distance Numeric. The interpatch distance, in metres,
#'   that `buffered` was made for. Used only to label the plot.
#' @param species Character. Species name for plot title.
#' @param col_barrier Character. Colour for barrier layer. Defaults to the
#'   package palette, so a map drawn here matches the app, the downloads and
#'   the report. See [urbio_colours()].
#' @param col_interpatch_dist Character. Colour for interpatch distance zone.
#' @param col_habitat Character. Colour for habitat patches.
#' @param col_paper Character. Background colour (default: "grey96").
#'
#' @returns A ggplot2 object.
#' @export
#' @examples
#' lizard_habitat <- example_habitat()
#' lizard_barrier <- example_barrier()
#' interpatch_distance <- 20
#'
#' # the buffer habitat_connectivity() makes
#' lizard_full <- habitat_connectivity_full(
#'   habitat = lizard_habitat,
#'   barrier = lizard_barrier,
#'   interpatch_distance = interpatch_distance,
#'   verbose = FALSE
#' )
#'
#' lizard_map <- gg_barrier_habitat_interpatch_dist(
#'   barrier = lizard_barrier,
#'   buffered = lizard_full$buffered_habitat,
#'   habitat = lizard_habitat,
#'   interpatch_distance = interpatch_distance,
#'   species = "Blue Tongue Lizard",
#'   col_barrier = "black",
#'   col_interpatch_dist = "lightgreen",
#'   col_habitat = "seagreen"
#' )
#'
#' # add a north arrow and scale bar with ggspatial, if it is installed
#' if (requireNamespace("ggspatial", quietly = TRUE)) {
#'   lizard_map <- lizard_map +
#'     ggspatial::annotation_north_arrow(
#'       style = ggspatial::north_arrow_fancy_orienteering()
#'     ) +
#'     ggspatial::annotation_scale()
#' }
#'
#' lizard_map
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
  # First, reclassify your rasters to assign actual colour values
  barrier_coloured <- terra::subst(barrier, 1, col_barrier)
  interpatch_coloured <- terra::subst(buffered, 1, col_interpatch_dist)
  habitat_present <- terra::ifel(is_habitat(habitat), 1, NA)
  habitat_coloured <- terra::subst(habitat_present, 1, col_habitat)

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
#' @param layer A `SpatRaster`. In a habitat, any cell that is neither `NA`
#'   nor `0` is the layer; in a barrier, cells equal to 1 are. Everything else
#'   is background.
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
  in_layer <- if (kind == "habitat") is_habitat(layer) else layer == 1
  present <- terra::ifel(in_layer, 1, NA)

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
#' Visualises habitat patches coloured by their connected fragment ID.
#'
#' With `barrier`, the barrier is drawn in grey. With `buffered` as well, each
#' patch's connecting zone, the buffered habitat cut by the barrier that joins
#' it into one patch, is shaded a paler version of its colour. Buffer cut off
#' from all habitat joins no patch, so it is left blank.
#'
#' @param patch_id Terra SpatRaster with a layer named `patch_id`, such as the
#'   `patch_id_raster` from [habitat_connectivity_full()] or the result of
#'   [add_patch_area()].
#' @param interpatch_distance Numeric. The interpatch distance, in metres, the
#'   patches were found with. Used only to label the plot.
#' @param species Character. Species name (default: "Species").
#' @param n_cols Integer. Number of colours to cycle through (default: 7).
#' @param barrier Terra SpatRaster, optional. The barrier layer the patches
#'   were found with, 1 where there is a barrier.
#' @param buffered Terra SpatRaster, optional. Needs `barrier`. The buffered
#'   habitat the patches were found with, from [habitat_connectivity_full()].
#' @param directions Which neighbouring cells join, as in
#'   [habitat_connectivity()]: `4`, the default, or `8`. Used with `buffered`
#'   to find the zones, so give it the value the patches were found with.
#'
#' @returns A ggplot2 object showing patches with distinct colours.
#' @export
#' @examples
#' lizard_barrier <- example_barrier()
#' interpatch_distance <- 20
#'
#' # the patches habitat_connectivity() finds, and the buffer it finds them with
#' lizard_full <- habitat_connectivity_full(
#'   habitat = example_habitat(),
#'   barrier = lizard_barrier,
#'   interpatch_distance = interpatch_distance,
#'   verbose = FALSE
#' )
#'
#' plot_patches(
#'   patch_id = lizard_full$patch_id_raster,
#'   interpatch_distance = interpatch_distance
#' )
#'
#' # with the barrier
#' plot_patches(
#'   lizard_full$patch_id_raster,
#'   interpatch_distance,
#'   barrier = lizard_barrier
#' )
#'
#' # with the barrier, and each patch's connecting zone shaded
#' lizard_patch_map <- plot_patches(
#'   lizard_full$patch_id_raster,
#'   interpatch_distance,
#'   barrier = lizard_barrier,
#'   buffered = lizard_full$buffered_habitat
#' )
#'
#' # add a north arrow and scale bar with ggspatial, if it is installed
#' if (requireNamespace("ggspatial", quietly = TRUE)) {
#'   lizard_patch_map <- lizard_patch_map +
#'     ggspatial::annotation_north_arrow(
#'       style = ggspatial::north_arrow_fancy_orienteering()
#'     ) +
#'     ggspatial::annotation_scale()
#' }
#'
#' lizard_patch_map
plot_patches <- function(
  patch_id,
  interpatch_distance,
  species = "Species",
  n_cols = 7,
  barrier = NULL,
  buffered = NULL,
  directions = 4
) {
  check_directions(directions)

  # the barrier is drawn whenever it is given; the zones also need the buffered
  # habitat, which the barrier cuts into one zone per patch
  draw_barrier <- !is.null(barrier)
  shade_zones <- !is.null(buffered)

  if (shade_zones && !draw_barrier) {
    cli::cli_abort(
      "{.arg buffered} needs {.arg barrier}, which cuts the buffer into zones."
    )
  }

  raster_patches <- patch_id$patch_id |> terra::values()

  unique_vals <- unique(raster_patches[!is.na(raster_patches)])
  n_patches <- length(unique_vals)

  my_colours <- colorspace::qualitative_hcl(n = n_cols)

  # assign colours cyclically
  colour_indices <- ((unique_vals - 1) %% n_cols) + 1
  colour_map <- my_colours[colour_indices]
  names(colour_map) <- unique_vals

  # one layer, so it draws as one image: a habitat cell holds its patch id, a
  # zone cell the id negated, and a barrier cell 0
  cells <- patch_id$patch_id
  if (shade_zones) {
    mask <- create_barrier_mask(barrier)
    fragments <- buffered |>
      fragment_habitat(mask) |>
      terra::patches(directions = directions)
    fragments <- align_to(fragments, cells)
    # ids are renumbered, so find each fragment's patch from the habitat in it.
    # Buffer that a barrier cuts off from all habitat is left unshaded.
    fragment_ids <- terra::values(fragments)[, 1]
    patch_ids <- terra::values(cells)[, 1]
    shared <- data.frame(fragment = fragment_ids, patch = patch_ids) |>
      stats::na.omit() |>
      unique()
    zone <- terra::subst(
      fragments,
      from = shared$fragment,
      to = shared$patch,
      others = NA
    )
    cells <- terra::cover(cells, -zone)
    zone_colours <- colorspace::lighten(colour_map, 0.65)
    names(zone_colours) <- -unique_vals
    colour_map <- c(colour_map, zone_colours)
  }
  if (draw_barrier) {
    barrier <- align_to(barrier, cells)
    cells <- terra::cover(terra::ifel(barrier == 1, 0, NA), cells)
    colour_map <- c(colour_map, "0" = "grey55")
  }

  ggplot2::ggplot() +
    tidyterra::geom_spatraster(data = terra::as.factor(cells)) +
    ggplot2::scale_fill_manual(values = colour_map, na.value = NA) +
    ggplot2::theme_minimal() +
    ggplot2::theme(legend.position = "none") +
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
        "# patches: {n_patches}\nInterpatch Distance size: {interpatch_distance}m"
      )
    ) +
    ggplot2::theme_sub_axis(
      text = ggplot2::element_blank(),
      ticks = ggplot2::element_blank()
    )
}


#' Plot connectivity metrics across interpatch distances
#'
#' Draws how the connectivity metrics change with the interpatch distance, a
#'   panel per metric, each on its own scale.
#'
#'   Given a `connectivity` object, it draws a point per distance joined by a
#'   line. A single distance is a single point.
#'
#'   Given a `compare_connectivity` object, it draws a bar for the baseline and
#'   for each scenario at every interpatch distance, side by side, so you can
#'   see where a scenario departs from the baseline and whether that holds
#'   across distances.
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
#' # 10 m cells, as the app uses, keep the example quick
#' today <- prepare_rasters(
#'   example_habitat(),
#'   example_barrier(),
#'   data_resolution = 10
#' )
#'
#' lizard_connectivity <- habitat_connectivity(
#'   habitat = today$habitat_raster,
#'   barrier = today$barrier_raster,
#'   species = "Blue-tongued Lizard",
#'   interpatch_distance = 80,
#'   verbose = FALSE
#' )
#'
#' lizard_connectivity
#'
#' plot_connectivity(lizard_connectivity)
#'
#' # multiple distances
#' distances <- c(40, 80, 160)
#'
#' # a row per interpatch distance
#' lizard_connectivities <- purrr::map(
#'   distances,
#'   function(distance) {
#'     habitat_connectivity(
#'       habitat = today$habitat_raster,
#'       barrier = today$barrier_raster,
#'       species = "Blue-tongued Lizard",
#'       interpatch_distance = distance,
#'       verbose = FALSE
#'     )
#'   }
#' ) |>
#'   purrr::list_rbind()
#'
#' plot_connectivity(lizard_connectivities)
#'
#' # a new road through the habitat against the landscape today
#' new_road <- onto_grid(
#'   example_barrier_scenario(),
#'   today$barrier_raster,
#'   background = 0
#' )
#'
#' lizard_road_comparison <- habitat_connectivity_comparison(
#'   habitat_baseline = today$habitat_raster,
#'   barrier_baseline = today$barrier_raster,
#'   species = "Blue-tongued Lizard",
#'   interpatch_distance = distances,
#'   barrier_scenario = new_road,
#'   scenario_name = "New road",
#'   verbose = FALSE
#' )
#'
#' lizard_road_comparison
#'
#' plot_connectivity(lizard_road_comparison)
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

  over_distance <- ggplot2::ggplot(
    data = plot_data,
    ggplot2::aes(
      x = .data$interpatch_distance,
      y = .data$value
    )
  ) +
    ggplot2::geom_point() +
    distance_line(x$interpatch_distance, colour = series_colours()[[1]]) +
    ggplot2::scale_x_continuous(
      breaks = unique(x$interpatch_distance),
      labels = \(x) glue::glue("{x}m")
    )

  connectivity_plot_layout(over_distance)
}

#' @rdname plot_connectivity
#' @export
plot_connectivity.compare_connectivity <- function(x, ...) {
  rlang::check_dots_empty()

  scenarios <- unique(scenario_labels(x$scenario_name))
  check_scenario_not_baseline(scenarios)
  check_scenario_count(scenarios)

  plot_data <- comparison_plot_data(x)
  colours <- series_colours()[seq_len(nlevels(plot_data$series))]

  bars <- ggplot2::ggplot(
    data = plot_data,
    ggplot2::aes(
      x = factor(.data$interpatch_distance),
      y = .data$value,
      fill = .data$series
    )
  ) +
    ggplot2::geom_col(position = ggplot2::position_dodge()) +
    ggplot2::scale_x_discrete(labels = \(x) glue::glue("{x}m")) +
    ggplot2::scale_fill_manual(values = colours, name = NULL)

  connectivity_plot_layout(bars) +
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

  bars <- dplyr::bind_rows(baseline, scenarios) |>
    dplyr::select(
      "series",
      "interpatch_distance",
      dplyr::all_of(plotted_metrics())
    ) |>
    dplyr::distinct()

  check_one_bar_per_distance(bars, call = call)

  bars |>
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
  baseline <- scico::scico(n = 6, palette = "bukavu")[[4]]

  c(baseline, "#0072B2", "#D55E00", "#CC79A7", "#E69F00", "#56B4E9")
}

#' @noRd
scenario_labels <- function(scenario_name) {
  dplyr::coalesce(scenario_name, "Scenario")
}

#' Checked on the names rather than the drawn bars: a scenario called
#' "Baseline" with the baseline's values would be dropped as a duplicate
#'
#' @noRd
check_scenario_not_baseline <- function(
  scenarios,
  call = rlang::caller_env()
) {
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

  invisible(scenarios)
}

#' One colour each, after the baseline's
#'
#' @noRd
check_scenario_count <- function(scenarios, call = rlang::caller_env()) {
  most <- length(series_colours()) - 1

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

  invisible(scenarios)
}

#' Two scenarios sharing a label, or comparisons against different
#' baselines, would otherwise draw one bar over the other, hiding the shorter
#'
#' @noRd
check_one_bar_per_distance <- function(bars, call = rlang::caller_env()) {
  clashes <- bars |>
    dplyr::count(.data$series, .data$interpatch_distance) |>
    dplyr::filter(.data$n > 1)

  if (nrow(clashes) > 0) {
    cli::cli_abort(
      c(
        "Can't draw {.val {unique(clashes$series)}} as one bar per interpatch
         distance: more than one comparison gives a value at the same
         distance.",
        "i" = "Give each scenario its own {.field scenario_name}, and compare
               every scenario against the same baseline."
      ),
      call = call
    )
  }

  invisible(bars)
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

#' What both plots share: the panels, the y axis and the theme
#'
#' @noRd
connectivity_plot_layout <- function(plot) {
  plot +
    ggplot2::facet_wrap(
      ~name,
      scales = "free",
      ncol = 2,
      labeller = ggplot2::labeller(name = to_sentence)
    ) +
    ggplot2::scale_y_continuous(
      labels = scales::label_number(scale_cut = scales::cut_short_scale())
    ) +
    ggplot2::labs(
      x = "Interpatch distance (m)"
    ) +
    ggplot2::theme_bw() +
    ggplot2::theme_sub_panel(
      border = ggplot2::element_rect(
        colour = "grey85",
        fill = NA
      )
    ) +
    ggplot2::theme(
      text = ggplot2::element_text(size = 14)
    )
}
