test_that("every input has an i, outside its label", {
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
  expect_setequal(ids_ending("label"), names(input_help))

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

test_that("nearest_cell_size_figure() picks the example nearest the cell size", {
  skip_if_no_app()
  local_app_server()

  expect_equal(nearest_cell_size_figure(10, cell_size_figures)$cell_size, 10)
  # between the 10 and 15 m examples
  expect_equal(nearest_cell_size_figure(12, cell_size_figures)$cell_size, 10)
  expect_equal(nearest_cell_size_figure(13, cell_size_figures)$cell_size, 15)
  # outside the 1 to 100 m they span
  expect_equal(nearest_cell_size_figure(0.5, cell_size_figures)$cell_size, 1)
  expect_equal(nearest_cell_size_figure(250, cell_size_figures)$cell_size, 100)
})

test_that("a cell size too wide to grow the example's buffer shows none", {
  skip_if_no_app()
  local_app_server()

  widest_with_buffer <- nearest_cell_size_figure(50, cell_size_figures)
  too_wide <- nearest_cell_size_figure(55, cell_size_figures)
  expect_match(widest_with_buffer$alt, "the buffer around it")
  expect_match(too_wide$alt, "no buffer")
})

test_that("the cell size examples in www/ are the ones the app lists", {
  skip_if_no_app()
  app_dir <- local_app_server()

  images <- list.files(file.path(app_dir, "www"), "^cell-size-.*[.]png$")
  expect_setequal(images, cell_size_figures$file)
})
