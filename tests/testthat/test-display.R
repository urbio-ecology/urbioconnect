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

test_that("a comparison with several scenarios stays numeric", {
  layers <- scenario_test_layers()

  several <- habitat_connectivity_scenarios(
    habitat_baseline = layers$habitat,
    barrier_baseline = layers$barrier,
    species = "Superb Fairy Wren",
    habitat_scenarios = list(dev = layers$habitat_scenario),
    barrier_scenarios = list(road = layers$barrier_scenario),
    interpatch_distance = 40,
    verbose = FALSE
  )

  display <- connectivity_display(several)

  # dropping scenario_name collapsed two scenarios onto one row, and
  # pivot_wider() then returned list-columns that round_by() silently skipped
  expect_type(display$data$Baseline, "double")
  expect_snapshot(names(display$data))
  expect_setequal(display$data$Scenario, c("dev", "road"))
  expect_equal(nrow(display$data), 10)
})

test_that("the long comparison rounds metrics but not identifiers", {
  display <- connectivity_display(test_comparison(), wide = FALSE)

  # signif(1234, 3) is 1230, so a distance rounded like a metric lies
  expect_false("Distance (m)" %in% display$digits$column)
  expect_snapshot(display$digits$column)
})

test_that("display_ids() names the identifier columns", {
  expect_snapshot(display_ids(connectivity_display(
    test_report_data(40)$connectivity
  )))
})

test_that("a display is rejected when its digit spec doesn't fit", {
  expect_snapshot(error = TRUE, {
    connectivity_display(data.frame(a = 1))
    round_by(list(data = tibble::tibble(x = 1), digits = "nope"))
    round_by(list(
      data = tibble::tibble(x = 1),
      digits = tibble::tibble(column = "absent", kind = "round", digits = 2)
    ))
    round_by(list(
      data = tibble::tibble(x = 1),
      digits = tibble::tibble(column = "x", kind = "nope", digits = 2)
    ))
  })
})

test_that("format_by() keeps missing values missing", {
  display <- list(
    data = tibble::tibble(x = c(1.234, NA)),
    digits = tibble::tibble(column = "x", kind = "round", digits = 1)
  )

  expect_equal(format_by(display)$x, c("1.2", NA))
})

test_that("print() on a comparison takes a width", {
  # print.compare_connectivity() used to fix width = Inf, so passing one
  # matched the argument twice
  expect_no_error(capture.output(print(test_comparison(), width = 80)))
})
