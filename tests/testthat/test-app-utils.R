test_that("extract_interpatch_distances() splits at commas and drops blanks", {
  skip_if_no_app()
  local_app_server()

  expect_equal(
    extract_interpatch_distances(" 100, 250,, 400 ,"),
    c("100", "250", "400")
  )
  expect_equal(extract_interpatch_distances("100, ten"), c("100", "ten"))
  expect_equal(extract_interpatch_distances(" , "), character())
  # what the box gives before it has sent anything, as under testServer()
  expect_equal(extract_interpatch_distances(NULL), character())
})
