ui <- page_navbar(
  title = "Urban Connectedness",
  theme = urbio_theme(),
  fillable = TRUE,

  header = shinyjs::useShinyjs(),

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
            accept = c(
              ".shp",
              ".tif",
              ".tiff",
              ".geojson",
              ".gpkg",
              ".shx",
              ".dbf",
              ".prj",
              ".cpg"
            ),
            multiple = TRUE
          ),

          fileInput(
            inputId = "barrier_file",
            label = "Barrier Layer",
            accept = c(
              ".shp",
              ".tif",
              ".tiff",
              ".geojson",
              ".gpkg",
              ".shx",
              ".dbf",
              ".prj",
              ".cpg"
            ),
            multiple = TRUE
          ),

          checkboxInput(
            inputId = "use_example_data",
            label = "Use Example Data",
            value = FALSE
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

    # Results content
    conditionalPanel(
      condition = "output.results_ready",

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
              col_widths = c(6, 6),
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
      ),

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

      # Everything, in one archive
      layout_columns(
        col_widths = 12,
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
      ),

      # Spatial Downloads
      layout_columns(
        col_widths = 12,
        card(
          card_header("Spatial Data Downloads"),
          card_body(
            p("Download spatial layers for use in GIS software:"),
            layout_columns(
              col_widths = c(4, 4, 4),
              downloadButton(
                "download_raster",
                "Download Raster (GeoTIFF)",
                class = "btn-outline-primary w-100"
              ),
              downloadButton(
                "download_report_html",
                "Download Report (HTML)",
                class = "btn-outline-success w-100"
              ),
              downloadButton(
                "download_report_pdf",
                "Download Report (PDF)",
                class = "btn-outline-success w-100"
              )
            )
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
  ),
)
