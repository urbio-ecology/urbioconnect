test_that("every input but target_resolution has an i", {
  skip_if_no_app()
  app_dir <- local_app_server()
  source(file.path(app_dir, "ui.R"), local = TRUE)

  html <- as.character(htmltools::renderTags(ui)$html)
  labels <- regmatches(
    html,
    gregexpr('(?s)<label[^>]*id="[^"]+-label".*?</label>', html, perl = TRUE)
  )[[1]]
  ids <- sub('(?s)^<label[^>]*id="([^"]+)-label".*', "\\1", labels, perl = TRUE)
  has_help <- grepl("input-help", labels, fixed = TRUE)

  expect_setequal(ids[has_help], names(input_help))
  expect_snapshot(ids[!has_help])
})

test_that("help_label() fails for an input with no help", {
  skip_if_no_app()
  local_app_server()

  expect_snapshot(help_label("speceis"), error = TRUE)
})

test_that("describe_analysis() says what the inputs add up to", {
  skip_if_no_app()
  local_app_server()

  # defaults in the signature, not modifyList(), which would drop data = NULL
  describe <- function(
    data = "Blue Tongue Lizard example data",
    data_resolution = 10,
    distances = 100,
    scenario = NULL
  ) {
    description <- describe_analysis(data, data_resolution, distances, scenario)
    cat(
      c(
        sprintf("- %s", description$summary),
        sprintf("! %s", description$warnings)
      ),
      sep = "\n"
    )
  }

  expect_snapshot({
    describe()
    describe(distances = c(100, 250, 400))
    describe(distances = 15)
    describe(data_resolution = 30, distances = c(20, 50, 100))
    describe(distances = c(50, 100, 150, 200, 250))
    describe(data = NULL)
    describe(
      scenario = list(name = "A new road through the habitat", kind = "barrier")
    )
    describe(scenario = list(name = NULL, kind = "habitat"))
  })
})

test_that("describe_analysis() takes the integer a browser sends", {
  skip_if_no_app()
  local_app_server()

  expect_equal(
    describe_analysis("Data", 10L, c(15, 250)),
    describe_analysis("Data", 10, c(15, 250))
  )
})
