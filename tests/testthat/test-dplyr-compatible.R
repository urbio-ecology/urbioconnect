test_that("patch_size_tbl class is compatible with dplyr", {
  # what is under test is `[`, `names<-` and dplyr_reconstruct() keeping the
  # class and its attributes, none of which care where the rows came from.
  # Built directly rather than run out of the pipeline: that was ~3s for a
  # table, and round numbers read better in the snapshots below.
  ps <- patch_size_tbl(
    # doubles, as the pipeline produces them
    data = tibble::tibble(
      patch_id = as.numeric(1:25),
      area = seq(500, 12500, by = 500)
    ),
    species = "Blue-tongued Lizard",
    interpatch_distance = 8,
    res = c(2, 2)
  )

  library(dplyr)
  expect_snapshot(ps |> filter(area > 4000))
  expect_snapshot(ps |> filter(area > 1000))
  expect_snapshot(ps |> slice(1:10))
  expect_snapshot(ps |> select(-area) |> head())
  expect_snapshot(ps |> select(-patch_id) |> head())
})
