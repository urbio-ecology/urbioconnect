test_that("run_connectivity_app launches the shiny app", {
  local_mocked_bindings(
    runApp = function(...) invisible(NULL),
    .package = "shiny"
  )
  expect_no_error(run_connectivity_app())
})

test_that("app_packages() lists what the app attaches", {
  expect_snapshot(app_packages())
})
