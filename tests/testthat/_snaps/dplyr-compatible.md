# patch_size_tbl class is compatible with dplyr

    Code
      filter(ps, area > 4000)
    Output
      # patch_size_tbl:      data.frame
      # Species:             Blue-tongued Lizard
      # Patches:             17
      # Resolution:          2x2
      # Interpatch Distance: 8 m
        patch_id  area
           <dbl> <dbl>
      1        9  4500
      2       10  5000
      3       11  5500
      4       12  6000
      5       13  6500
      # i 12 more rows

---

    Code
      filter(ps, area > 1000)
    Output
      # patch_size_tbl:      data.frame
      # Species:             Blue-tongued Lizard
      # Patches:             23
      # Resolution:          2x2
      # Interpatch Distance: 8 m
        patch_id  area
           <dbl> <dbl>
      1        3  1500
      2        4  2000
      3        5  2500
      4        6  3000
      5        7  3500
      # i 18 more rows

---

    Code
      slice(ps, 1:10)
    Output
      # patch_size_tbl:      data.frame
      # Species:             Blue-tongued Lizard
      # Patches:             10
      # Resolution:          2x2
      # Interpatch Distance: 8 m
        patch_id  area
           <dbl> <dbl>
      1        1   500
      2        2  1000
      3        3  1500
      4        4  2000
      5        5  2500
      # i 5 more rows

---

    Code
      head(select(ps, -area))
    Message
      Removing attributes in <patch_size_tbl>
    Output
        patch_id
      1        1
      2        2
      3        3
      4        4
      5        5
      6        6

---

    Code
      head(select(ps, -patch_id))
    Message
      Removing attributes in <patch_size_tbl>
    Output
        area
      1  500
      2 1000
      3 1500
      4 2000
      5 2500
      6 3000

