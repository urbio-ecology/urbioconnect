# What each input means. The "i" beside its label and the Details
# page both read from here, so the two can't disagree.
input_help <- list(
  species = list(
    label = "Species name",
    help = c(
      "The species you are planning for, such as 'Superb Fairy Wren'. It
      labels the maps, tables and report."
    )
  ),
  habitat_file = list(
    label = "Habitat layer",
    help = c(
      "Where your species lives: parks, bushland, creek corridors or gardens.",
      "- Polygons, as a shapefile
      - A raster (GeoTIFF): any cell other than 0 or empty (no data) is
        habitat.",
      "Only the area inside its bounding box is analysed."
    )
  ),
  barrier_file = list(
    label = "Barrier layer",
    help = c(
      "What your species can't cross: roads, railways, buildings.",
      "- Polygons
      - A raster: barrier cells 1, all others 0 or empty",
      "Same coordinate reference system as the habitat. Habitat under a barrier
      is removed, and a connection can go around a barrier but never across it."
    )
  ),
  example_data = list(
    label = "Example data",
    help = c(
      "Try the app on built-in data. Fills in the species and replaces both
      uploads.",
      "- Blue Tongue Lizard (Darebin Creek), ~1.5 km, ~1s per distance
      - Superb Fairy Wren (Knox), ~14 km, ~10s per distance"
    )
  ),
  scenario_choice = list(
    label = "Scenario layer (optional)",
    help = c(
      "A change to test, such as a new road or housing development. The app
      runs the analysis with and without it, and the Results tab compares
      them.",
      "Give the whole layer after the change: a barrier scenario holding only
      the new road leaves out every existing road."
    )
  ),
  scenario_kind = list(
    # short enough not to wrap in a 300px input, which would push the "i" onto
    # a line of its own
    label = "Which layer does it change?",
    help = c(
      "- Barrier: it adds or removes roads or other barriers
      - Habitat: it adds or removes habitat"
    )
  ),
  scenario_file = list(
    label = "Your scenario layer",
    help = c(
      "Same formats, place and coordinate reference system as the layer it
      replaces. Its cell size doesn't need to match."
    )
  ),
  data_resolution = list(
    label = "Data resolution (m)",
    help = c(
      "The width of the grid cells, in metres.",
      "- Smaller: slower, but thin roads and narrow gaps stay sharp
      - Larger: faster, but small patches can merge or vanish",
      "Use at most half your smallest interpatch distance: 50 m or less for
      100 m."
    )
  ),
  interpatch_distances = list(
    label = "Interpatch distances (m)",
    help = c(
      "How far your species will cross open ground. Patches closer than this
      join into one connected patch, unless a barrier lies between them.",
      "Up to four, separated by commas, for example 100, 250, 400. Use
      distances from published studies or local experts.",
      "Each is rounded down to a multiple of twice the cell size: at 10 m
      cells, 250 m becomes 240 m. The Your analysis box warns you when this
      happens."
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
      id = glue::glue("{id}-help"),
      class = "input-help ms-1",
      fontawesome::fa(
        "circle-info",
        a11y = "sem",
        title = glue::glue("More about: {entry$label}")
      )
    ),
    help_paragraphs(id),
    title = entry$label
  )

  input <- htmltools::tagQuery(input_fn(inputId = id, label = entry$label, ...))
  input$find(glue::glue("#{id}-label"))$after(icon)$allTags()
}

# Each element is a markdown paragraph or list. trim() takes off the source's
# indentation, which would otherwise stop a "- " line starting a list.
help_paragraphs <- function(id) {
  help <- glue::trim(input_help[[id]]$help)
  shiny::markdown(glue::glue_collapse(help, sep = "\n\n"))
}

# For the Details page: each input's explanation under its label
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
  grid <- glue::glue("on a grid of {metres(data_resolution)} cells")

  description <- if (is.null(data)) {
    glue::glue(
      "Choose example data, or upload a habitat and a barrier layer. \\
      The analysis runs {grid}."
    )
  } else {
    glue::glue("{data}, {grid}.")
  }

  description
}

describe_distances <- function(distances) {
  description <- if (length(distances) == 1) {
    glue::glue(
      "Patches up to {metres(distances)} apart are joined, unless a barrier \\
      lies between them."
    )
  } else {
    glue::glue(
      "The analysis runs once for each of {length(distances)} interpatch \\
      distances: {metres(distances)}. At each, patches up to that distance \\
      apart are joined, unless a barrier lies between them."
    )
  }

  description
}

describe_scenario <- function(scenario) {
  if (is.null(scenario)) {
    return(character())
  }

  # an upload names its file once there is one
  name <- if (is.null(scenario$name)) {
    "your scenario layer"
  } else {
    glue::glue('"{scenario$name}"')
  }

  glue::glue(
    "Then it runs again with {name} in place of the {scenario$kind} layer, \\
    and compares the two."
  )
}

too_short <- function(short, data_resolution) {
  if (length(short) == 0) {
    return(character())
  }

  one <- length(short) == 1

  problem <- if (one) {
    glue::glue(
      "{metres(short)} is too short to measure: half of it \\
      ({metres(short / 2)}) is less than one cell"
    )
  } else {
    glue::glue(
      "{metres(short)} are too short to measure: half of each is less than \\
      one cell"
    )
  }

  # the cell size input takes whole metres, and at least 1; "" not NULL, since
  # glue() returns nothing at all for a NULL
  cell <- floor(min(short) / 2)
  smaller_cells <- if (cell >= 1) {
    glue::glue("cells of {metres(cell)} or smaller, or ")
  } else {
    ""
  }
  distance <- if (one) "a distance" else "distances"

  glue::glue(
    "At {metres(data_resolution)} cells, {problem}, so only patches that \\
    touch will join. Use {smaller_cells}{distance} of at least \\
    {metres(2 * data_resolution)}."
  )
}

rounded <- function(distances, treated_as, data_resolution) {
  moved <- treated_as > 0 & !dplyr::near(treated_as, distances)
  if (!any(moved)) {
    return(character())
  }

  verb <- c(" is treated as ", rep(" as ", sum(moved) - 1))
  changes <- glue::glue(
    "{number(distances[moved])} m{verb}{number(treated_as[moved])} m"
  )

  glue::glue(
    "At {metres(data_resolution)} cells, distances go up in steps of \\
    {metres(2 * data_resolution)}, so {and_list(changes)}."
  )
}

too_many <- function(distances) {
  if (length(distances) <= 4) {
    return(character())
  }

  glue::glue(
    "You have entered {length(distances)} distances. Each is a separate \\
    analysis, so this takes longer. Up to four is usually enough to see the \\
    trend."
  )
}

# "100, 250 and 400 m"
metres <- function(values) {
  glue::glue("{and_list(number(values))} m")
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
  cli::ansi_collapse(x, sep = ", ", last = " and ")
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
