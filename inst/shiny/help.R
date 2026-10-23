# What each input means. The "i" beside its label and the Before you start
# page both read from here, so the two can't disagree.
input_help <- list(
  species = list(
    label = "Species name",
    help = c(
      "The species you are planning for. For example, 'Superb Fairy Wren'.",
      "This name will also label the outputs - maps, tables, and report."
    )
  ),
  habitat_file = list(
    label = "Habitat layer",
    help = c(
      "Where your species lives: parks, bushland, creek corridors or
      gardens that count as its habitat.",
      "Upload polygons (a shapefile) or a raster (GeoTIFF). In rasters,
      habitat cells should be 1 and every other cell empty (no data).
      A cell of 0 is read as habitat, so set those cells to no data first.",
      "The habitat layer sets the area analysed. Anything outside its bounding
      box is left out."
    )
  ),
  barrier_file = list(
    label = "Barrier layer",
    help = c(
      "What your species can't cross: roads, railways, buildings, etc.",
      "Upload polygons or raster cells set to 1 and everything else 0 or empty.
      It must use the same coordinate reference system as the habitat layer.",
      "Habitat under a barrier is removed. A connection can go around the end
      of a barrier, but never across it."
    )
  ),
  example_data = list(
    label = "Example data",
    help = c(
      "Test out the app with our built-in example data. This fills in species
      and replaces both uploads.",
      "Blue Tongue Lizard (Darebin Creek), ~1.5 km. Runs in ~1s per distance",
      "Superb Fairy Wren (Knox), ~14 km. Runs in ~10s for each distance."
    )
  ),
  scenario_choice = list(
    label = "Scenario layer (optional)",
    help = c(
      "A change you want to test, such as a new road or a housing development.
      The app runs the analysis twice: once on the landscape as
      it is (baseline), and once with your scenario in place of the layer
      it changes. Both runs use the same distances and cell size, and the
      Results tab shows the difference.",
      "A scenario is the whole layer as it would be after the change. A
      barrier scenario holding only the new road leaves out every existing
      road, and the landscape looks far better connected than it is."
    )
  ),
  scenario_kind = list(
    # short enough not to wrap in a 300px input, which would push the "i" onto
    # a line of its own
    label = "Which layer does it change?",
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
      baseline's grid, so its cell size doesn't need to match",
      "Must cover the same place and use the same coordinate reference system."
    )
  ),
  data_resolution = list(
    label = "Data resolution (m)",
    help = c(
      "Size of grid cells used in the analysis, in metres. Layers are converted
      cells about this wide.",
      "Smaller cells are slow, but keep thin roads and narrow gaps sharp.",
      "Larger cells are faster, but smaller patches can merge or disappear.",
      "Keep cells less than half your smallest interpatch distance. So an
      interpatch distance of 100m should mean your cells should be 50m or smaller.",
      "Coarser means gaps between patches can't be measured, so only patches that
      touch will join."
    )
  ),
  interpatch_distances = list(
    label = "Interpatch distances (m)",
    help = c(
      "How far your species will cross open ground to reach another patch of
      habitat. Patches closer together than this are joined into one
      connected patch, unless a barrier lies between them.",
      "You can enter multiple distances to see how connectivity changes.",
      "For example: 100, 250, 400",
      "With a maximum of four distances.",
      "Use a distance from published studies or local experts on your species.",
      "Distances are measured in whole cells, so each is rounded down to a
      multiple of twice the cell size: at 10 m cells, 250 m is treated as
      240 m. Each must be at least twice the cell size. The Your analysis box
      above the Run button warns you when either happens."
    )
  )
)

# An input labelled from input_help, with an "i" after its label that opens
# its explanation. The "i" goes beside the <label>, not in it: inside, a
# screen reader reads it as part of the input's name, and a click on it
# reaches the input, which for a file input opens the file picker.
help_input <- function(input_fn, id, ...) {
  entry <- input_help[[id]] %||%
    cli::cli_abort("There is no help text for the {.val {id}} input.")

  icon <- popover(
    span(
      id = paste0(id, "-help"),
      class = "input-help ms-1",
      fontawesome::fa(
        "circle-info",
        a11y = "sem",
        title = paste("More about:", entry$label)
      )
    ),
    help_paragraphs(id),
    title = entry$label
  )

  input <- htmltools::tagQuery(input_fn(inputId = id, label = entry$label, ...))
  input$find(paste0("#", id, "-label"))$after(icon)$allTags()
}

# the strings are wrapped in the source; squish so the line breaks don't show
help_paragraphs <- function(id) {
  tagList(purrr::map(
    input_help[[id]]$help,
    \(text) p(gsub("\\s+", " ", trimws(text)))
  ))
}

