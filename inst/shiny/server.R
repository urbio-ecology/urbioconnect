server <- function(input, output, session) {
  # Define file paths
  data_dir <- system.file(
    "shiny-data/superb-fairy-wren",
    package = "urbioconnect"
  )
  habitat_file_path <- file.path(data_dir, "superbHab.shp")
  barrier_file_path <- file.path(data_dir, "allSFWRoads.shp")
  # Observer to update species name when example data checkbox is toggled
  ## review: Should probably use eventReactive here
  observeEvent(input$use_example_data, {
    if (input$use_example_data) {
      updateTextInput(session, "species", value = "Superb Fairy Wren")
      # Disable inputs when using example data
      shinyjs::disable("species")
      shinyjs::disable("habitat_file")
      shinyjs::disable("barrier_file")
      # Add CSS to grey out the inputs
      shinyjs::runjs(
        "
        $('#species').closest('.form-group').css('opacity', '0.5');
        $('#habitat_file').closest('.form-group').css('opacity', '0.5');
        $('#barrier_file').closest('.form-group').css('opacity', '0.5');
      "
      )
    } else {
      # Enable inputs when not using example data
      shinyjs::enable("species")
      shinyjs::enable("habitat_file")
      shinyjs::enable("barrier_file")
      # Remove greying out
      shinyjs::runjs(
        "
        $('#species').closest('.form-group').css('opacity', '1');
        $('#habitat_file').closest('.form-group').css('opacity', '1');
        $('#barrier_file').closest('.form-group').css('opacity', '1');
      "
      )
    }
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
    analysis_time = NULL
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
    } else if (any(grepl("\\.geojson$", file_input$name, ignore.case = TRUE))) {
      # Handle GeoJSON files
      data <- st_read(file_input$datapath[1], quiet = TRUE)
    } else {
      cli::cli_abort(
        c(
          "File format must be a shapefile",
          "i" = "(.shp + .shx + .dbf), GeoTIFF (.tif), or GeoJSON (.geojson)",
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
        # Read files
        withProgress(message = "Loading data...", value = 0.1, {
          # Use example data if checkbox selected, otherwise use uploaded files
          # review: be careful with avoiding reuse of read_geometry() and then
          # replace with read_uploaded_file()
          if (input$use_example_data) {
            # Use predefined file paths
            habitat_data <- read_geometry(habitat_file_path) |>
              clean() |>
              st_as_sf()

            # File paths already defined at top of server function
            barrier_data <- read_geometry(barrier_file_path) |>
              clean() |>
              st_as_sf()
          } else {
            # Use uploaded files
            if (is.null(input$habitat_file) || is.null(input$barrier_file)) {
              cli::cli_abort(
                "Please upload both habitat and barrier files, or check \\
                'Use example data'"
              )
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

          # One object holding the whole analysis: the summary, and the layers
          # each distance produced. The tables, plots and downloads below all
          # read from it, and it is what the asset bundle is written from.
          report_data <- connectivity_report_data(
            habitat = results$habitat_raster,
            barrier = results$barrier_raster,
            species = input$species,
            interpatch_distance = interpatch_dists,
            verbose = FALSE
          )

          incProgress(0.5, message = "Summarising results...")

          results$report_data <- report_data
          results$results_connect_habitat <- report_data$connectivity
          results$buffered_habitat <- report_data$buffered_habitat
          results$patch_id_raster <- report_data$patch_id_raster
          results$areas_connected <- patch_sizes(report_data$connectivity)

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

  # Output: Habitat, Buffered Habitat, and Barrier - Tabbed Plots ----
  output$gg_barrier_habitat_buffer_tabs <- renderUI({
    req(results$ready)

    # Create color palette
    urbio_pal <- scico::scico(n = 11, palette = "tofino")
    urbio_pal_cut <- urbio_pal[c(6:11)]
    urbio_cols <- list(
      habitat = urbio_pal_cut[2],
      interpatch = urbio_pal_cut[5],
      barrier = "#FFFFFF"
    )

    # Create tabs for each interpatch distance
    tab_panels <- map2(
      .x = results$buffered_habitat,
      .y = results$interpatch_distances,
      .f = function(interpatch_distance, distance) {
        nav_panel(
          title = paste0("Interpatch: ", distance, "m"),
          plotOutput(
            outputId = paste0("barrier_habitat_interpatch_", distance),
            height = "500px"
          )
        )
      }
    )

    do.call(navset_tab, c(id = "barrier_habitat_tabs", tab_panels))
  })

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
              col_barrier = urbio_cols$barrier,
              col_interpatch_dist = urbio_cols$interpatch_distance,
              col_habitat = urbio_cols$habitat,
              col_paper = "grey96"
            )
          })
        })
      }
    )
  })

  # Output: Patch ID - Tabbed Plots ----
  output$plot_patches_tabs <- renderUI({
    req(results$ready)

    tab_panels <- map2(
      .x = results$patch_id_raster,
      .y = results$interpatch_distances,
      .f = function(patch_id, interpatch_distance) {
        nav_panel(
          title = paste0("Interpatch Distance: ", interpatch_distance, "m"),
          plotOutput(
            outputId = paste0("patch_plot_", interpatch_distance),
            height = "500px"
          )
        )
      }
    )

    do.call(navset_tab, c(id = "patch_tabs", tab_panels))
  })

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

    results$results_connect_habitat |>
      # patch_size is a list-column of per-patch tables: useful to carry
      # around, not something DT can render
      select(-patch_size) |>
      datatable(
        options = list(
          pageLength = 10,
          scrollX = TRUE,
          dom = "tip"
        ),
        rownames = FALSE
      ) |>
      formatRound(
        columns = c(
          "effective_mesh_ha",
          "patch_area_mean",
          "patch_area_total_ha"
        ),
        digits = 3
      ) |>
      # prob_connectedness is ~1e-5, so three decimal places reads as 0.000
      formatSignif(columns = "prob_connectedness", digits = 3)
  })

  # Output: Longer format prob connectedness table ----
  output$results_connect_habitat_longer_table <- renderDT({
    req(results$results_connect_habitat)

    results$results_connect_habitat |>
      select(-patch_size) |>
      pivot_longer(
        cols = -c(species, interpatch_distance, data_resolution)
      ) |>
      datatable(
        options = list(
          pageLength = 8,
          scrollX = TRUE
        ),
        rownames = FALSE
      ) |>
      # one column now holds metrics of very different magnitudes, from
      # ~1e-5 to the thousands, so significant figures rather than decimals
      formatSignif(columns = "value", digits = 3)
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
        y = "Mean Patch Area (m²)"
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
            y = "Patch Area (m²)",
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
          y = "Mean Patch Area (m²)"
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
      ggsave(
        filename = file,
        plot = plot_connectivity(results$results_connect_habitat),
        width = 12,
        height = 10,
        dpi = 300
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

  # Everything: maps, tables and GIS layers, laid out by interpatch distance
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
}
