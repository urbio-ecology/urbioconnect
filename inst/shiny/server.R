# Apply a connectivity_display() digit spec to a DT. DT formats cell by cell,
# so the values stay numeric and therefore sortable, which is why the package
# describes the rounding rather than applying it.
dt_format <- function(table, digits) {
  purrr::reduce(
    seq_len(nrow(digits)),
    function(formatted, i) {
      rule <- digits[i, ]
      format_fn <- if (rule$kind == "signif") formatSignif else formatRound
      format_fn(formatted, columns = rule$column, digits = rule$digits)
    },
    .init = table
  )
}

# A connectivity_display() as a DT: its labelled data, formatted to the digits
# it asks for. Every display-backed table in the app wants this, so the DT
# options are all a caller has to give.
display_dt <- function(display, ...) {
  DT::datatable(
    display$data,
    options = list(scrollX = TRUE, ...),
    rownames = FALSE
  ) |>
    dt_format(display$digits)
}

server <- function(input, output, session) {
  # The example dataset in use, or NULL when the layers are being uploaded. A
  # plain function, like chosen_scenario(): it is a list lookup, so there is
  # nothing for a reactive to cache, and a reactive can only be read from
  # inside a reactive context.
  chosen_dataset <- function() {
    example_datasets[[input$example_data %||% ""]]
  }

  # For the settings record: the example dataset, or every file uploaded
  layer_source <- function(file_input) {
    if (!is.null(chosen_dataset())) {
      return(paste0("example data: ", input$example_data))
    }

    paste(file_input$name, collapse = ", ")
  }

  # The name of an upload: its .shp when there is one, else its first file.
  main_file_name <- function(file_input) {
    shp <- grepl("\\.shp$", file_input$name, ignore.case = TRUE)
    if (any(shp)) file_input$name[shp][1] else file_input$name[1]
  }

  # Choosing an example fills in its species and takes over the file inputs;
  # the scenarios on offer are that dataset's, since a scenario is only
  # comparable against the landscape it was drawn on. Not at startup: the page
  # already matches "none", and a late update there put a scenario chosen in
  # the meantime back to "none".
  observeEvent(input$example_data, ignoreInit = TRUE, {
    dataset <- chosen_dataset()
    using_example <- !is.null(dataset)

    if (using_example) {
      updateTextInput(session, "species", value = dataset$species)
    }

    updateSelectInput(
      session,
      "scenario_choice",
      choices = scenario_choices(input$example_data)
    )

    # dimmed as well as disabled: a disabled file input's Browse button still
    # looks clickable
    purrr::walk(
      c("species", "habitat_file", "barrier_file"),
      function(id) {
        shinyjs::toggleState(id, condition = !using_example)
        shinyjs::toggleClass(
          selector = glue(".form-group:has(#{id})"),
          class = "opacity-50",
          condition = using_example
        )
      }
    )
  })

  # Parse interpatch distances ----
  interpatch_distances_parsed <- reactive({
    # not req(), so an empty box reaches the "at least one" check below, which
    # says what is wrong
    entries <- extract_interpatch_distances(input$interpatch_distances)
    distances <- suppressWarnings(as.numeric(entries))
    unparsed <- entries[is.na(distances)]

    # separate from the checks below, which can't run on NA and would
    # otherwise add a second message
    validate(need(
      length(unparsed) == 0,
      paste0(
        "Interpatch distances must be numbers, and ",
        paste0('"', unparsed, '"', collapse = ", "),
        if (length(unparsed) == 1) " isn't." else " aren't."
      )
    ))

    validate(
      need(
        length(distances) > 0,
        "Please enter at least one valid interpatch distance"
      ),
      need(all(distances > 0), "Interpatch distances must be positive numbers"),
      # "Inf" and "1e999" both parse as numbers
      need(all(is.finite(distances)), "Interpatch distances must be finite")
    )

    distances
  })

  # Before you start ----

  observeEvent(input$go_to_inputs, nav_select("main_nav", "Inputs"))
  observeEvent(input$go_to_details, nav_select("main_nav", "Details"))

  # straight to a landscape that runs in a second, ready to click Run
  observeEvent(input$try_lizard, {
    updateSelectInput(session, "example_data", selected = "lizard")
    nav_select("main_nav", "Inputs")
  })

  # Cell size example ----

  cell_size_img <- function() {
    req(input$data_resolution)
    figure <- nearest_cell_size_figure(input$data_resolution, cell_size_figures)
    img(src = figure$file, alt = figure$alt, class = "img-fluid")
  }
  output$cell_size_figure_inputs <- renderUI(cell_size_img())
  output$cell_size_figure_details <- renderUI(cell_size_img())

  # Your analysis ----

  # The layers, as the Your analysis card names them. NULL until there are
  # two to analyse.
  preview_data <- function() {
    dataset <- chosen_dataset()

    if (!is.null(dataset)) {
      return(paste(dataset$species, "example data"))
    }

    if (is.null(input$habitat_file) || is.null(input$barrier_file)) {
      return(NULL)
    }

    paste0(
      "Your habitat layer (",
      main_file_name(input$habitat_file),
      ") and barrier layer (",
      main_file_name(input$barrier_file),
      ")"
    )
  }

  # Rewritten as the inputs change; the browser debounces typing. It reads
  # the parser the run reads, so the two agree on the distances, and reads no
  # layer from disk.
  output$analysis_preview <- renderUI({
    # one at a time: the second can't be asked of an empty box
    validate(need(
      input$data_resolution,
      "Enter a data resolution to see what the analysis will do."
    ))
    validate(need(
      input$data_resolution > 0,
      "Data resolution must be more than 0 m."
    ))

    analysis_preview(describe_analysis(
      data = preview_data(),
      data_resolution = input$data_resolution,
      distances = interpatch_distances_parsed(),
      scenario = scenario_details()
    ))
  })

  # Read uploaded files ----
  read_uploaded_file <- function(file_input) {
    req(file_input)

    # Handle shapefiles (multiple files required)
    if (any(grepl("\\.shp$", file_input$name, ignore.case = TRUE))) {
      # Create a temporary directory for this shapefile
      temp_dir <- file.path(
        tempdir(),
        paste0("shp_", format(Sys.time(), "%Y%m%d_%H%M%S"))
      )
      dir.create(temp_dir, showWarnings = FALSE, recursive = TRUE)

      # Copy all uploaded files to temp directory with original names
      for (i in seq_along(file_input$datapath)) {
        file.copy(
          file_input$datapath[i],
          file.path(temp_dir, file_input$name[i]),
          overwrite = TRUE
        )
      }

      # Find the .shp file
      shp_file <- file.path(
        temp_dir,
        file_input$name[grepl("\\.shp$", file_input$name, ignore.case = TRUE)]
      )

      # Check if we have the required files
      base_name <- tools::file_path_sans_ext(basename(shp_file))
      present_files <- list.files(
        temp_dir,
        pattern = paste0("^", base_name),
        full.names = TRUE
      )

      if (length(present_files) < 3) {
        cli::cli_abort(
          "Shapefile upload incomplete. Please upload all required files \\
          (.shp, .shx, .dbf, and optionally .prj)"
        )
      }

      # Read the shapefile
      data <- st_read(shp_file, quiet = TRUE)
    } else if (
      any(grepl("\\.(tif|tiff)$", file_input$name, ignore.case = TRUE))
    ) {
      # Handle raster files
      data <- terra::rast(file_input$datapath[1])
    } else if (
      # .gpkg is offered by every file input, and is what the app's own GIS
      # downloads are written as, so an upload of one has to read
      any(grepl("\\.(geojson|gpkg)$", file_input$name, ignore.case = TRUE))
    ) {
      data <- st_read(file_input$datapath[1], quiet = TRUE)
    } else {
      cli::cli_abort(
        c(
          "File format must be a shapefile",
          "i" = "(.shp + .shx + .dbf), GeoTIFF (.tif), GeoJSON (.geojson) or
                 GeoPackage (.gpkg)",
          "We see: {.path {file_input$name}}"
        )
      )
    }

    data
  }

  # Main analysis ----

  # Everything the last Run produced, as one connectivity_report_data: the
  # summary, the layers each distance produced, and the scenario landscape
  # beside them. Every output is drawn from it, so none mixes two runs, and it
  # is what the reports and the asset bundle are written from. Before a run,
  # and after one that fails, it gives a silent error, which empties every
  # output that reads it.
  analysis <- eventReactive(input$run_analysis, {
    showModal(modalDialog(
      title = "Running Analysis",
      "Processing your data... This may take a few moments.",
      easyClose = FALSE,
      footer = NULL
    ))
    on.exit(removeModal())

    tryCatch(
      {
        check_scenario_choice()
        # before the layers are read, so a bad box fails at once
        distances <- interpatch_distances_parsed()

        # withProgress() returns its block's value: the
        # connectivity_report_data() at the end of it
        report_data <- withProgress(message = "Loading data...", value = 0.1, {
          # An example dataset brings its own layers; otherwise they are
          # uploaded. Either way they go through prepare_rasters() below, so
          # the resolution control means the same thing for both.
          dataset <- chosen_dataset()

          if (!is.null(dataset)) {
            habitat_data <- dataset$habitat()
            barrier_data <- dataset$barrier()
          } else {
            if (is.null(input$habitat_file) || is.null(input$barrier_file)) {
              cli::cli_abort(c(
                "No habitat and barrier layers to analyse.",
                "i" = "Upload both, or pick one of the example datasets."
              ))
            }
            habitat_data <- read_uploaded_file(input$habitat_file)
            barrier_data <- read_uploaded_file(input$barrier_file)
          }

          incProgress(0.2, message = "Preparing rasters...")

          rasters <- prepare_rasters(
            habitat = habitat_data,
            barrier = barrier_data,
            data_resolution = input$data_resolution
          )

          incProgress(0.3, message = "Calculating connectivity...")

          scenario <- chosen_scenario()

          if (!is.null(scenario)) {
            incProgress(0, message = "Comparing scenario to baseline...")
          }

          # the "Which layer does it change?" choice picks the argument; with
          # no scenario both stay NULL
          scenario_changes_habitat <- identical(scenario$kind, "habitat")
          scenario_changes_barrier <- identical(scenario$kind, "barrier")
          habitat_scenario <- if (scenario_changes_habitat) scenario$layer
          barrier_scenario <- if (scenario_changes_barrier) scenario$layer

          # A scenario goes in here rather than being compared separately, so
          # the baseline pipeline runs once rather than once for the analysis
          # and again for the comparison.
          connectivity_report_data(
            habitat = rasters$habitat_raster,
            barrier = rasters$barrier_raster,
            species = input$species,
            interpatch_distance = distances,
            habitat_scenario = habitat_scenario,
            barrier_scenario = barrier_scenario,
            scenario_name = scenario$name,
            settings = list(
              habitat_source = layer_source(input$habitat_file),
              barrier_source = layer_source(input$barrier_file),
              data_resolution_m = input$data_resolution
            ),
            verbose = FALSE
          )
        })

        showNotification("Analysis complete!", type = "message", duration = 3)
        report_data
      },
      error = function(e) {
        showNotification(
          paste("Error:", conditionMessage(e)),
          type = "error",
          duration = NULL
        )
        # silent, so it empties the outputs rather than printing in each one,
        # and doesn't end the session from the observers below
        req(FALSE)
      }
    )
  })

  # Output: Results ready flag ----

  # Never suspended, so the analysis runs when Run is clicked even with Results
  # closed: an eventReactive waits until something reads it. A conditionalPanel
  # reads its silent error as false.
  output$results_ready <- reactive(isTruthy(analysis()))
  outputOptions(output, "results_ready", suspendWhenHidden = FALSE)

  # Output: Analysis Metadata ----
  output$analysis_species <- renderText(analysis()$species)

  output$analysis_timestamp <- renderText({
    format(analysis()$run_time, "%Y-%m-%d %H:%M:%S %Z")
  })

  output$analysis_session <- renderText({
    req(analysis())
    paste0("R ", getRversion(), " on ", Sys.info()["sysname"])
  })

  output$analysis_buffers <- renderText({
    paste(analysis()$interpatch_distance, collapse = ", ")
  })

  output$analysis_workdir <- renderText({
    req(analysis())
    getwd()
  })

  # every tabbed view of the analysis has a tab per distance the last run used
  run_distances <- reactive(analysis()$interpatch_distance)

  # One landscape at one distance. The baseline maps and both sides of a
  # comparison are all drawn with this, so the only difference you see between
  # two of them is the one the scenario made.
  landscape_plot <- function(habitat, barrier, buffered, distance, species) {
    gg_barrier_habitat_interpatch_dist(
      barrier = barrier,
      buffered = buffered,
      habitat = habitat,
      interpatch_distance = distance,
      species = species,
      col_paper = "grey96"
    )
  }

  # the run's own landscape, on its own and as a comparison's baseline
  baseline_landscape <- function(data, distance) {
    landscape_plot(
      data$habitat,
      data$barrier,
      data$buffered_habitat[[as.character(distance)]],
      distance,
      data$species
    )
  }

  # Output: Habitat, Buffered Habitat, and Barrier - Tabbed Plots ----
  distance_tabs_server("barrier_habitat", run_distances, function(distance) {
    baseline_landscape(analysis(), distance)
  })

  # Output: Patch ID - Tabbed Plots ----
  distance_tabs_server("patches", run_distances, function(distance) {
    data <- analysis()
    key <- as.character(distance)
    plot_patches(
      patch_id = data$patch_id_raster[[key]],
      interpatch_distance = distance,
      species = data$species,
      barrier = data$barrier,
      buffered = data$buffered_habitat[[key]],
      directions = data$directions
    )
  })

  # every distance's patches in one table, for the table and its CSV
  patch_areas <- reactive({
    data <- analysis()

    patch_sizes(data$connectivity) |>
      setNames(data$interpatch_distance) |>
      bind_rows(.id = "interpatch")
  })

  # Output: Area and patch information table (combined from all buffers) ----
  output$summary_table <- renderDT({
    patch_areas() |>
      datatable(
        options = list(
          pageLength = 10,
          scrollX = TRUE
        ),
        rownames = FALSE
      )
  })

  # Output: Connectivity summary table ----
  output$results_connect_habitat_table <- renderDT({
    display_dt(
      connectivity_display(analysis()$connectivity),
      pageLength = 10,
      dom = "tip"
    )
  })

  # Output: Longer format prob connectedness table ----
  output$results_connect_habitat_longer_table <- renderDT({
    # the labels and which columns identify a row both come from the package,
    # so renaming one doesn't break this. One column of every metric needs
    # significant figures rather than the per-column rules.
    display <- connectivity_display(analysis()$connectivity)

    display$data |>
      pivot_longer(
        cols = -all_of(display_ids(display)),
        names_to = "Metric",
        values_to = "Value"
      ) |>
      datatable(
        options = list(
          pageLength = 8,
          scrollX = TRUE
        ),
        rownames = FALSE
      ) |>
      formatSignif(columns = "Value", digits = 3)
  })

  # Output: Visualization of connectivity changes ----
  output$plot_connectivity_output <- renderPlot({
    plot_connectivity(analysis()$connectivity)
  })

  # Downloads ----

  # A download named after the analysis. filename runs before content, so it
  # is what stops a download before there is an analysis to name it after.
  stem_filename <- function(suffix) {
    force(suffix)

    function() {
      paste0(connectivity_file_stem(analysis()), suffix)
    }
  }

  output$download_summary_csv <- downloadHandler(
    filename = function() {
      paste0("connectivity_summary_", Sys.Date(), ".csv")
    },
    content = function(file) {
      # patch_size is a list-column of per-patch tables; it writes as an empty
      # column. The per-patch data has its own download.
      analysis()$connectivity |>
        select(-patch_size) |>
        write_csv(file)
    }
  )

  # the patch ids behind the patch map, one layer per distance
  output$download_raster <- downloadHandler(
    filename = stem_filename("-patches.tif"),
    content = function(file) {
      data <- analysis()
      patches <- terra::rast(map(data$patch_id_raster, \(x) x[["patch_id"]]))
      names(patches) <- glue("interpatch-{data$interpatch_distance}m")
      terra::writeRaster(patches, file, overwrite = TRUE)
    }
  )

  # Download connectivity plot (using plot_connectivity function) ----
  output$download_connectivity_plot <- downloadHandler(
    filename = stem_filename("-over-distance.png"),
    content = function(file) {
      # the same size the zip and the report use, from urbio_figure_size()
      size <- urbio_figure_size()
      ggsave(
        filename = file,
        plot = plot_connectivity(analysis()$connectivity),
        width = size$width,
        height = size$tall_height,
        dpi = size$dpi,
        bg = "white"
      )
    }
  )

  # Download terra areas CSV ----
  output$download_areas_csv <- downloadHandler(
    filename = stem_filename("-areas.csv"),
    content = function(file) {
      write_csv(patch_areas(), file)
    }
  )

  # Download the settings CSV ----
  output$download_settings_csv <- downloadHandler(
    filename = stem_filename("-settings.csv"),
    content = function(file) {
      write_csv(connectivity_settings(analysis()), file, na = "")
    }
  )

  # Scenarios ----

  # A supplied scenario belongs to the example dataset it was drawn on. The
  # dropdown only offers the chosen dataset's, so this is reachable by driving
  # the inputs directly rather than by clicking. There is no longer anything
  # to say about resolution: connectivity_report_data() puts a scenario on
  # whatever grid is in use.
  check_scenario_choice <- function() {
    choice <- input$scenario_choice %||% "none"

    if (choice == "none") {
      return(invisible())
    }

    if (choice == "upload") {
      if (is.null(input$scenario_file)) {
        cli::cli_abort(c(
          "No scenario file chosen.",
          "i" = "Upload one under {.field Your scenario layer}, or pick one of
                 the supplied scenarios, or set it back to {.field None}."
        ))
      }
      return(invisible())
    }

    if (is.null(chosen_dataset()$scenarios[[choice]])) {
      cli::cli_abort(c(
        "The {.val {choice}} scenario doesn't go with these layers.",
        "x" = "A supplied scenario belongs to the example dataset it was
               drawn on.",
        "i" = "Choose that dataset under {.field Example data}, or
               {.field Upload my own} scenario covering your own layers."
      ))
    }

    invisible()
  }

  # Which layer a scenario changes, its name, and a function that reads the
  # layer. Each supplied scenario says its own kind; only an upload has to be
  # told. NULL when no scenario is chosen. Nothing is read here, so the Your
  # analysis card can name a scenario without loading it.
  scenario_details <- function() {
    choice <- input$scenario_choice %||% "none"

    if (choice == "none") {
      return(NULL)
    }

    if (choice == "upload") {
      file <- input$scenario_file
      return(list(
        read_layer = \() read_uploaded_file(file),
        kind = input$scenario_kind,
        name = if (!is.null(file)) main_file_name(file)
      ))
    }

    supplied <- chosen_dataset()$scenarios[[choice]]

    # a choice left over from the other dataset, until the dropdown catches
    # up. A run never gets here: check_scenario_choice() stops it first.
    if (is.null(supplied)) {
      return(NULL)
    }

    list(
      read_layer = supplied$layer,
      kind = supplied$kind,
      name = supplied$label
    )
  }

  # The scenario a run compares: its layer, read, and what it is
  chosen_scenario <- function() {
    scenario <- scenario_details()

    if (is.null(scenario)) {
      return(NULL)
    }

    list(
      layer = scenario$read_layer(),
      kind = scenario$kind,
      name = scenario$name
    )
  }

  # drives the Results tab's scenario section, which stays hidden until there
  # is a comparison to show
  output$has_comparison <- reactive(!is.null(analysis()$comparison))
  outputOptions(output, "has_comparison", suspendWhenHidden = FALSE)

  # a silent error when the run had no scenario, so its outputs stay empty
  comparison <- reactive(req(analysis()$comparison))

  output$comparison_plot <- renderPlot(
    plot_connectivity(comparison()),
    alt = "Baseline and scenario metrics across interpatch distances"
  )

  output$download_comparison_plot <- downloadHandler(
    filename = stem_filename("-scenario-comparison.png"),
    content = function(file) {
      size <- urbio_figure_size()
      ggsave(
        filename = file,
        plot = plot_connectivity(comparison()),
        width = size$width,
        height = size$tall_height,
        dpi = size$dpi,
        bg = "white"
      )
    }
  )

  output$comparison_wide_table <- renderDT({
    display_dt(
      connectivity_display(comparison()),
      pageLength = 10,
      dom = "t"
    )
  })

  output$comparison_long_table <- renderDT({
    display_dt(
      connectivity_display(comparison(), wide = FALSE),
      pageLength = 8
    )
  })

  # What went into the comparison, one layer at a time: the two baseline
  # inputs and the scenario standing in for one of them.
  output$layer_habitat <- renderPlot(gg_layer(analysis()$habitat, "habitat"))

  output$layer_barrier <- renderPlot(gg_layer(analysis()$barrier, "barrier"))

  output$layer_scenario <- renderPlot({
    data <- analysis()
    kind <- req(data$scenario_kind)

    gg_layer(scenario_layer(data), kind, title = paste0("Scenario: ", kind))
  })

  # diffviewer compares two files rather than two plots, so each side is
  # written out. Square and named for what it is: the widget puts the old
  # file's name in its header.
  landscape_png <- function(plot, side, distance) {
    path <- file.path(
      compare_png_dir,
      paste0("interpatch-", distance, "m-", side, ".png")
    )
    ggsave(
      path,
      plot,
      width = compare_png_inches,
      height = compare_png_inches,
      dpi = compare_png_dpi
    )
    path
  }

  # both sides at each distance, built once for their tabs and the PNGs
  compared_landscapes <- reactive({
    data <- analysis()
    req(data$comparison)

    map(setNames(nm = data$interpatch_distance), function(distance) {
      list(
        baseline = baseline_landscape(data, distance),
        scenario = landscape_plot(
          data$scenario_habitat,
          data$scenario_barrier,
          data$scenario_buffered_habitat[[as.character(distance)]],
          distance,
          data$species
        )
      )
    })
  })

  observe({
    iwalk(compared_landscapes(), function(pair, distance) {
      output[[paste0("compare_", distance)]] <- visual_diff_render(
        visual_diff(
          landscape_png(pair$baseline, "baseline", distance),
          landscape_png(pair$scenario, "scenario", distance)
        )
      )
    })
  })

  # One tab per distance, for each way of looking at the pair.
  compared_distances <- reactive({
    req(comparison())
    run_distances()
  })

  distance_tabs_server(
    "baseline_landscape",
    compared_distances,
    function(distance) {
      pair <- compared_landscapes()[[as.character(distance)]]
      pair$baseline
    }
  )
  distance_tabs_server(
    "scenario_landscape",
    compared_distances,
    function(distance) {
      pair <- compared_landscapes()[[as.character(distance)]]
      pair$scenario
    }
  )
  output$landscape_compare_tabs <- renderUI({
    distance_navset(
      "compare_distance",
      compared_distances(),
      function(distance) {
        visual_diff_output(paste0("compare_", distance), height = "720px")
      }
    )
  })

  # Everything: maps, tables, GIS layers and the reports
  output$download_everything <- downloadHandler(
    filename = function() {
      paste0("connectivity-", Sys.Date(), ".zip")
    },
    content = function(file) {
      withProgress(message = "Preparing your download...", value = 0.3, {
        zip_connectivity_assets(analysis(), file)
      })
    }
  )

  # Reports ----

  # shiny names the download file itself, with no extension to read a format
  # from, so the format is passed explicitly and the report renders straight
  # into it
  report_download <- function(extension) {
    force(extension)

    downloadHandler(
      filename = stem_filename(paste0(".", extension)),
      content = function(file) {
        withProgress(message = "Rendering your report...", value = 0.3, {
          generate_connectivity_report(analysis(), file, format = extension)
        })
      }
    )
  }

  output$download_report_html <- report_download("html")
  output$download_report_pdf <- report_download("pdf")

  output$download_reports_zip <- downloadHandler(
    filename = stem_filename("-reports.zip"),
    content = function(file) {
      withProgress(message = "Rendering both reports...", value = 0.3, {
        zip_connectivity_reports(analysis(), file)
      })
    }
  )
}
