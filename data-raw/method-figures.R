# The seven step-by-step figures on the app's Before you start page: the whole
# lizard example, a small part of it, then the whole again. Their captions are
# in ui.R. Re-run
# from the package root, with the package loaded, after changing them:
#   Rscript -e 'devtools::load_all(); source("data-raw/method-figures.R")'
library(ggplot2)
library(terra)

data_resolution <- 10
distance <- 100

layers <- prepare_rasters(
  example_habitat(),
  example_barrier(),
  data_resolution = data_resolution
)
habitat <- layers$habitat_raster
barrier <- layers$barrier_raster
steps <- habitat_connectivity_full(habitat, barrier, distance, verbose = FALSE)

# picked by eye: a road between two patches that would otherwise join
zoom <- ext(
  xmin(habitat) + c(500, 740),
  ymin(habitat) + c(1100, 1340)
)

colours <- c(
  habitat = urbio_colours()$habitat,
  buffer = urbio_colours()$interpatch_distance,
  barrier = "grey40"
)

# the cells of one layer that are 1, as tiles
cells <- function(layer, where = zoom) {
  d <- as.data.frame(crop(layer, where), xy = TRUE, na.rm = TRUE)
  d[d[[3]] == 1, c("x", "y")]
}

hab <- cells(steps$remaining_habitat)
buf <- cells(steps$buffered_habitat)
road <- cells(barrier)
cut <- cells(!is.na(steps$barrier_mask) & steps$buffered_habitat == 1)

# each piece of the cut grown area is one patch, numbered as the habitat in it
pieces <- patches(fragment_habitat(steps$buffered_habitat, steps$barrier_mask))
by_patch <- function(layer, where = zoom) {
  d <- as.data.frame(crop(layer, where), xy = TRUE, na.rm = TRUE)
  names(d)[3] <- "patch_id"
  d$patch_id <- factor(d$patch_id)
  d
}
grown <- by_patch(pieces)
patches <- by_patch(steps$patch_id_raster$patch_id)

# the square's two patches, as far as they reach across the whole map
whole <- ext(example_habitat())
reach <- by_patch(steps$patch_id_raster$patch_id, whole)
reach <- droplevels(reach[reach$patch_id %in% levels(patches$patch_id), ])

# two from plot_patches()'s palette; its own pick for these ids is two teals
patch_colours <- scale_fill_manual(
  values = rlang::set_names(
    colorspace::qualitative_hcl(7)[c(6, 2)],
    levels(patches$patch_id)
  )
)

map_plot <- function(..., where = zoom) {
  ggplot(mapping = aes(x, y)) +
    list(...) +
    coord_equal(
      expand = FALSE,
      xlim = c(where$xmin, where$xmax),
      ylim = c(where$ymin, where$ymax)
    ) +
    theme_void() +
    theme(
      panel.background = element_rect(fill = "grey96", colour = "grey70"),
      legend.position = "none"
    )
}

# the whole map with the square outlined, and anything else drawn over it
whole_map <- function(...) {
  map_plot(
    geom_tile(data = cells(barrier, whole), fill = colours[["barrier"]]),
    geom_tile(
      data = cells(steps$remaining_habitat, whole),
      fill = colours[["habitat"]]
    ),
    ...,
    annotate(
      "rect",
      xmin = zoom$xmin,
      xmax = zoom$xmax,
      ymin = zoom$ymin,
      ymax = zoom$ymax,
      fill = NA,
      colour = "black",
      linewidth = 0.6
    ),
    where = whole
  )
}

figures <- list(
  whole_map(),
  map_plot(
    geom_tile(data = road, fill = colours[["barrier"]]),
    geom_tile(data = hab, fill = colours[["habitat"]])
  ),
  map_plot(
    geom_tile(data = buf, fill = colours[["buffer"]]),
    geom_tile(data = hab, fill = colours[["habitat"]])
  ),
  map_plot(
    geom_tile(data = cut, fill = colours[["buffer"]]),
    geom_tile(data = road, fill = colours[["barrier"]]),
    geom_tile(data = hab, fill = colours[["habitat"]])
  ),
  map_plot(
    geom_tile(data = grown, aes(fill = patch_id)),
    geom_tile(data = road, fill = colours[["barrier"]]),
    geom_tile(data = hab, fill = colours[["habitat"]]),
    patch_colours
  ),
  map_plot(
    geom_tile(data = road, fill = colours[["barrier"]]),
    geom_tile(data = patches, aes(fill = patch_id)),
    patch_colours
  ),
  whole_map(geom_tile(data = reach, aes(fill = patch_id)), patch_colours)
)

# a few KB each, and still sharp on a high-density screen at the size shown
dir.create("inst/shiny/www", showWarnings = FALSE)
purrr::iwalk(figures, function(figure, step) {
  ggsave(
    sprintf("inst/shiny/www/method-step-%d.png", step),
    figure,
    width = 2,
    height = 2,
    dpi = 150
  )
})
