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
#' @param col_barrier Character. Color for barrier layer.
#' @param col_interpatch_dist Character. Color for interpatch distance zone.
#' @param col_habitat Character. Color for habitat patches.
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
  col_barrier,
  col_interpatch_dist,
  col_habitat,
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

#' Display plots in tabs
#'
#' Helper function to display a list of plots with tab headers in R Markdown
#' documents.
#'
#' @param the_list Named list. List of plot objects.
#' @param message Character. Prefix message for each tab heading.
#'
#' @returns Invisible NULL. Prints plots with markdown headers.
#' @examples
#' plots <- list("100m" = ggplot2::ggplot(), "200m" = ggplot2::ggplot())
#' show_tabs(plots, message = "interpatch distance")
#' @noRd
#' @note internal
show_tabs <- function(the_list, message = NULL) {
  for (iplot in names(the_list)) {
    cat(sprintf("## %s %s\n", message, iplot))
    print(the_list[[iplot]])
    cat("\n\n")
  }
}

#' Display images in tabs
#'
#' Helper function to display a list of image paths with tab headers in R
#' Markdown documents.
#'
#' @param images Named character vector. Paths to image files.
#' @param message Character. Prefix message for each tab heading.
#'
#' @returns Invisible NULL. Includes images with markdown headers.
#' @examples
#' \dontrun{
#' # Typically used inside a knitr/quarto document
#' image_paths <- c("100m" = "plot-100m.png", "200m" = "plot-200m.png")
#' show_image_tabs(image_paths, message = "interpatch distance")
#' }
#' @noRd
#' @note internal
show_image_tabs <- function(images, message = NULL) {
  for (iplot in names(images)) {
    cat(sprintf("## %s %s\n", message, iplot))
    knitr::include_graphics(images[[iplot]])
    cat("\n\n")
  }
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
