# Quarto is separate software and may not be installed where the app runs.
# Asked once here, not per session: it can't change while the app is up.
has_quarto <- quarto_available()

# A download button that is dead unless Quarto is there to render with
report_button <- function(id, label) {
  button <- downloadButton(id, label, class = "btn-outline-success w-100")
  if (has_quarto) button else shinyjs::disabled(button)
}

# The step-by-step figures on Before you start, drawn by
# data-raw/method-figures.R
method_figure <- function(step, alt) {
  img(src = sprintf("method-step-%d.png", step), alt = alt, class = "img-fluid")
}

details_panel <- function() {
  # Opened from the foot of Before you start. What it says about each input
  # comes from help.R, so it can't disagree with that input's "i".
  nav_panel(
    title = "Details",
    icon = icon("book-open"),
    layout_columns(
      col_widths = breakpoints(sm = 12, lg = c(-2, 8, -2)),
      card(
        card_body(
          accordion(
            id = "details",
            open = FALSE,
            accordion_panel(
              "Prepare your data",
              help_sections(c("habitat_file", "barrier_file")),
              p(
                "Both layers need the same coordinate reference system, and it",
                "should be a projected one in metres, such as GDA2020 / MGA.",
                "Cell sizes and distances are read in the layers' own units.",
                "The example data uses GDA94 / MGA zone 55."
              ),

              h5("Uploading shapefiles"),
              p(
                strong("Important:"),
                "Shapefiles consist of multiple files; upload all required files:"
              ),

              tags$div(
                class = "ms-3",
                h6("Required files"),
                tags$ul(
                  tags$li(
                    tags$code(".shp"),
                    " - Main file containing geometry"
                  ),
                  tags$li(tags$code(".shx"), " - Shape index file"),
                  tags$li(tags$code(".dbf"), " - Attribute database file")
                ),

                h6("Optional (but recommended)"),
                tags$ul(
                  tags$li(tags$code(".prj"), " - Projection information"),
                  tags$li(tags$code(".cpg"), " - Character encoding")
                )
              ),

              h5("How to upload in the app"),
              tags$ol(
                tags$li("Click \"Browse\" on the file input"),
                tags$li(
                  strong("Select all shapefile components at once"),
                  " (hold Ctrl/Cmd to select multiple)",
                  tags$ul(
                    tags$li(
                      "Example: Select ",
                      tags$code("habitat.shp"),
                      ", ",
                      tags$code("habitat.shx"),
                      ", ",
                      tags$code("habitat.dbf"),
                      ", ",
                      tags$code("habitat.prj"),
                      " together"
                    )
                  )
                ),
                tags$li("Click \"Open\"")
              ),

              h5("Common errors"),
              tags$div(
                class = "ms-3",
                tags$div(
                  class = "alert alert-warning",
                  strong("Error: \"Cannot open shapefile; source corrupt\""),
                  tags$ul(
                    tags$li(
                      strong("Cause:"),
                      " Missing required files (.shx or .dbf)"
                    ),
                    tags$li(
                      strong("Solution:"),
                      " Make sure you selected ALL shapefiles when uploading"
                    )
                  )
                ),
                tags$div(
                  class = "alert alert-warning",
                  strong("Error: \"Shapefile upload incomplete\""),
                  tags$ul(
                    tags$li(strong("Cause:"), " Only one file was uploaded"),
                    tags$li(
                      strong("Solution:"),
                      " Select all files together in the file browser"
                    )
                  )
                )
              ),

              h5("Alternative formats"),
              p("If you have trouble with shapefiles, consider using:"),
              tags$ul(
                tags$li(
                  strong("GeoTIFF"),
                  " (",
                  tags$code(".tif"),
                  ", ",
                  tags$code(".tiff"),
                  ") - Single file, easier to upload"
                ),
                tags$li(
                  strong("GeoJSON"),
                  " (",
                  tags$code(".geojson"),
                  ") - Single file, text-based vector format"
                )
              ),
              p("You can convert shapefiles to these formats using:"),
              tags$ul(
                tags$li("QGIS (free, open source)"),
                tags$li("ArcGIS"),
                tags$li(
                  "R: ",
                  tags$code("terra::writeRaster()"),
                  " or ",
                  tags$code("sf::st_write()")
                )
              )
            ),
            accordion_panel(
              "Choose your settings",
              p(paste0(
                "The defaults are a cell size of ",
                input_defaults$data_resolution,
                " m and one interpatch distance of ",
                input_defaults$interpatch_distances,
                " m."
              )),
              help_sections(c(
                "data_resolution",
                "interpatch_distances",
                "species"
              )),
              p(
                "Not sure which cell size to use? The rule of thumb is a cell",
                "size of at most half your smallest interpatch distance. The",
                "package website has a worked example:",
                a(
                  href = "https://urbio-ecology.github.io/urbioconnect/articles/interpatch-distance-and-resolution.html",
                  target = "_blank",
                  "Interpatch distance and raster resolution",
                  .noWS = "after"
                ),
                "."
              )
            ),
            accordion_panel(
              "Compare a scenario (optional)",
              help_sections(c(
                "scenario_choice",
                "scenario_kind",
                "scenario_file"
              ))
            ),
            accordion_panel(
              "Run and read the results",
              tags$ol(
                tags$li(
                  "Choose example data, or upload a habitat and a barrier",
                  "layer."
                ),
                tags$li(
                  "Set the cell size and one to four interpatch distances. The",
                  "Your analysis box above the Run button says what will",
                  "happen."
                ),
                tags$li("Choose a scenario, if you have one."),
                tags$li(
                  "Click Run Analysis. The lizard example takes about a",
                  "second; a larger landscape takes longer."
                ),
                tags$li(
                  "The Results tab has maps of the habitat and barriers and of",
                  "the connected patches, one tab per distance; the tables;",
                  "and a plot of how the numbers change with distance. Its",
                  "Scenario view compares the scenario with the baseline."
                ),
                tags$li(
                  "Every table has its own CSV download. The Downloads tab has",
                  "the GIS layers, the reports, and one archive of everything."
                )
              ),
              h5("What the numbers mean"),
              p("These are the column names in the results tables."),
              tags$ul(
                tags$li(
                  strong("Patches:"),
                  "how many separate connected patches there are. More",
                  "usually means more fragmented."
                ),
                tags$li(
                  strong("Mesh (ha):"),
                  "the effective mesh size. The size of the connected patch",
                  "you would be in, on average, from a point picked at random",
                  "in the habitat. Larger means better connected."
                ),
                tags$li(
                  strong("P(connected):"),
                  "the probability of connectedness. The chance that two",
                  "points picked at random in the habitat are in the same",
                  "connected patch. Higher means better connected."
                ),
                tags$li(
                  strong("Mean area (m2)"),
                  "and",
                  strong("Total area (ha):"),
                  "the average size of a connected patch, and all of the",
                  "habitat added up."
                )
              )
            ),
            accordion_panel(
              "About this app",
              p(
                "Built with R, Shiny and terra, as the urbioconnect R package:",
                a(
                  href = "https://urbio-ecology.github.io/urbioconnect/",
                  target = "_blank",
                  "urbio-ecology.github.io/urbioconnect"
                )
              )
            )
          )
        )
      )
    )
  )
}