# For the Before you start page: each input's explanation under its label
help_sections <- function(ids) {
  tagList(purrr::map(
    ids,
    \(id) tagList(h5(input_help[[id]]$label), help_paragraphs(id))
  ))
}

# coloured and with a pointer, so an "i" reads as something to click
input_help_head <- tags$style(HTML(
  ".input-help { cursor: pointer; color: var(--bs-primary); }"
))

# What the inputs add up to, in words, before anything runs: a few sentences,
# and a warning for each setting that won't do what it looks like. Plain
# values in, so it is tested without a session. `data` names the layers, or is
# NULL before there are any; `scenario` is a list of `name` and `kind`.
describe_analysis <- function(
  data,
  data_resolution,
  distances,
  scenario = NULL
) {
  treated_as <- representable_distance(distances, data_resolution)

  list(
    summary = c(
      describe_data(data, data_resolution),
      describe_distances(distances),
      describe_scenario(scenario)
    ),
    warnings = c(
      too_short(distances[treated_as == 0], data_resolution),
      rounded(distances, treated_as, data_resolution),
      too_many(distances)
    )
  )
}

describe_data <- function(data, data_resolution) {
  grid <- paste0("on a grid of ", metres(data_resolution), " cells")

  if (is.null(data)) {
    return(paste0(
      "Choose example data, or upload a habitat and a barrier layer. The ",
      "analysis runs ",
      grid,
      "."
    ))
  }

  paste0(data, ", ", grid, ".")
}

describe_distances <- function(distances) {
  if (length(distances) == 1) {
    return(paste0(
      "Patches up to ",
      metres(distances),
      " apart are joined, unless a barrier lies between them."
    ))
  }

  paste0(
    "The analysis runs once for each of ",
    length(distances),
    " interpatch distances: ",
    metres(distances),
    ". At each, patches up to that distance apart are joined, unless a ",
    "barrier lies between them."
  )
}

describe_scenario <- function(scenario) {
  if (is.null(scenario)) {
    return(character())
  }

  # an upload names its file once there is one
  name <- if (is.null(scenario$name)) {
    "your scenario layer"
  } else {
    paste0('"', scenario$name, '"')
  }

  paste0(
    "Then it runs again with ",
    name,
    " in place of the ",
    scenario$kind,
    " layer, and compares the two."
  )
}

too_short <- function(short, data_resolution) {
  if (length(short) == 0) {
    return(character())
  }

  one <- length(short) == 1

  problem <- if (one) {
    paste0(
      metres(short),
      " is too short to measure: half of it (",
      metres(short / 2),
      ") is less than one cell"
    )
  } else {
    paste0(
      metres(short),
      " are too short to measure: half of each is less than one cell"
    )
  }

  # the cell size input takes whole metres, and at least 1
  cell <- floor(min(short) / 2)
  smaller_cells <- if (cell >= 1) {
    paste0("cells of ", metres(cell), " or smaller, or ")
  }

  paste0(
    "At ",
    metres(data_resolution),
    " cells, ",
    problem,
    ", so only patches that touch will join. Use ",
    smaller_cells,
    if (one) "a distance" else "distances",
    " of at least ",
    metres(2 * data_resolution),
    "."
  )
}

rounded <- function(distances, treated_as, data_resolution) {
  moved <- treated_as > 0 & !dplyr::near(treated_as, distances)
  if (!any(moved)) {
    return(character())
  }

  changes <- paste0(
    number(distances[moved]),
    " m",
    c(" is treated as ", rep(" as ", sum(moved) - 1)),
    number(treated_as[moved]),
    " m"
  )

  paste0(
    "At ",
    metres(data_resolution),
    " cells, distances go up in steps of ",
    metres(2 * data_resolution),
    ", so ",
    and_list(changes),
    "."
  )
}

too_many <- function(distances) {
  if (length(distances) <= 4) {
    return(character())
  }

  paste0(
    "You have entered ",
    length(distances),
    " distances. Each is a separate analysis, so this takes longer. Up to ",
    "four is usually enough to see the trend."
  )
}

# "100, 250 and 400 m"
metres <- function(values) {
  paste(and_list(number(values)), "m")
}

# each on its own, so 7.5 and 100 don't share decimal places
number <- function(values) {
  vapply(
    values,
    \(value) format(value, trim = TRUE, scientific = FALSE),
    character(1)
  )
}

and_list <- function(x) {
  glue::glue_collapse(x, sep = ", ", last = " and ")
}

# describe_analysis() as tags: a paragraph per sentence, the warnings together
analysis_preview <- function(description) {
  tagList(
    purrr::map(description$summary, p),
    if (length(description$warnings) > 0) {
      div(
        class = "alert alert-warning",
        purrr::map(description$warnings, \(warning) p(class = "mb-1", warning))
      )
    }
  )
}
