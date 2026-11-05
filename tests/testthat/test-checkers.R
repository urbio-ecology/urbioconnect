test_that("check_names names the argument the caller supplied", {
  needs_area <- function(patch_table) {
    check_names(patch_table, "area")
  }

  expect_snapshot(
    error = TRUE,
    needs_area(data.frame(patch_id = 1:3))
  )
})

test_that("check_names passes a data frame holding the column through", {
  patches <- data.frame(patch_id = 1:3, area = 1:3)
  expect_identical(expect_invisible(check_names(patches, "area")), patches)
})

test_that("check_directions takes 4 or 8 and nothing else", {
  expect_snapshot(error = TRUE, {
    check_directions(6)
    check_directions("8")
    check_directions(c(4, 8))
  })
  expect_no_error(check_directions(4))
  expect_no_error(check_directions(8))
})
