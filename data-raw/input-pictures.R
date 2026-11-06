# The pictures beside the habitat, barrier and scenario uploads on the app's
# Inputs tab: a piece of the lizard example, marked up with what its values
# mean, in the words inst/shiny/help.R gives. Re-run from the package root:
#   Rscript -e 'devtools::load_all(); source("data-raw/input-pictures.R")'
library(ggplot2)
library(terra)

# help.R builds a tag as it is sourced, so it needs htmltools
library(htmltools)
app_help <- new.env()
sys.source("inst/shiny/help.R", envir = app_help)
pictures <- purrr::compact(purrr::map(app_help$input_help, "picture"))

# the square the Before you start figures zoom in on, with the scenario's new
# road running down it
piece <- ext(326609.6, 326849.6, 5820993.6, 5821233.6)
side <- piece$xmax - piece$xmin

# Shown at 300 by 120 CSS pixels, as ui.R says, and drawn at twice that to be
# sharp on a high-density screen. At 144 dpi, 14 point text is then 14 pixels
# on screen, the size of the app's help text.
text_size <- 14 / .pt

# the piece of a layer on its pale ground, with the cells that are 1 in `fill`
layer_tiles <- function(layer, fill, shift = 0) {
  cells <- as.data.frame(crop(layer, piece), xy = TRUE, na.rm = TRUE)
  list(
    annotate(
      "rect",
      xmin = piece$xmin + shift,
      xmax = piece$xmax + shift,
      ymin = piece$ymin,
      ymax = piece$ymax,
      fill = "grey96",
      colour = "grey70"
    ),
    geom_tile(aes(x + shift, y), data = cells[cells[[3]] == 1, ], fill = fill)
  )
}

# A label at `to`, with a line from the point `at` it is about. What comes
# before a colon is in bold, and what comes after goes on the line below.
callout <- function(label, at, to) {
  parts <- strsplit(label, ": ", fixed = TRUE)[[1]]
  list(
    annotate("segment", x = at[1], y = at[2], xend = to[1] - 7, yend = to[2]),
    annotate("point", x = at[1], y = at[2], size = 1.2),
    annotate(
      "text",
      x = to[1],
      y = to[2],
      label = parts,
      hjust = 0,
      vjust = if (length(parts) == 1) 0.5 else c(0, 1.2),
      fontface = c("bold", "plain")[seq_along(parts)],
      size = text_size
    )
  )
}

# `top` is the room above the piece for titles, in metres
picture <- function(..., top = 0) {
  height <- side + top
  ggplot(mapping = aes(x, y)) +
    list(...) +
    coord_equal(
      expand = FALSE,
      clip = "off",
      xlim = piece$xmin + c(0, 2.5 * height),
      ylim = piece$ymin + c(0, height)
    ) +
    theme_void()
}

habitat <- pictures$habitat_file$labels
barrier <- pictures$barrier_file$labels
scenario <- pictures$scenario_file$labels
text_x <- piece$xmax + 30
upper <- piece$ymin + 175
lower <- piece$ymin + 70
# the scenario's copy of the piece, to the right of the baseline's
shift <- side + 20

figures <- list(
  habitat_file = picture(
    layer_tiles(example_habitat(), urbio_colours()$habitat),
    callout(habitat[["habitat"]], c(326800, 5821205), c(text_x, upper)),
    callout(habitat[["other"]], c(326705, 5821140), c(text_x, lower))
  ),
  barrier_file = picture(
    layer_tiles(example_barrier(), "grey40"),
    callout(barrier[["barrier"]], c(326800, 5821120), c(text_x, upper)),
    callout(barrier[["other"]], c(326800, 5821050), c(text_x, lower))
  ),
  scenario_file = picture(
    layer_tiles(example_barrier(), "grey40"),
    layer_tiles(example_barrier_scenario(), "grey40", shift),
    annotate(
      "text",
      x = piece$xmin + c(0, shift) + side / 2,
      y = piece$ymax + 36,
      label = scenario[c("baseline", "scenario")],
      fontface = "bold",
      size = text_size
    ),
    # the new road is 18 m wide, from x = 326797.6
    callout(
      scenario[["change"]],
      c(326806.6 + shift, 5821050),
      c(piece$xmax + shift + 20, lower)
    ),
    top = 72
  )
)

purrr::iwalk(figures, function(figure, id) {
  ggsave(
    file.path("inst/shiny/www", pictures[[id]]$file),
    figure,
    width = 600,
    height = 240,
    units = "px",
    dpi = 144,
    bg = "white"
  )
})
