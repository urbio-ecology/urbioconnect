# check_names names the argument the caller supplied

    Code
      needs_area(data.frame(patch_id = 1:3))
    Condition
      Error in `needs_area()`:
      ! `patch_table` must have a column named area.

# check_directions takes 4 or 8 and nothing else

    Code
      check_directions(6)
    Condition
      Error:
      ! `6` must be 4 or 8.
      x You supplied a number: 6.
      i 4 joins cells that share an edge (the rook's case), and 8 also joins cells that touch at a corner (the queen's case).
    Code
      check_directions("8")
    Condition
      Error:
      ! `"8"` must be 4 or 8.
      x You supplied a string: "8".
      i 4 joins cells that share an edge (the rook's case), and 8 also joins cells that touch at a corner (the queen's case).
    Code
      check_directions(c(4, 8))
    Condition
      Error:
      ! `c(4, 8)` must be 4 or 8.
      x You supplied a double vector: 4 and 8.
      i 4 joins cells that share an edge (the rook's case), and 8 also joins cells that touch at a corner (the queen's case).

