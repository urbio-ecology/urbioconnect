# The app's module for a plot at every interpatch distance, one tab each
#
# `distance_tabs_ui()` leaves the space that `distance_tabs_server()` fills.
#
# @param id The module's id, the same in both halves.
distance_tabs_ui <- function(id) {
  shiny::uiOutput(shiny::NS(id, "tabs"))
}

# @param id The module's id, the same in both halves.
# @param distances A reactive giving the interpatch distances.
# @param plot_for A function of one distance that returns its plot. It runs
#   inside `renderPlot()`, so the reactives it reads are tracked, and only for
#   a distance `distances()` holds.
distance_tabs_server <- function(id, distances, plot_for) {
  stopifnot(shiny::is.reactive(distances))

  shiny::moduleServer(id, function(input, output, session) {
    plot_id <- function(distance) paste0("plot_", distance)
    plot_output_for <- function(distance) {
      shiny::plotOutput(session$ns(plot_id(distance)), height = "500px")
    }

    output$tabs <- shiny::renderUI({
      distance_navset(session$ns("distance"), distances(), plot_output_for)
    })

    # Each output is bound once. Its renderPlot() tracks what it reads, so
    # binding it again on a rerun would draw the plot a second time.
    bound <- new.env()
    shiny::observe({
      unbound <- setdiff(distances(), bound$distances)
      purrr::walk(unbound, function(distance) {
        output[[plot_id(distance)]] <- shiny::renderPlot({
          # empty, not stale, once a run drops this distance
          shiny::req(distance %in% distances())
          plot_for(distance)
        })
      })
      bound$distances <- c(bound$distances, unbound)
    })
  })
}

# A navset with a tab per interpatch distance
#
# @param id The navset's id, so the open tab is an input.
# @param distances The interpatch distances, a tab each.
# @param content A function of one distance that returns what its tab holds.
distance_navset <- function(id, distances, content) {
  panels <- purrr::map(distances, function(distance) {
    bslib::nav_panel(
      title = paste0("Interpatch: ", distance, "m"),
      content(distance)
    )
  })

  do.call(bslib::navset_tab, c(list(id = id), panels))
}
