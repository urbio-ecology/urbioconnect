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
  col_paper = NA
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
    ggplot2::theme_sub_plot(
      title = marquee::element_marquee()
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
#' Creates faceted line plots showing how connectivity metrics change with
#' different interpatch distances. This works best when you have multiple
#' interpatch distances, otherwise it will just be a plot with one point.
#'
#' @param results_connect_habitat Data frame. Connectivity summary results with
#'   columns for species, interpatch distance, and various metrics.
#'
#' @returns A ggplot2 object with faceted plots of connectivity metrics.
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
#' @export
plot_connectivity <- function(results_connect_habitat) {
  geo_cols <- scico::scico(n = 6, palette = "bukavu") |> as.list()

  names(geo_cols) <- c(
    "dark_blue",
    "mid_blue",
    "light_blue",
    "dark_green",
    "tan",
    "offwhite"
  )

  results_for_plot <- results_connect_habitat |>
    dplyr::select(
      species:patch_area_total_ha,
      -effective_mesh_ha
    ) |>
    tidyr::pivot_longer(
      cols = -c(species, interpatch_distance)
    )

  ggplot2::ggplot(
    data = results_for_plot,
    ggplot2::aes(
      x = interpatch_distance,
      y = value
    )
  ) +
    ggplot2::geom_point() +
    ggplot2::geom_line(colour = geo_cols$dark_green) +
    ggplot2::facet_wrap(
      ~name,
      scales = "free",
      ncol = 2,
      labeller = ggplot2::labeller(name = to_sentence)
    ) +
    ggplot2::scale_x_continuous(
      breaks = results_connect_habitat$interpatch_distance,
      labels = \(x) glue::glue("{x}m")
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
