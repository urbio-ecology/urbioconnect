# check_names names the argument the caller supplied

    Code
      needs_area(data.frame(patch_id = 1:3))
    Condition
      Error in `needs_area()`:
      ! `patch_table` must contain a area column.

# new_patch_size_tbl names its own argument

    Code
      new_patch_size_tbl(data = data.frame(patch_id = 1:3), species = "birds",
      interpatch_distance = 10)
    Condition
      Error in `new_patch_size_tbl()`:
      ! `data` must contain a area column.

