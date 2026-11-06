# The Details tab's example of what the cell size changes: the step figures'
# square at a 100 m interpatch distance, at each cell size here, with a table
# of their alt text. Re-run from the package root, with the package loaded,
# after changing them (about a minute):
#   Rscript -e 'devtools::load_all(); source("data-raw/cell-size-figures.R")'
library(ggplot2)
library(terra)

distance <- 100
round_sizes <- c(1, 2, 5, 10, 15, 20, 25, 30, 40, 50, 60, 75, 100)
# and one past half the distance, so sizes too wide to grow a buffer show none
cell_sizes <- sort(c(round_sizes, distance / 2 + 1))
# method-figures.R's square, so move both together
zoom <- ext(c(326609.6, 326849.6), c(5820993.6, 5821233.6))
# the step figures' blue and gold first
patch_colours <- colorspace::qualitative_hcl(7)[c(6, 2, 4, 1, 3, 5, 7)]

draw_square <- function(size) {
  layers <- prepare_rasters(
    example_habitat(),
    example_barrier(),
    data_resolution = size
  )
  steps <- habitat_connectivity_full(
    layers$habitat_raster,
    layers$barrier_raster,
    distance,
    verbose = FALSE
  )
  grown <- fragment_habitat(steps$buffered_habitat, steps$barrier_mask)

  # c() with names gives a list, not a SpatRaster
  square <- c(
    layers$barrier_raster == 1,
    !is.na(grown),
    steps$patch_id_raster$patch_id
  )
  names(square) <- c("barrier", "buffer", "patch")
  cells <- crop(square, zoom, snap = "out") |>
    as.data.frame(xy = TRUE, na.rm = FALSE)
  cells$patch <- factor(cells$patch)
  n_patches <- nlevels(cells$patch)

  # terra stretches cells to fit the map, so they are not quite `size` wide
  cell <- res(layers$habitat_raster)
  tile <- function(data, ...) {
    geom_tile(data = data, ..., width = cell[1], height = cell[2])
  }
  figure <- ggplot(mapping = aes(x, y)) +
    tile(
      cells[cells$buffer %in% TRUE, ],
      fill = urbio_colours()$interpatch_distance
    ) +
    tile(cells[cells$barrier %in% TRUE, ], fill = "grey40") +
    tile(cells[!is.na(cells$patch), ], aes(fill = patch)) +
    scale_fill_manual(values = rep_len(patch_colours, n_patches)) +
    coord_equal(
      expand = FALSE,
      xlim = c(zoom$xmin, zoom$xmax),
      ylim = c(zoom$ymin, zoom$ymax)
    ) +
    labs(title = cli::pluralize("{size} m cells: {n_patches} patch{?es}")) +
    theme_void() +
    theme(
      panel.background = element_rect(fill = "grey96"),
      legend.position = "none"
    )

  # twice the 300 by 320 px the app shows it at, so it is sharp on a
  # high-density screen
  file <- sprintf("cell-size-%d.png", size)
  ggsave(
    file.path("inst/shiny/www", file),
    figure,
    width = 300 / 72,
    height = 320 / 72,
    dpi = 144
  )

  # grown cells beyond the habitat, which a radius less than a cell gives none of
  buffer <- if (any(cells$buffer & is.na(cells$patch))) {
    "the buffer around it in light green"
  } else {
    "no buffer, as a cell is wider than its radius"
  }
  alt <- cli::pluralize(
    "The example square from Before you start at {size} m cells and a \\
    {distance} m interpatch distance, with {n_patches} connected \\
    patch{?es}: habitat above and below a grey road, {buffer}, and the \\
    habitat coloured by patch."
  )
  data.frame(cell_size = size, file = file, alt = alt)
}

unlink(Sys.glob("inst/shiny/www/cell-size-*.png"))
figures <- purrr::map(cell_sizes, draw_square) |> purrr::list_rbind()
write.csv(figures, "inst/shiny/www/cell-size-figures.csv", row.names = FALSE)
