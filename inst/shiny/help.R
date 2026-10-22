# What each input means. The "i" beside its label and the Before you start
# page both read from here, so the two can't disagree.
input_help <- list(
  species = list(
    label = "Species name",
    help = c(
      "The animal or plant you are planning for. It labels the maps, tables
      and report, and names the download files.",
      "It does not change the analysis. How far your species can move is set
      by the interpatch distance."
    )
  ),
  habitat_file = list(
    label = "Habitat layer",
    help = c(
      "Where your species lives: the parks, bushland, creek corridors or
      gardens that count as habitat for it.",
      "Upload polygons (a shapefile, GeoPackage or GeoJSON) or a GeoTIFF. In a
      GeoTIFF, habitat cells should be 1 and every other cell empty (no data).
      A cell of 0 is read as habitat, so set those cells to no data first.",
      "The habitat layer sets the area analysed. Anything outside its bounding
      box is left out."
    )
  ),
  barrier_file = list(
    label = "Barrier layer",
    help = c(
      "What your species can't cross, such as roads, railways and buildings.",
      "Upload lines or polygons, or a GeoTIFF with barrier cells set to 1 and
      everything else 0 or empty. It must use the same coordinate reference
      system as the habitat layer.",
      "Habitat under a barrier is removed. A connection can go around the end
      of a barrier, but never across it."
    )
  ),
  example_data = list(
    label = "Example data",
    help = c(
      "Try the app without your own layers. Choosing a dataset fills in the
      species and replaces both uploads.",
      "The Blue Tongue Lizard landscape, along Darebin Creek, is about 1.5 km
      across and runs in about a second. The Superb Fairy Wren landscape, in
      Knox, is about 14 km across and takes tens of seconds for each
      distance."
    )
  ),
  scenario_choice = list(
    label = "Scenario layer (optional)",
    help = c(
      "A change you want to test, such as a new road or a housing
      development. The app runs the analysis twice: once on the landscape as
      it is (the baseline), and once with your scenario in place of the layer
      it changes. Both runs use the same distances and cell size, and the
      Results tab shows the difference.",
      "A scenario is the whole layer as it would be after the change. A
      barrier scenario holding only the new road leaves out every existing
      road, and the landscape looks far better connected than it is."
    )
  ),
  scenario_kind = list(
    label = "Which layer does your scenario change?",
    help = c(
      "Barrier if the scenario adds or removes roads or other barriers.
      Habitat if it adds or removes habitat. Only one layer changes, so any
      difference in connectivity comes from that change."
    )
  ),
  scenario_file = list(
    label = "Your scenario layer",
    help = c(
      "The same formats as the habitat and barrier layers. It is put on the
      baseline's grid, so its cell size doesn't need to match, but it must
      cover the same place and use the same coordinate reference system."
    )
  ),
  data_resolution = list(
    label = "Data resolution (m)",
    help = c(
      "The size of the grid cells the analysis works on, in metres. Both
      layers are converted to square cells about this wide before anything is
      measured. The default is 10 m.",
      "Smaller cells keep thin roads and narrow gaps sharp, but take longer:
      halving the cell size makes four times as many cells. Larger cells are
      faster, but a thin road becomes a whole cell wide, and small patches can
      merge or disappear.",
      "Keep it at most half your smallest interpatch distance. Any coarser,
      and the gaps between patches can't be measured, so only patches that
      touch will join."
    )
  ),
  interpatch_distances = list(
    label = "Interpatch distances (m)",
    help = c(
      "How far your species will cross open ground to reach another patch of
      habitat. Patches closer together than this are joined into one
      connected patch, unless a barrier lies between them.",
      "Enter up to four distances, separated by commas, such as 100, 250,
      400, to see how connectivity changes with distance. Each distance is a
      separate analysis. Use a distance from published studies or local
      experts on your species.",
      "Distances are measured in whole cells, so each is rounded down to a
      multiple of twice the cell size: at 10 m cells, 250 m is treated as
      240 m. Each must be at least twice the cell size."
    )
  )
)

# An input's label, with an "i" that opens its explanation
help_label <- function(id) {
  entry <- input_help[[id]] %||%
    cli::cli_abort("There is no help text for the {.val {id}} input.")

  tagList(
    entry$label,
    popover(
      span(
        class = "input-help ms-1",
        fontawesome::fa(
          "circle-info",
          a11y = "sem",
          title = paste("About", tolower(entry$label))
        )
      ),
      help_paragraphs(id),
      title = entry$label
    )
  )
}

# the strings are wrapped in the source; squish so the line breaks don't show
help_paragraphs <- function(id) {
  tagList(purrr::map(input_help[[id]]$help, \(text) p(squish(text))))
}

squish <- function(text) {
  gsub("\\s+", " ", trimws(text))
}

# The "i" sits inside its input's <label>, and clicking a label activates its
# input: a file input opens the file picker. So a click stops at the "i".
input_help_head <- tagList(
  tags$style(HTML(
    ".input-help { cursor: pointer; color: var(--bs-primary); }"
  )),
  tags$script(HTML(
    "$(document).on('click', '.input-help', function(e) { e.preventDefault(); });"
  ))
)