ui <- page_navbar(
  title = "Urban Connectedness",
  # id so which panel is open is an input, settable without reaching for the
  # DOM. Outputs suspend while hidden, so a test has to open a panel to see it.
  id = "main_nav",
  theme = urbio_theme(),
  # Not Inputs: filling the window squeezed its three cards until the Run
  # button was clipped. It scrolls instead.
  fillable = c("Results", "Downloads"),

  header = tagList(
    shinyjs::useShinyjs(),
    # a spinner on every output while it recalculates, so a slow plot or table
    # reads as pending rather than missing
    useBusyIndicators(),
    tags$style(HTML(compare_css)),
    input_help_head
  ),

  # The app opens here, being the first panel
  nav_panel(
    title = "Before you start",
    icon = icon("compass"),
    layout_columns(
      col_widths = breakpoints(sm = 12, lg = c(-2, 8, -2)),
      card(
        card_body(
          p(
            class = "lead",
            "This app measures how well habitat is connected for a given",
            "species in an urban landscape, and how planned changes to",
            "habitat or urban environment would alter the connectedness. It",
            "uses the method from Kirk et al. (2023),",
            em(
              "Ecological connectivity as a planning tool for the",
              "conservation of wildlife in cities",
              .noWS = c("after", "inside")
            ),
            ", MethodsX 10, 101989 (",
            a(
              href = "https://doi.org/10.1016/j.mex.2022.101989",
              target = "_blank",
              "https://doi.org/10.1016/j.mex.2022.101989",
              .noWS = "outside"
            ),
            ")."
          ),
          p(
            "Animals move between patches of habitat, such as parks,",
            "bushland and creek corridors, and roads, railways and",
            "buildings get in the way. A planned change, such as a new",
            "road or a development, can cut patches off from each other."
          ),
          p(
            "You give it two maps, one of the habitat and one of the",
            "barriers, and a distance your species will cross open ground:",
            "the interpatch distance. The app grows every patch of habitat",
            "by half that distance on each side. Patches whose grown edges",
            "meet are joined into one connected patch, unless a barrier",
            "lies between them."
          ),
          p("Here is how that works on a small part of the lizard example."),
          # three across on a wide screen, two on a narrow one
          layout_columns(
            col_widths = breakpoints(sm = 6, lg = 4),
            method_figure(
              1,
              "1. Habitat and a road: a square of the lizard map, with patches of habitat above and below a grey road."
            ),
            method_figure(
              2,
              "2. Grow each patch by 50 m: the grown patches run together over the road and fill most of the square."
            ),
            method_figure(
              3,
              "3. The road cuts the grown area: the road laid over the grown patches splits them into a part above the road and a part below."
            ),
            method_figure(
              4,
              "4. Identify the patches: each piece of the cut grown area is one patch, the piece above the road in blue and the piece below it in gold."
            ),
            method_figure(
              5,
              "5. Two connected patches: the habitat above the road is one connected patch, in blue, and the habitat below it another, in gold."
            ),
            method_figure(
              6,
              "6. Zoom out to the whole map: the whole lizard map of roads and habitat, with the square outlined in orange, left of centre."
            )
          ),
          p(
            "Then it measures the connected patches: how many there are, and",
            "how much habitat you can reach from a point picked at random."
          ),
          # the skip for someone who has used it before, and a one-click start
          # for someone who hasn't
          div(
            class = "d-flex flex-wrap gap-2 mb-3",
            actionButton(
              inputId = "go_to_inputs",
              label = "Go to inputs",
              icon = icon("arrow-right"),
              class = "btn-primary"
            ),
            actionButton(
              inputId = "try_lizard",
              label = "Try the lizard example",
              icon = icon("play"),
              class = "btn-outline-primary"
            )
          ),
          p(
            "Preparing your data, choosing settings, comparing a scenario and",
            "reading the results are all in",
            strong(
              actionLink("go_to_details", "Details"),
              .noWS = c("after", "inside")
            ),
            "."
          )
        )
      )
    )
  ),

  # Inputs Panel
  nav_panel(
    title = "Inputs",
    icon = icon("upload"),
    layout_columns(
      col_widths = c(6, 6),

      # Left Column - File Uploads and Species
      card(
        card_header("Data Upload"),
        card_body(
          help_input(
            textInput,
            "species",
            value = "Superb Fairy Wren",
            placeholder = "Enter species name"
          ),

          help_input(
            fileInput,
            "habitat_file",
            accept = spatial_upload_accept,
            multiple = TRUE
          ),

          help_input(
            fileInput,
            "barrier_file",
            accept = spatial_upload_accept,
            multiple = TRUE
          ),

          # Two example landscapes, not one. The lizard is ~200x200 cells and
          # analyses in under a second; the wren is ~1500x1400 and takes tens
          # of seconds, so it is worth knowing which you are asking for.
          help_input(
            selectInput,
            "example_data",
            choices = example_data_choices,
            selected = "none"
          ),

          hr(),

          # A scenario is another layer you supply, so it belongs here with
          # the others. Each shipped one implies which layer it changes; only
          # an upload has to be told.
          # the supplied scenarios depend on the example data chosen above, so
          # the server fills these in rather than the list living here twice
          help_input(
            selectInput,
            "scenario_choice",
            choices = scenario_choices(NULL)
          ),

          conditionalPanel(
            condition = "input.scenario_choice == 'upload'",
            help_input(
              radioButtons,
              "scenario_kind",
              choices = c(
                "Barrier (a new road, say)" = "barrier",
                "Habitat (a development, say)" = "habitat"
              )
            ),
            help_input(
              fileInput,
              "scenario_file",
              accept = spatial_upload_accept,
              multiple = TRUE
            )
          )
        )
      ),

      # Right Column - Analysis Parameters
      card(
        card_header("Analysis Parameters"),
        card_body(
          help_input(
            numericInput,
            "data_resolution",
            value = input_defaults$data_resolution,
            min = 1,
            max = 100,
            step = 1
          ),

          numericInput(
            inputId = "target_resolution",
            label = "Target resolution (m)",
            value = 500,
            min = 1,
            max = 1000,
            step = 1
          ),

          help_input(
            textInput,
            "interpatch_distances",
            value = input_defaults$interpatch_distances,
            placeholder = "For example, 100, 250, 400"
          ),

          # the format has to be visible without opening the "i"
          helpText("Separate distances with commas.")
        )
      )
    ),

    # What the inputs add up to, just above the button that runs it
    layout_columns(
      col_widths = 12,
      card(
        card_header("Your analysis"),
        card_body(
          uiOutput("analysis_preview"),
          # The run shows its progress in a modal. A spinner on shiny-busy
          # here would flash on every keystroke, as the card above recalculates.
          actionButton(
            inputId = "run_analysis",
            label = "Run Analysis",
            icon = icon("play"),
            class = "btn-primary btn-lg w-100"
          )
        )
      )
    )
  ),

  # Results Panel
  nav_panel(
    title = "Results",
    icon = icon("chart-line"),

    # Loading indicator
    conditionalPanel(
      condition = "!output.results_ready",
      layout_column_wrap(
        card(
          card_body(
            div(
              class = "text-center p-5",
              h4("No results yet"),
              p("Upload data and run the analysis to see results here.")
            )
          )
        )
      )
    ),

    # Results content. Baseline and scenario get a tab each: a scenario is a
    # second analysis to read against the first, not more of the first.
    conditionalPanel(
      condition = "output.results_ready",
      # navset_tab, not navset_card_tab: that one wraps each panel in a
      # fillable card_body, which squeezes a long column of cards into the
      # viewport and collapses the ones furthest down to zero height. These
      # panels bring their own cards.
      navset_tab(
        # id so the tab shown is an input: readable in a test, and settable
        # without reaching for the DOM
        id = "results_view",
        nav_panel(
          title = "Baseline",

          # Habitat, Buffered Habitat, and Barrier
          layout_columns(
            col_widths = 12,
            card(
              card_header("Habitat, Buffered Habitat, and Barrier"),
              card_body(
                uiOutput("gg_barrier_habitat_buffer_tabs")
              )
            )
          ),

          # Patch ID
          layout_columns(
            col_widths = 12,
            card(
              card_header("Patch ID"),
              card_body(
                uiOutput("plot_patches_tabs")
              )
            )
          ),

          # Area and patch information for each interpatch distance
          layout_columns(
            col_widths = 12,
            card(
              card_header(
                "Area and patch information for each interpatch distance"
              ),
              card_body(
                DTOutput("summary_table")
              ),
              card_footer(
                downloadButton(
                  "download_areas_csv",
                  "Download CSV",
                  class = "btn-sm"
                )
              )
            )
          ),

          # Prob connectedness and summary information for each interpatch distance
          layout_columns(
            col_widths = 12,
            card(
              card_header(
                "Prob connectedness and summary information for each interpatch distance"
              ),
              card_body(
                DTOutput("results_connect_habitat_table")
              ),
              card_footer(
                downloadButton(
                  "download_summary_csv",
                  "Download CSV",
                  class = "btn-sm"
                )
              )
            )
          ),

          # Longer: Prob connectedness and summary information for each interpatch
          # distance
          layout_columns(
            col_widths = 12,
            card(
              card_header(
                "Longer: Prob connectedness and summary information for each interpatch distance"
              ),
              card_body(
                DTOutput("results_connect_habitat_longer_table")
              )
            )
          ),

          # Visualisation of changes in key stats over interpatch distance
          layout_columns(
            col_widths = 12,
            card(
              card_header(
                "Visualisation of changes in key stats over interpatch distance"
              ),
              card_body(
                plotOutput("plot_connectivity_output", height = "600px")
              ),
              card_footer(
                downloadButton(
                  "download_connectivity_plot",
                  "Download Plot",
                  class = "btn-sm"
                )
              )
            )
          )
        ),

        # The controls for this are an input, over on the Inputs tab; what
        # came of them is a result, so it belongs here.
        nav_panel(
          title = "Scenario",
          conditionalPanel(
            condition = "!output.has_comparison",
            div(
              class = "text-center p-5",
              h4("No scenario compared"),
              p(
                "Choose a scenario layer on the Inputs tab, then run the",
                "analysis."
              )
            )
          ),
          conditionalPanel(
            condition = "output.has_comparison",
            layout_columns(
              col_widths = 12,
              # the three layers the comparison was built from, before any of
              # it is combined into a map
              card(
                card_header("Input layers"),
                card_body(
                  p(
                    "The habitat and the barriers as analysed.",
                    "Plus scenario layer"
                  ),
                  layout_columns(
                    col_widths = c(4, 4, 4),
                    plotOutput("layer_habitat", height = "340px"),
                    plotOutput("layer_barrier", height = "340px"),
                    plotOutput("layer_scenario", height = "340px")
                  )
                )
              ),
              card(
                card_header("Scenario against baseline"),
                card_body(
                  p(
                    "One row per metric: the baseline, the scenario, and the",
                    "change."
                  ),
                  DTOutput("comparison_wide_table"),
                  hr(),
                  p(
                    "The comparison as produced from the analysis",
                    "it."
                  ),
                  DTOutput("comparison_long_table")
                )
              ),
              card(
                card_header("Habitat, Scenario, and Comparison"),
                card_body(
                  p(
                    "One tab per interpatch distance within each."
                  ),
                  navset_tab(
                    id = "landscape_view",
                    nav_panel(
                      title = "Baseline",
                      uiOutput("baseline_landscape_tabs")
                    ),
                    nav_panel(
                      title = "Scenario",
                      uiOutput("scenario_landscape_tabs")
                    ),
                    # diffviewer's widget, the one testthat shows for a
                    # changed snapshot: difference, toggle and slider in one
                    nav_panel(
                      title = "Compare",
                      uiOutput("landscape_compare_tabs")
                    )
                  )
                )
              )
            )
          )
        )
      )
    ),

    # Analysis Metadata ----
    layout_columns(
      col_widths = 12,
      card(
        card_header(
          class = "bg-info text-white",
          "Analysis Information"
        ),
        card_body(
          layout_columns(
            col_widths = c(4, 4, 4),
            div(
              strong("Species: "),
              textOutput("analysis_species", inline = TRUE)
            ),
            div(
              strong("Run Time: "),
              textOutput("analysis_timestamp", inline = TRUE)
            ),
            div(
              strong("Session: "),
              textOutput("analysis_session", inline = TRUE)
            )
          ),
          layout_columns(
            col_widths = c(4, 8),
            div(
              strong("Interpatch Distances: "),
              textOutput("analysis_buffers", inline = TRUE)
            ),
            div(
              strong("Working Directory: "),
              code(textOutput("analysis_workdir", inline = TRUE))
            )
          )
        ),
        card_footer(
          # this card shows before a run, so the button is guarded, not a panel
          conditionalPanel(
            condition = "output.results_ready",
            downloadButton(
              "download_settings_csv",
              "Download settings CSV",
              class = "btn-sm"
            )
          )
        )
      )
    )
  ),

  nav_panel(
    title = "Downloads",
    icon = icon("download"),
    # Spatial Downloads
    layout_columns(
      col_widths = 12,
      card(
        card_header("Spatial Data Downloads"),
        card_body(
          p("Download spatial layers for use in GIS software:"),
          downloadButton(
            "download_raster",
            "Download Raster (GeoTIFF)",
            class = "btn-outline-primary w-100"
          )
        )
      ),
      # Reports. These are the only downloads that need Quarto, so they are
      # the only ones switched off without it; everything else still works.
      card(
        card_header("Reports"),
        card_body(
          p(
            "One document holding every map, table and summary.",
            "Rendering takes a moment."
          ),
          layout_columns(
            col_widths = c(4, 4, 4),
            report_button("download_report_html", "Report (HTML)"),
            report_button("download_report_pdf", "Report (PDF)"),
            report_button("download_reports_zip", "Both (ZIP)")
          ),
          if (!has_quarto) {
            div(
              class = "alert alert-warning mt-2 mb-0",
              strong("Reports need Quarto."),
              " It isn't installed where this app is running, so the three",
              " buttons above are switched off. Every other download works.",
              " See ",
              a(
                href = "https://quarto.org/docs/get-started/",
                target = "_blank",
                "quarto.org"
              ),
              "."
            )
          }
        )
      ),
      # Everything, in one archive
      card(
        card_header("Download your results"),
        card_body(
          p(
            "One archive holding every map, table and GIS layer below,",
            "in a folder for each interpatch distance, with a README",
            "explaining each file."
          ),
          downloadButton(
            "download_everything",
            "Download everything (ZIP)",
            class = "btn-primary btn-lg w-100"
          )
        )
      )
    )
  ),

  details_panel()
)
