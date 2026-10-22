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
  expect_equal(check_names(patches, "area"), patches)
})

test_that("new_patch_size_tbl names its own argument", {
  expect_snapshot(
    error = TRUE,
    new_patch_size_tbl(
      data = data.frame(patch_id = 1:3),
      species = "birds",
      interpatch_distance = 10
    )
  )
})
