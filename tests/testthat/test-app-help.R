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
