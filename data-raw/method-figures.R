# The five step-by-step figures on the app's Before you start page, drawn from
# a small part of the lizard example. Re-run from the package root, with the
# package loaded, after changing them:
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

patches <- as.data.frame(
  crop(steps$patch_id_raster$patch_id, zoom),
  xy = TRUE,
  na.rm = TRUE
)
patches$patch_id <- factor(patches$patch_id)

step_plot <- function(title, ...) {
  ggplot(mapping = aes(x, y)) +
    list(...) +
    coord_equal(
      expand = FALSE,
      xlim = c(zoom$xmin, zoom$xmax),
      ylim = c(zoom$ymin, zoom$ymax)
    ) +
    labs(title = title) +
    theme_void() +
    theme(
      panel.background = element_rect(fill = "grey96", colour = "grey70"),
      legend.position = "none"
    )
}

whole <- ext(example_habitat())

figures <- list(
  step_plot(
    "1. Habitat and a road",
    geom_tile(data = road, fill = colours[["barrier"]]),
    geom_tile(data = hab, fill = colours[["habitat"]])
  ),
  step_plot(
    glue::glue("2. Grow each patch by {distance / 2} m"),
    geom_tile(data = buf, fill = colours[["buffer"]]),
    geom_tile(data = hab, fill = colours[["habitat"]])
  ),
  step_plot(
    "3. The road cuts the grown area",
    geom_tile(data = cut, fill = colours[["buffer"]]),
    geom_tile(data = road, fill = colours[["barrier"]]),
    geom_tile(data = hab, fill = colours[["habitat"]])
  ),
  step_plot(
    "4. Two connected patches",
    geom_tile(data = road, fill = colours[["barrier"]]),
    geom_tile(data = patches, aes(fill = patch_id)),
    scale_fill_manual(values = c("#0072B2", "#E69F00"))
  ),
  ggplot(mapping = aes(x, y)) +
    geom_tile(data = cells(barrier, whole), fill = colours[["barrier"]]) +
    geom_tile(
      data = cells(steps$remaining_habitat, whole),
      fill = colours[["habitat"]]
    ) +
    annotate(
      "rect",
      xmin = zoom$xmin,
      xmax = zoom$xmax,
      ymin = zoom$ymin,
      ymax = zoom$ymax,
      fill = NA,
      colour = "#D55E00",
      linewidth = 1
    ) +
    coord_equal(expand = FALSE) +
    labs(title = "5. The square is a small part of the lizard map") +
    theme_void() +
    theme(panel.background = element_rect(fill = "grey96", colour = "grey70"))
)

# a few KB each, and still sharp on a high-density screen at the size shown
dir.create("inst/shiny/www", showWarnings = FALSE)
purrr::iwalk(figures, function(figure, step) {
  ggsave(
    sprintf("inst/shiny/www/method-step-%d.png", step),
    figure,
    width = if (step == 5) 5 else 3,
    height = if (step == 5) 5.4 else 3.2,
    dpi = 150
  )
})
