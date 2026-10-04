test_that("generate_connectivity_report() rejects anything else", {
  expect_snapshot(error = TRUE, {
    generate_connectivity_report(lizard_areas_connected)
    generate_connectivity_report(test_report_data(), output_format = "word")
  })
})

# a render costs ~15s, so one report's properties are asserted together
test_that("generate_connectivity_report() writes both formats of a report", {
  skip_if_no_quarto()

  dir <- withr::local_tempdir()
  nested <- file.path(dir, "reports", "today")

  paths <- suppressMessages(
    generate_connectivity_report(
      test_report_data(c(40, 80)),
      output_format = "both",
      output_dir = nested
    )
  )

  # defaults to the species and date, matching the download folder
  expect_equal(
    basename(paths),
    paste0("superb-fairy-wren-connectivity-", Sys.Date(), c(".html", ".pdf"))
  )
  expect_true(all(file.exists(paths)))
  expect_gt(file.size(paths[[2]]), 0)

  # output_dir is created, and the paths come back absolute
  expect_true(dir.exists(nested))
  expect_equal(paths, normalizePath(paths, winslash = "/"))

  html <- test_report_text(paths[[1]])

  # the figures are embedded, so the file stands alone
  expect_match(html, "data:image/png", fixed = TRUE)
  expect_match(html, "Superb Fairy Wren", fixed = TRUE)
  expect_match(html, "Change over distance", fixed = TRUE)
})

test_that("the change-over-distance section needs more than one distance", {
  skip_if_no_quarto()

  dir <- withr::local_tempdir()

  path <- suppressMessages(
    generate_connectivity_report(
      test_report_data(40),
      output_format = "html",
      output_dir = dir,
      output_file = "report"
    )
  )

  expect_equal(basename(path), "report.html")
  expect_no_match(
    test_report_text(path),
    "Change over distance",
    fixed = TRUE
  )
})
