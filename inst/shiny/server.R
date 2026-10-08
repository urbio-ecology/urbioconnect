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

  # Choosing an example fills in its species and takes over the file inputs;
  # the scenarios on offer are that dataset's, since a scenario is only
  # comparable against the landscape it was drawn on.
  observeEvent(input$example_data, {
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

    purrr::walk(
      c("species", "habitat_file", "barrier_file"),
      function(id) {
        if (using_example) {
          shinyjs::disable(id)
        } else {
          shinyjs::enable(id)
        }
        shinyjs::runjs(sprintf(
          "$('#%s').closest('.form-group').css('opacity', '%s');",
          id,
          if (using_example) "0.5" else "1"
        ))
      }
    )
  })
  # Reactive values to store results ----
  results <- reactiveValues(
    ready = FALSE,
    report_data = NULL,
    habitat_raster = NULL,
    barrier_raster = NULL,
    buffered_habitat = NULL,
    patch_id_raster = NULL,
    interpatch_distances = NULL,
    results_connect_habitat = NULL,
    areas_connected = NULL,
    analysis_time = NULL,
    comparison = NULL,
    scenario_layer = NULL,
    scenario_kind = NULL,
    scenario_habitat = NULL,
    scenario_barrier = NULL,
    scenario_buffered = NULL
  )

  # Parse interpatch distances ----
  interpatch_distances_parsed <- reactive({
    req(input$interpatch_distances)
    distances_text <- input$interpatch_distances
    distances <- as.numeric(unlist(strsplit(distances_text, ",")))
    distances <- distances[!is.na(distances)]

    validate(
      need(
        length(distances) > 0,
        "Please enter at least one valid interpatch distance"
      ),
      need(all(distances > 0), "Unterpatch distances must be positive numbers")
    )

    distances
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
  observeEvent(input$run_analysis, {
    # Show modal with progress
    showModal(modalDialog(
      title = "Running Analysis",
      "Processing your data... This may take a few moments.",
      easyClose = FALSE,
      footer = NULL
    ))

    tryCatch(
      {
        check_scenario_choice()

        # Read files
        withProgress(message = "Loading data...", value = 0.1, {
          # An example dataset brings its own layers; otherwise they are
          # uploaded. Either way they go through prepare_rasters() below, so
          # the resolution controls mean the same thing for both.
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

          # Store for later use
          results$habitat <- habitat_data
          results$barrier <- barrier_data

          # Get parameters
          base_res <- input$data_resolution
          overlay_res <- input$target_resolution
          interpatch_dists <- interpatch_distances_parsed()
          results$interpatch_distances <- interpatch_dists

          incProgress(0.2, message = "Preparing rasters...")

          # Prepare rasters
          rasters <- prepare_rasters(
            habitat = habitat_data,
            barrier = barrier_data,
            data_resolution = base_res,
            target_resolution = overlay_res
          )

          results$habitat_raster <- rasters$habitat_raster
          results$barrier_raster <- rasters$barrier_raster

          incProgress(0.3, message = "Calculating connectivity...")

          scenario <- chosen_scenario()

          if (!is.null(scenario)) {
            incProgress(0, message = "Comparing scenario to baseline...")
          }

          # One object holding the whole analysis: the summary, the layers
          # each distance produced, and the scenario landscape beside them.
          # The tables, plots and downloads below all read from it, and it is
          # what the asset bundle is written from. A scenario goes in here
          # rather than being compared separately, so the baseline pipeline
          # runs once rather than once for the analysis and again for the
          # comparison.
          report_data <- connectivity_report_data(
            habitat = results$habitat_raster,
            barrier = results$barrier_raster,
            species = input$species,
            interpatch_distance = interpatch_dists,
            scenario = scenario$layer,
            scenario_kind = scenario$kind,
            verbose = FALSE
          )

          incProgress(0.5, message = "Summarising results...")

          results$report_data <- report_data
          results$results_connect_habitat <- report_data$connectivity
          results$buffered_habitat <- report_data$buffered_habitat
          results$patch_id_raster <- report_data$patch_id_raster
          results$areas_connected <- patch_sizes(report_data$connectivity)

          results$comparison <- report_data$comparison
          results$scenario_layer <- scenario_layer(report_data)
          results$scenario_kind <- report_data$scenario_kind
          results$scenario_habitat <- report_data$scenario_habitat
          results$scenario_barrier <- report_data$scenario_barrier
          results$scenario_buffered <- report_data$scenario_buffered_habitat

          incProgress(0.9, message = "Finalizing...")

          results$ready <- TRUE
          results$analysis_time <- Sys.time()
        })

        removeModal()

        # Show success message
        showNotification(
          "Analysis complete!",
          type = "message",
          duration = 3
        )
      },
      error = function(e) {
        removeModal()
        showNotification(
          paste("Error:", e$message),
          type = "error",
          duration = NULL
        )
      }
    )
  })

  # Output: Results ready flag ----
  output$results_ready <- reactive({
    results$ready
  })
  outputOptions(output, "results_ready", suspendWhenHidden = FALSE)

  # Output: Analysis Metadata ----
  output$analysis_species <- renderText({
    req(results$ready)
    input$species
  })

  output$analysis_timestamp <- renderText({
    req(results$ready)
    format(results$analysis_time, "%Y-%m-%d %H:%M:%S %Z")
  })

  output$analysis_session <- renderText({
    req(results$ready)
    paste0("R ", getRversion(), " on ", Sys.info()["sysname"])
  })

  output$analysis_buffers <- renderText({
    req(results$ready)
    paste(results$interpatch_distances, collapse = ", ")
  })

  output$analysis_workdir <- renderText({
    req(results$ready)
    getwd()
  })

  # Output: Show interpatch distance comparison flag ----
  output$show_buffer_comparison <- reactive({
    results$ready && length(results$interpatch_distances) > 1
  })
  outputOptions(output, "show_buffer_comparison", suspendWhenHidden = FALSE)

  # One tab per interpatch distance. Every tabbed view of the analysis is this
  # shape, so they share it: `content` says what one panel holds, and `ready`
  # has to be a function, because a promise would be forced once and then stop
  # tracking.
  distance_tabs <- function(content, ready = \() results$ready, id = NULL) {
    renderUI({
      req(ready())

      panels <- map(results$interpatch_distances, function(distance) {
        nav_panel(
          title = paste0("Interpatch: ", distance, "m"),
          content(distance)
        )
      })

      do.call(navset_tab, c(if (is.null(id)) NULL else list(id = id), panels))
    })
  }

  # the rasters are only needed by the plots themselves, rendered in the
  # observers below
  distance_plot <- function(prefix) {
    function(distance) {
      plotOutput(paste0(prefix, "_", distance), height = "500px")
    }
  }

  # Output: Habitat, Buffered Habitat, and Barrier - Tabbed Plots ----
  output$gg_barrier_habitat_buffer_tabs <- distance_tabs(
    distance_plot("barrier_habitat_interpatch"),
    id = "barrier_habitat_tabs"
  )

  # Render each barrier/habitat/interpatch plot dynamically ----
  observe({
    req(results$ready)

    walk2(
      .x = results$buffered_habitat,
      .y = results$interpatch_distances,
      .f = function(buffered_habitat, distance) {
        output_name <- paste0("barrier_habitat_interpatch_", distance)
        local({
          my_buffered <- buffered_habitat
          my_distance <- distance
          output[[output_name]] <- renderPlot({
            # review: this is the re-use section, set up module
            gg_barrier_habitat_interpatch_dist(
              barrier = results$barrier_raster,
              buffered = my_buffered,
              habitat = results$habitat_raster,
              interpatch_distance = my_distance,
              species = input$species,
              col_paper = "grey96"
            )
          })
        })
      }
    )
  })

  # Output: Patch ID - Tabbed Plots ----
  output$plot_patches_tabs <- distance_tabs(
    distance_plot("patch_plot"),
    id = "patch_tabs"
  )

  # Render each patch plot dynamically ----
  observe({
    req(results$ready)

    walk2(
      .x = results$patch_id_raster,
      .y = results$interpatch_distances,
      .f = function(patch_id, interpatch_distance) {
        output_name <- paste0("patch_plot_", interpatch_distance)
        local({
          my_patch_id <- patch_id
          my_interpatch_distance <- interpatch_distance
          my_species <- input$species
          output[[output_name]] <- renderPlot({
            plot_patches(
              patch_id = my_patch_id,
              interpatch_distance = my_interpatch_distance,
              species = my_species
            )
          })
        })
      }
    )
  })

  # Output: Area and patch information table (combined from all buffers) ----
  output$summary_table <- renderDT({
    req(results$areas_connected)

    results$areas_connected |>
      setNames(results$interpatch_distances) |>
      bind_rows(.id = "interpatch") |>
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
    req(results$results_connect_habitat)

    display_dt(
      connectivity_display(results$results_connect_habitat),
      pageLength = 10,
      dom = "tip"
    )
  })

  # Output: Longer format prob connectedness table ----
  output$results_connect_habitat_longer_table <- renderDT({
    req(results$results_connect_habitat)

    # the labels and which columns identify a row both come from the package,
    # so renaming one doesn't break this. One column of every metric needs
    # significant figures rather than the per-column rules.
    display <- connectivity_display(results$results_connect_habitat)

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
    req(results$results_connect_habitat)
    plot_connectivity(results$results_connect_habitat)
  })

  # Output: Interpatch distance comparison plot ----
  output$plot_buffer_comparison <- renderPlot({
    req(results$results_connect_habitat)
    req(length(results$interpatch_distances) > 1)

    # Create a multi-panel comparison
    p1 <- ggplot(
      results$results_connect_habitat,
      aes(x = interpatch_distance, y = prob_connectedness)
    ) +
      geom_line(linewidth = 1.2, color = "#1976D2") +
      geom_point(size = 3, color = "#1976D2") +
      scale_y_continuous(labels = scales::percent_format()) +
      theme_minimal() +
      labs(
        x = "Interpatch Distance (m)",
        y = "Probability of Connectedness",
        title = "Connectivity Metrics by Interpatch Distance"
      ) +
      theme(
        plot.title = element_text(size = 13, face = "bold"),
        axis.title = element_text(size = 10)
      )

    p2 <- ggplot(
      results$results_connect_habitat,
      aes(x = interpatch_distance, y = n_patches)
    ) +
      geom_line(linewidth = 1.2, color = "#D32F2F") +
      geom_point(size = 3, color = "#D32F2F") +
      theme_minimal() +
      labs(
        x = "Interpatch Distance (m)",
        y = "Number of Patches"
      ) +
      theme(
        axis.title = element_text(size = 10)
      )

    p3 <- ggplot(
      results$results_connect_habitat,
      aes(x = interpatch_distance, y = effective_mesh_ha)
    ) +
      geom_line(linewidth = 1.2, color = "#388E3C") +
      geom_point(size = 3, color = "#388E3C") +
      theme_minimal() +
      labs(
        x = "Interpatch Distance (m)",
        y = "Effective Mesh Size (ha)"
      ) +
      theme(
        axis.title = element_text(size = 10)
      )

    p4 <- ggplot(
      results$results_connect_habitat,
      aes(x = interpatch_distance, y = patch_area_mean)
    ) +
      geom_line(linewidth = 1.2, color = "#F57C00") +
      geom_point(size = 3, color = "#F57C00") +
      theme_minimal() +
      labs(
        x = "Interpatch Distance (m)",
        y = "Mean Patch Area (m2)"
      ) +
      theme(
        axis.title = element_text(size = 10)
      )

    gridExtra::grid.arrange(p1, p2, p3, p4, ncol = 2)
  })

  # Downloads ----

  output$download_summary_csv <- downloadHandler(
    filename = function() {
      paste0("connectivity_summary_", Sys.Date(), ".csv")
    },
    content = function(file) {
      # patch_size is a list-column of per-patch tables; it writes as an empty
      # column. The per-patch data has its own download.
      results$results_connect_habitat |>
        select(-patch_size) |>
        write_csv(file)
    }
  )

  output$download_patches_csv <- downloadHandler(
    filename = function() {
      paste0("patch_areas_", Sys.Date(), ".csv")
    },
    content = function(file) {
      all_patches <- map2(
        results$areas_connected,
        results$interpatch_distances,
        ~ mutate(.x, interpatch_distance = .y)
      ) |>
        list_rbind()
      write_csv(all_patches, file)
    }
  )

  output$download_raster <- downloadHandler(
    filename = function() {
      paste0("habitat_patches_", Sys.Date(), ".tif")
    },
    content = function(file) {
      terra::writeRaster(results$habitat_raster, file, overwrite = TRUE)
    }
  )

  output$download_map_1 <- downloadHandler(
    filename = function() {
      paste0("habitat_barrier_map_", Sys.Date(), ".png")
    },
    content = function(file) {
      png(file, width = 1200, height = 800, res = 150)
      print(
        ggplot() +
          geom_sf(
            data = results$habitat,
            fill = "#2E7D32",
            alpha = 0.7,
            color = NA
          ) +
          geom_sf(
            data = results$barrier,
            fill = "#D32F2F",
            alpha = 0.7,
            color = NA
          ) +
          theme_minimal() +
          labs(
            title = "Habitat and Barrier Layers",
            subtitle = paste("Species:", input$species)
          ) +
          theme(
            plot.title = element_text(size = 14, face = "bold"),
            plot.subtitle = element_text(size = 11)
          )
      )
      dev.off()
    }
  )

  output$download_map_2 <- downloadHandler(
    filename = function() {
      paste0("patches_map_", Sys.Date(), ".png")
    },
    content = function(file) {
      first_result <- results$areas_connected[[1]]
      first_buffer <- results$interpatch_distances[1]

      patch_summary <- first_result |>
        arrange(desc(area)) |>
        mutate(
          patch_rank = row_number(),
          patch_category = case_when(
            patch_rank == 1 ~ "Largest",
            patch_rank <= 5 ~ "Top 5",
            TRUE ~ "Other"
          )
        )

      png(file, width = 1200, height = 800, res = 150)
      print(
        ggplot(
          patch_summary,
          aes(x = patch_rank, y = area, fill = patch_category)
        ) +
          geom_col() +
          scale_fill_manual(
            values = c(
              "Largest" = "#1B5E20",
              "Top 5" = "#43A047",
              "Other" = "#81C784"
            )
          ) +
          theme_minimal() +
          labs(
            title = "Connected Habitat Patches by Size",
            subtitle = paste("Interpatch distance:", first_buffer, "m"),
            x = "Patch Rank (by size)",
            y = "Patch Area (m2)",
            fill = "Category"
          ) +
          theme(
            plot.title = element_text(size = 14, face = "bold"),
            plot.subtitle = element_text(size = 11)
          )
      )
      dev.off()
    }
  )

  output$download_comparison <- downloadHandler(
    filename = function() {
      paste0("buffer_comparison_", Sys.Date(), ".png")
    },
    content = function(file) {
      png(file, width = 1600, height = 1200, res = 150)

      p1 <- ggplot(
        results$results_connect_habitat,
        aes(x = interpatch_distance, y = prob_connectedness)
      ) +
        geom_line(linewidth = 1.2, color = "#1976D2") +
        geom_point(size = 3, color = "#1976D2") +
        scale_y_continuous(labels = scales::percent_format()) +
        theme_minimal() +
        labs(
          x = "Interpatch Distance (m)",
          y = "Probability of Connectedness",
          title = "Connectivity Metrics by Interpatch Distance"
        ) +
        theme(
          plot.title = element_text(size = 13, face = "bold"),
          axis.title = element_text(size = 10)
        )

      p2 <- ggplot(
        results$results_connect_habitat,
        aes(x = interpatch_distance, y = n_patches)
      ) +
        geom_line(linewidth = 1.2, color = "#D32F2F") +
        geom_point(size = 3, color = "#D32F2F") +
        theme_minimal() +
        labs(
          x = "Interpatch Distance (m)",
          y = "Number of Patches"
        ) +
        theme(
          axis.title = element_text(size = 10)
        )

      p3 <- ggplot(
        results$results_connect_habitat,
        aes(x = interpatch_distance, y = effective_mesh_ha)
      ) +
        geom_line(linewidth = 1.2, color = "#388E3C") +
        geom_point(size = 3, color = "#388E3C") +
        theme_minimal() +
        labs(
          x = "Interpatch Distance (m)",
          y = "Effective Mesh Size (ha)"
        ) +
        theme(
          axis.title = element_text(size = 10)
        )

      p4 <- ggplot(
        results$results_connect_habitat,
        aes(x = interpatch_distance, y = patch_area_mean)
      ) +
        geom_line(linewidth = 1.2, color = "#F57C00") +
        geom_point(size = 3, color = "#F57C00") +
        theme_minimal() +
        labs(
          x = "Interpatch Distance (m)",
          y = "Mean Patch Area (m2)"
        ) +
        theme(
          axis.title = element_text(size = 10)
        )

      print(gridExtra::grid.arrange(p1, p2, p3, p4, ncol = 2))
      dev.off()
    }
  )

  # Download connectivity plot (using plot_connectivity function) ----
  output$download_connectivity_plot <- downloadHandler(
    filename = function() {
      paste0(input$species, "_connectivity_plot_", Sys.Date(), ".png")
    },
    content = function(file) {
      # the same size the zip and the report use, from urbio_figure_size()
      size <- urbio_figure_size()
      ggsave(
        filename = file,
        plot = plot_connectivity(results$results_connect_habitat),
        width = size$width,
        height = size$tall_height,
        dpi = size$dpi,
        bg = "white"
      )
    }
  )

  # Download terra areas CSV ----
  output$download_areas_csv <- downloadHandler(
    filename = function() {
      paste0(input$species, "_areas_", Sys.Date(), ".csv")
    },
    content = function(file) {
      results$areas_connected |>
        setNames(results$interpatch_distances) |>
        bind_rows(.id = "interpatch") |>
        write_csv(file)
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
          "i" = "Upload one under {.field Scenario Layer}, or pick one of the
                 supplied scenarios, or set it back to {.field None}."
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

  # Which layer a scenario changes, and the layer itself. Each supplied
  # scenario says its own kind; only an upload has to be told. NULL when no
  # scenario is chosen.
  chosen_scenario <- function() {
    choice <- input$scenario_choice %||% "none"

    if (choice == "none") {
      return(NULL)
    }

    if (choice == "upload") {
      req(input$scenario_file)
      return(list(
        layer = read_uploaded_file(input$scenario_file),
        kind = input$scenario_kind
      ))
    }

    supplied <- chosen_dataset()$scenarios[[choice]]
    list(layer = supplied$layer(), kind = supplied$kind)
  }

  # drives the Results tab's scenario section, which stays hidden until there
  # is a comparison to show
  output$has_comparison <- reactive(!is.null(results$comparison))
  outputOptions(output, "has_comparison", suspendWhenHidden = FALSE)

  output$comparison_wide_table <- renderDT({
    req(results$comparison)

    display_dt(
      connectivity_display(results$comparison),
      pageLength = 10,
      dom = "t"
    )
  })

  output$comparison_long_table <- renderDT({
    req(results$comparison)

    display_dt(
      connectivity_display(results$comparison, wide = FALSE),
      pageLength = 8
    )
  })

  # What went into the comparison, one layer at a time: the two baseline
  # inputs and the scenario standing in for one of them.
  output$layer_habitat <- renderPlot({
    req(results$habitat_raster)
    gg_layer(results$habitat_raster, "habitat")
  })

  output$layer_barrier <- renderPlot({
    req(results$barrier_raster)
    gg_layer(results$barrier_raster, "barrier")
  })

  output$layer_scenario <- renderPlot({
    req(results$scenario_layer, results$scenario_kind)

    gg_layer(
      results$scenario_layer,
      results$scenario_kind,
      title = paste0("Scenario: ", results$scenario_kind)
    )
  })

  # One landscape, drawn the way both sides of a comparison are drawn, so the
  # only difference you see is the one the scenario made.
  landscape_plot <- function(habitat, barrier, buffered, distance) {
    gg_barrier_habitat_interpatch_dist(
      barrier = barrier,
      buffered = buffered,
      habitat = habitat,
      interpatch_distance = distance,
      species = input$species,
      col_paper = "grey96"
    )
  }

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

  observe({
    req(results$comparison)

    walk(results$interpatch_distances, function(distance) {
      key <- as.character(distance)

      baseline <- landscape_plot(
        results$habitat_raster,
        results$barrier_raster,
        results$buffered_habitat[[key]],
        distance
      )
      scenario <- landscape_plot(
        results$scenario_habitat,
        results$scenario_barrier,
        results$scenario_buffered[[key]],
        distance
      )

      output[[paste0("baseline_landscape_", distance)]] <- renderPlot(baseline)
      output[[paste0("scenario_landscape_", distance)]] <- renderPlot(scenario)

      output[[paste0("compare_", distance)]] <- visual_diff_render(
        visual_diff(
          landscape_png(baseline, "baseline", distance),
          landscape_png(scenario, "scenario", distance)
        )
      )
    })
  })

  # One tab per distance, for each way of looking at the pair.
  compared <- \() !is.null(results$comparison)

  output$baseline_landscape_tabs <- distance_tabs(
    distance_plot("baseline_landscape"),
    ready = compared,
    id = "baseline_distance"
  )
  output$scenario_landscape_tabs <- distance_tabs(
    distance_plot("scenario_landscape"),
    ready = compared,
    id = "scenario_distance"
  )
  output$landscape_compare_tabs <- distance_tabs(
    function(distance) {
      visual_diff_output(paste0("compare_", distance), height = "720px")
    },
    ready = compared,
    id = "compare_distance"
  )

  # Everything: maps, tables, GIS layers and the reports
  output$download_everything <- downloadHandler(
    filename = function() {
      paste0("connectivity-", Sys.Date(), ".zip")
    },
    content = function(file) {
      req(results$report_data)

      withProgress(message = "Preparing your download...", value = 0.3, {
        zip_connectivity_assets(results$report_data, file)
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
      filename = function() {
        # filename runs before content, so req() has to be here too
        req(results$report_data)
        paste0(connectivity_file_stem(results$report_data), ".", extension)
      },
      content = function(file) {
        req(results$report_data)

        withProgress(message = "Rendering your report...", value = 0.3, {
          generate_connectivity_report(
            results$report_data,
            file,
            format = extension
          )
        })
      }
    )
  }

  output$download_report_html <- report_download("html")
  output$download_report_pdf <- report_download("pdf")

  output$download_reports_zip <- downloadHandler(
    filename = function() {
      req(results$report_data)
      paste0(connectivity_file_stem(results$report_data), "-reports.zip")
    },
    content = function(file) {
      req(results$report_data)

      withProgress(message = "Rendering both reports...", value = 0.3, {
        zip_connectivity_reports(results$report_data, file)
      })
    }
  )
}
