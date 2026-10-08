# Quarto is separate software and may not be installed where the app runs.
# Asked once here, not per session: it can't change while the app is up.
has_quarto <- quarto_available()

# A download button that is dead unless Quarto is there to render with
report_button <- function(id, label) {
  button <- downloadButton(id, label, class = "btn-outline-success w-100")
  if (has_quarto) button else shinyjs::disabled(button)
}

ui <- page_navbar(
  title = "Urban Connectedness",
  # id so which panel is open is an input, settable without reaching for the
  # DOM. Outputs suspend while hidden, so a test has to open a panel to see it.
  id = "main_nav",
  theme = urbio_theme(),
  fillable = TRUE,

  header = tagList(
    shinyjs::useShinyjs(),
    # a spinner on every output while it recalculates, so a slow plot or table
    # reads as pending rather than missing
    useBusyIndicators(),
    tags$style(HTML(compare_css))
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
          textInput(
            inputId = "species",
            label = "Species Name",
            value = "Superb Fairy Wren",
            placeholder = "Enter species name"
          ),

          fileInput(
            inputId = "habitat_file",
            label = "Habitat Layer",
            accept = spatial_upload_accept,
            multiple = TRUE
          ),

          fileInput(
            inputId = "barrier_file",
            label = "Barrier Layer",
            accept = spatial_upload_accept,
            multiple = TRUE
          ),

          # Two example landscapes, not one. The lizard is ~200x200 cells and
          # analyses in under a second; the wren is ~1500x1400 and takes tens
          # of seconds, so it is worth knowing which you are asking for.
          selectInput(
            inputId = "example_data",
            label = "Example data",
            choices = example_data_choices,
            selected = "none"
          ),

          hr(),

          # A scenario is another layer you supply, so it belongs here with
          # the others. Each shipped one implies which layer it changes; only
          # an upload has to be told.
          # the supplied scenarios depend on the example data chosen above, so
          # the server fills these in rather than the list living here twice
          selectInput(
            inputId = "scenario_choice",
            label = "Scenario Layer (optional)",
            choices = scenario_choices(NULL)
          ),

          conditionalPanel(
            condition = "input.scenario_choice == 'upload'",
            radioButtons(
              inputId = "scenario_kind",
              label = "Which layer does your scenario change?",
              choices = c(
                "Barrier (a new road, say)" = "barrier",
                "Habitat (a development, say)" = "habitat"
              )
            ),
            fileInput(
              inputId = "scenario_file",
              label = "Scenario Layer",
              accept = spatial_upload_accept,
              multiple = TRUE
            )
          ),

          helpText(
            "A scenario changes one layer and leaves the rest of the",
            "landscape alone, so the difference in connectivity is",
            "attributable to that change. It is compared at the same",
            "interpatch distances as the baseline."
          )
        )
      ),

      # Right Column - Analysis Parameters
      card(
        card_header("Analysis Parameters"),
        card_body(
          numericInput(
            inputId = "data_resolution",
            label = "Data resolution (m)",
            value = 10,
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

          textInput(
            inputId = "interpatch_distances",
            label = "Interpatch Distances (m)",
            value = "100",
            placeholder = "e.g., 50, 100, 200"
          ),

          helpText(
            "Enter interpatch distances as comma-separated values.",
            "These represent the maximum dispersal distances to analyze."
          )
        )
      )
    ),

    # Action Button - Full Width
    layout_columns(
      col_widths = 12,
      card(
        card_body(
          actionButton(
            inputId = "run_analysis",
            label = "Run Analysis",
            icon = icon("play"),
            class = "btn-primary btn-lg w-100"
          ),

          conditionalPanel(
            condition = "$('html').hasClass('shiny-busy')",
            div(
              class = "text-center mt-3",
              div(class = "spinner-border text-primary", role = "status"),
              p(class = "mt-2", "Analysis in progress...")
            )
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

  # About Panel
  nav_panel(
    title = "About",
    icon = icon("info-circle"),
    layout_columns(
      col_widths = 12,
      card(
        card_header("Urban Biodiversity Connectivity Analysis"),
        card_body(
          h4("Overview"),
          p(
            "This application analyzes habitat connectivity for urban \\
            biodiversity.",
            "It calculates how habitat patches are connected across different \\
            interpatch distances,",
            "accounting for barriers like roads and urban infrastructure."
          ),
          hr(),
          h4("How It Works"),
          tags$ol(
            tags$li("Upload habitat and barrier raster data"),
            tags$li("Specify species name and interpatch distances"),
            tags$li("Run the analysis to calculate connectivity metrics"),
            tags$li(
              "View results including patch ID and connectivity statistics"
            ),
            tags$li("Download results and reports")
          ),
          hr(),
          h4("File Upload Guide"),

          h5("Uploading Shapefiles"),
          p(
            strong("Important:"),
            "Shapefiles consist of multiple files; upload all required files:"
          ),

          tags$div(
            class = "ms-3",
            h6("Required Files"),
            tags$ul(
              tags$li(tags$code(".shp"), " - Main file containing geometry"),
              tags$li(tags$code(".shx"), " - Shape index file"),
              tags$li(tags$code(".dbf"), " - Attribute database file")
            ),

            h6("Optional (but recommended)"),
            tags$ul(
              tags$li(tags$code(".prj"), " - Projection information"),
              tags$li(tags$code(".cpg"), " - Character encoding")
            )
          ),

          h5("How to Upload in the App"),
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

          h5("Common Errors"),
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

          h5("Alternative Formats"),
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
          ),

          hr(),
          h4("Metrics Calculated"),
          tags$ul(
            tags$li(
              strong("Probability of Connectedness:"),
              " Overall habitat connectivity"
            ),
            tags$li(
              strong("Number of Patches:"),
              " Count of distinct habitat patches"
            ),
            tags$li(
              strong("Effective Mesh Size:"),
              " Measure of landscape fragmentation"
            ),
            tags$li(
              strong("Mean Patch Area:"),
              " Average size of habitat patches"
            ),
            tags$li(
              strong("Total Patch Area:"),
              " Sum of all habitat patch areas"
            )
          ),
          hr(),
          p(
            class = "text-muted",
            "Built with R, Shiny, and the terra package for spatial analysis."
          )
        )
      )
    )
  )
)
