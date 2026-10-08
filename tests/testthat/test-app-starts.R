# testServer() sources the app's files by hand, so it cannot tell whether
# shiny can actually run the directory. These start the app for real. They are
# the only tests that would have caught an `app.R` beside a `server.R`, which
# shiny silently ignores, leaving no packages attached.
#
# One browser for the whole file. Starting chrome and the app is ~6s, which is
# more than every assertion here put together, so this is deliberately one
# long test rather than several short ones.

test_that("the app starts, takes an analysis, and compares the result", {
  skip_if_no_browser_app()
  skip_if_not_installed("diffviewer")

  app <- local_app_driver()

  expect_match(app$get_text(".navbar-brand"), "Urban Connectedness")

  # get_text() returns nothing for the nav links, so ask the page
  tabs <- unique(strsplit(
    app$get_js(
      '$("a[data-value]").map(function() {
         return $(this).attr("data-value")
       }).get().join(",")'
    ),
    ","
  )[[1]])

  expect_in(c("Inputs", "Results", "Downloads", "About"), tabs)

  # the scenario controls are an input, so they live on Inputs, not a tab
  expect_false("Scenarios" %in% tabs)

  visible <- function(selector) {
    app$get_js(paste0('$("', selector, '").is(":visible")'))
  }

  # the scenario select sits with the other layer inputs, always offered. A
  # selectInput's own <select> is hidden behind its selectize widget, so ask
  # about the label rather than the input.
  expect_true(visible("#scenario_choice-label"))

  # a shipped scenario says which layer it changes, so nothing more is needed
  expect_false(visible("#scenario_file"))
  expect_false(visible("#scenario_kind"))

  app$set_inputs(scenario_choice = "upload")
  app$wait_for_idle()

  expect_true(visible("#scenario_file"))
  expect_true(visible("#scenario_kind"))

  # the widget exists only once there is a scenario to compare, so this test
  # pays for a real analysis, on the lizard landscape and at two distances to
  # see that they stay apart
  # the lizard example dataset and its own scenario, both chosen rather than
  # uploaded: that is the path a user takes, and it analyses in under a
  # second. Choosing the dataset fills in the species and reloads the
  # scenario choices, which is behaviour only a browser exercises.
  app$set_inputs(example_data = "lizard")
  app$wait_for_idle()

  expect_equal(app$get_value(input = "species"), "Blue Tongue Lizard")

  app$set_inputs(
    interpatch_distances = "40, 80",
    scenario_choice = "lizard_road"
  )

  app$set_inputs(run_analysis = "click", wait_ = FALSE)
  app$wait_for_idle(duration = 1000, timeout = 120000)

  # outputs suspend while hidden, so every panel down to the widget has to be
  # opened first. Each navset carries an id, so this is an input, not a click
  app$set_inputs(
    main_nav = "Results",
    results_view = "Scenario",
    landscape_view = "Compare"
  )
  app$wait_for_idle(timeout = 60000)

  # the zoom buttons share the button class, so ask the view group by name
  modes <- function(distance) {
    app$get_js(sprintf(
      '$("#compare_%s .image-diff-view-buttons > .image-diff-button")
         .map(function() { return $(this).attr("data-button") })
         .get().join(",")',
      distance
    ))
  }

  # a widget per distance, each in its own tab. Only the open one is filled
  # in, because an htmlwidget suspends while hidden, so the second is checked
  # as a container: filling it costs two more 1200px PNGs for no new
  # behaviour, and test-shiny-app.R already builds the outputs per distance.
  expect_equal(app$get_js('$("#compare_40, #compare_80").length'), 2)

  # an htmlwidget draws after its output has arrived, so wait_for_idle() can
  # return with the container up and nothing in it. CI found that on a slower
  # machine; wait for the widget itself rather than for the server to settle.
  app$wait_for_js(
    '$("#compare_40 .image-diff-view-buttons > .image-diff-button").length > 0',
    timeout = 60000
  )

  # the three views diffviewer gives a changed image, which is what this
  # widget is here for rather than the hand-rolled wipe it replaced
  expect_equal(modes(40), "difference,toggle,slider")

  # the slider view stacks both landscapes, so both PNGs reached the widget.
  # diffviewer ignores a mousedown that isn't the left button, and a bare
  # jQuery trigger leaves `which` unset.
  app$run_js(
    '$("#compare_40 .image-diff-view-buttons > [data-button=slider]")
       .trigger($.Event("mousedown", { which: 1 }));'
  )
  app$wait_for_js(
    '$("#compare_40 .image-slider img").length === 2',
    timeout = 60000
  )

  expect_equal(app$get_js('$("#compare_40 .image-slider img").length'), 2)
})
