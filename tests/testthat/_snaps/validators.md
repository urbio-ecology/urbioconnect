# patch_size_tbl works

    Code
      patch_size_tbl(data = data.frame(area = 1:10, patch_id = 1:10), species = "birds",
      interpatch_distance = 10, res = c(1, 1))
    Output
      # patch_size_tbl:      data.frame
      # Species:             birds
      # Patches:             10
      # Resolution:          1x1
      # Interpatch Distance: 10 m
        patch_id  area
           <int> <int>
      1        1     1
      2        2     2
      3        3     3
      4        4     4
      5        5     5
      # i 5 more rows

# validate_patch_size_tbl works

    Code
      validate_patch_size_tbl(iris)
    Condition
      Error in `validate_patch_size_tbl()`:
      ! `species` must be <character>, not <NULL>.
      i You supplied: NULL

---

    Code
      validate_patch_size_tbl(lizard_areas_connected)

---

    Code
      validate_patch_size_tbl(altered_lizard_areas)
    Condition
      Error in `validate_patch_size_tbl()`:
      ! `x` must contain a patch_id column.

# check_scalar works as expected

    Code
      check_scalar(1:3)
    Condition
      Error:
      ! `1:3` must be a scalar (length 1), not length 3.
      i Did you mean to pass a single value?

---

    Code
      check_scalar(LETTERS[1:3])
    Condition
      Error:
      ! `LETTERS[1:3]` must be a scalar (length 1), not length 3.
      i Did you mean to pass a single value?

---

    Code
      check_scalar(c(TRUE, FALSE, TRUE))
    Condition
      Error:
      ! `c(TRUE, FALSE, TRUE)` must be a scalar (length 1), not length 3.
      i Did you mean to pass a single value?

---

    Code
      check_scalar(1)

---

    Code
      check_scalar("1")

---

    Code
      check_scalar(TRUE)

# check_pc_match errors appropriately

    Code
      check_pc_match(birds_r1_i8, birds_r1_i10)
    Condition
      Error:
      ! `connectivity` and `connectivity_baseline` must have the same resolution, species, and interpatch_distance.
      ! One or more of these do not match:
      interpatch_distance
      * connectivity = "8"
      * connectivity_baseline = "10"

---

    Code
      check_pc_match(birds_r1_i8, cats_r1_i8)
    Condition
      Error:
      ! `connectivity` and `connectivity_baseline` must have the same resolution, species, and interpatch_distance.
      ! One or more of these do not match:
      species
      * connectivity = "birds"
      * connectivity_baseline = "cats"

---

    Code
      check_pc_match(birds_r1_i8, birds_r2_i8)
    Condition
      Error:
      ! `connectivity` and `connectivity_baseline` must have the same resolution, species, and interpatch_distance.
      ! One or more of these do not match:
      resolution
      * connectivity = "1x1"
      * connectivity_baseline = "2x2"

# check_pc_match reports the caller-supplied argument names

    Code
      check_pc_match(birds_r1_i8, cats_r1_i8, arg = "scenario", arg_baseline = "baseline")
    Condition
      Error:
      ! `scenario` and `baseline` must have the same resolution, species, and interpatch_distance.
      ! One or more of these do not match:
      species
      * scenario = "birds"
      * baseline = "cats"

