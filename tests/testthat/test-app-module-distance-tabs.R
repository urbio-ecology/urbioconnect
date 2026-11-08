test_that("distance_tabs_server() draws a tab per distance, and empties one dropped", {
  skip_if_no_app()
  local_app_server()

  distances <- shiny::reactiveVal(c(40, 80))
  plot_for <- function(distance) {
    ggplot2::ggplot() + ggplot2::labs(alt = paste0("drawn at ", distance, " m"))
  }

  shiny::testServer(
    distance_tabs_server,
    args = list(id = "maps", distances = distances, plot_for = plot_for),
    {
      # the ids and titles, not bslib's markup around them
      html <- output$tabs$html
      ids_and_titles <- gregexpr('id="maps-[^"]*"|data-value="[^"]*"', html)
      expect_snapshot(cat(regmatches(html, ids_and_titles)[[1]], sep = "\n"))
      expect_equal(output$plot_40$alt, "drawn at 40 m")
      expect_equal(output$plot_80$alt, "drawn at 80 m")

      distances(40)
      session$flushReact()

      expect_match(output$tabs$html, "Interpatch: 40m", fixed = TRUE)
      expect_no_match(output$tabs$html, "80m", fixed = TRUE)
      expect_error(output$plot_80, class = "shiny.silent.error")

      # one dropped and back, and one new
      distances(c(80, 120))
      session$flushReact()

      expect_equal(output$plot_80$alt, "drawn at 80 m")
      expect_equal(output$plot_120$alt, "drawn at 120 m")
    }
  )
})
