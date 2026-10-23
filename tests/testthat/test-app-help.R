test_that("every input but target_resolution has an i, outside its label", {
  skip_if_no_app()
  app_dir <- local_app_server()
  source(file.path(app_dir, "ui.R"), local = TRUE)
  html <- as.character(ui)

  ids_ending <- function(suffix) {
    pattern <- sprintf('id="([^"]+)-%s"', suffix)
    sub(pattern, "\\1", regmatches(html, gregexpr(pattern, html))[[1]])
  }
  label_text <- function(id) {
    pattern <- sprintf('(?s)id="%s-label"[^>]*>(.*?)</label>', id)
    trimws(regmatches(html, regexec(pattern, html, perl = TRUE))[[1]][[2]])
  }

  expect_setequal(ids_ending("help"), names(input_help))
  expect_snapshot(setdiff(ids_ending("label"), ids_ending("help")))

  # a label holding only its text: a screen reader reads the "i" as part of
  # any label it sits in, and a click on it would reach the input
  expect_equal(
    purrr::map_chr(names(input_help), label_text),
    unname(purrr::map_chr(input_help, "label"))
  )
})

test_that("help_input() fails for an input with no help", {
  skip_if_no_app()
  local_app_server()

  expect_snapshot(help_input(shiny::textInput, "speceis"), error = TRUE)
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
    # no whole-metre cell is small enough, so only a longer distance helps
    describe(distances = 1)
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
