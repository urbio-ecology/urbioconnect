test_that("the column spec covers every column a connectivity has", {
  conn <- test_report_data(40)$connectivity

  # a metric added to summarise_connectivity() but not to the spec would be
  # shown under its raw name, so this is the guard
  expect_in(setdiff(names(conn), "patch_size"), connectivity_columns()$name)
})

test_that("connectivity_display() labels the columns and keeps numbers", {
  display <- connectivity_display(test_report_data(c(40, 80))$connectivity)

  expect_snapshot(names(display$data))
  expect_snapshot(as.data.frame(display$digits))

  # numeric, so DT can sort: a pre-rounded character column sorts 100 before 99
  expect_true(is.numeric(display$data[["Mesh (ha)"]]))
  expect_true(is.numeric(display$data[["P(connected)"]]))
})

test_that("connectivity_display() handles a patch table", {
  display <- connectivity_display(patch_sizes(
    test_report_data(40)$connectivity
  )[[1]])

  expect_snapshot(names(display$data))
  expect_equal(nrow(display$data), 3)
})

test_that("round_by() rounds per column and leaves numbers numeric", {
  display <- connectivity_display(test_report_data(40)$connectivity)
  rounded <- round_by(display)

  expect_true(is.numeric(rounded[["Mesh (ha)"]]))
  expect_equal(rounded[["Mesh (ha)"]], round(display$data[["Mesh (ha)"]], 2))
  expect_equal(
    rounded[["P(connected)"]],
    signif(display$data[["P(connected)"]], 3)
  )
})

test_that("format_by() gives each value its own notation", {
  display <- connectivity_display(test_comparison())
  formatted <- format_by(display)

  # the reason format_by() exists: this column holds a count and a ~1e-5
  # probability, and a numeric column spanning both prints wholly in
  # scientific, so a count of 3 reads as 3.00e+00
  expect_true(is.character(formatted$Baseline))
  expect_snapshot(as.data.frame(formatted))
})

test_that("a comparison is wide by default and long when asked", {
  comparison <- test_comparison()

  wide <- connectivity_display(comparison)$data
  long <- connectivity_display(comparison, wide = FALSE)$data

  # wide: one row per metric, one column per measure
  expect_snapshot(names(wide))
  expect_snapshot(wide$Metric)

  # long: the object's own shape, one row per measure
  expect_snapshot(names(long))
  expect_equal(nrow(long), 4)
})

test_that("print() on a comparison takes a width", {
  # print.compare_connectivity() used to fix width = Inf, so passing one
  # matched the argument twice
  expect_no_error(capture.output(print(test_comparison(), width = 80)))
})
