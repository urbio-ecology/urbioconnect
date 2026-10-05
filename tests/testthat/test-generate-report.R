test_that("generate_connectivity_report() rejects anything else", {
  expect_snapshot(error = TRUE, {
    generate_connectivity_report(lizard_areas_connected)
    generate_connectivity_report(test_report_data(), "report")
    generate_connectivity_report(test_report_data(), c("a.html", "b.html"))
    generate_connectivity_report(test_report_data(), "no/such/dir/report.html")
  })
})

test_that("write_connectivity_report() writes a qmd beside its data", {
  dir <- withr::local_tempdir()

  qmd <- write_connectivity_report(
    test_report_data(c(40, 80)),
    file.path(dir, "wren.qmd")
  )

  expect_equal(basename(qmd), "wren.qmd")
  expect_snapshot(sort(basename(list.files(dir))))

  # the document names its own data file, so the pair renders on its own
  expect_true(any(grepl('report_data: "wren-data.rds"', readLines(qmd))))

  # and that data is the analysis, readable back
  read <- read_report_data(file.path(dir, "wren-data.rds"))
  expect_s3_class(read, "connectivity_report_data")
  expect_equal(read$interpatch_distance, c(40, 80))
})

test_that("write_connectivity_report() rejects a path that isn't a qmd", {
  expect_snapshot(error = TRUE, {
    write_connectivity_report(test_report_data(), "report.html")
    write_connectivity_report(lizard_areas_connected, "report.qmd")
  })
})

test_that("render_connectivity_report() needs a file that exists", {
  skip_if_no_quarto()

  # a relative name, so the snapshot doesn't capture a temp path that changes
  # every run
  expect_snapshot(render_connectivity_report("absent.qmd"), error = TRUE)
})

test_that("the extension picks the format", {
  expect_equal(report_format("report.html"), "html")
  expect_equal(report_format("REPORT.HTML"), "html")
  expect_equal(report_format("~/reports/my.report.v2.html"), "html")

  # the three where the extension and Quarto's format name differ
  expect_equal(report_format("report.pdf"), "typst")
  expect_equal(report_format("report.md"), "gfm")
  expect_equal(report_format("report.tex"), "latex")

  # anything else goes to Quarto as-is, which writes it or complains itself
  expect_equal(report_format("report.docx"), "docx")
  expect_equal(report_format("report.rtf"), "rtf")
})

# a render costs ~15s, so one report's properties are asserted together, and
# the write-then-render path is used here so both routes are covered by the
# three renders this file does
test_that("a written report renders to HTML", {
  skip_if_no_quarto()

  dir <- withr::local_tempdir()

  qmd <- write_connectivity_report(
    test_report_data(c(40, 80)),
    file.path(dir, "report.qmd")
  )

  path <- suppressMessages(
    render_connectivity_report(qmd, file.path(dir, "report.html"))
  )

  expect_equal(basename(path), "report.html")
  expect_true(file.exists(path))

  # absolute, so it survives a change of working directory
  expect_equal(path, normalizePath(path, winslash = "/"))

  html <- test_report_text(path)

  # the figures are embedded, so the file stands alone
  expect_match(html, "data:image/png", fixed = TRUE)
  expect_match(html, "Superb Fairy Wren", fixed = TRUE)
  expect_match(html, "Change over distance", fixed = TRUE)
})

test_that("generate_connectivity_report() writes a PDF report", {
  skip_if_no_quarto()

  dir <- withr::local_tempdir()

  path <- suppressMessages(
    generate_connectivity_report(
      test_report_data(40),
      file.path(dir, "report.pdf")
    )
  )

  expect_equal(basename(path), "report.pdf")
  expect_gt(file.size(path), 0)

  # a real PDF, not an HTML file with the wrong name
  expect_equal(readBin(path, "raw", 4), charToRaw("%PDF"))
})

test_that("generate_connectivity_report() defaults the path", {
  skip_if_no_quarto()

  withr::with_tempdir({
    path <- suppressMessages(
      generate_connectivity_report(test_report_data(40))
    )

    expect_equal(
      basename(path),
      paste0("superb-fairy-wren-connectivity-", Sys.Date(), ".html")
    )

    # a single distance is a single point, so there is nothing to plot
    expect_no_match(
      test_report_text(path),
      "Change over distance",
      fixed = TRUE
    )
  })
})
