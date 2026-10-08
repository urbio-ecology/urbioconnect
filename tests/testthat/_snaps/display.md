# connectivity_display() labels the columns and keeps numbers

    Code
      names(display$data)
    Output
      [1] "Species"         "Distance (m)"    "Patches"         "Mesh (ha)"      
      [5] "P(connected)"    "Mean area (m2)"  "Total area (ha)" "Resolution (m)" 

---

    Code
      as.data.frame(display$digits)
    Output
                 column   kind digits
      1       Mesh (ha)  round      2
      2    P(connected) signif      3
      3  Mean area (m2)  round      1
      4 Total area (ha)  round      2

# connectivity_display() handles a patch table

    Code
      names(display$data)
    Output
      [1] "Patch ID"  "Area (m2)"

# format_by() gives each value its own notation

    Code
      as.data.frame(formatted)
    Output
        Distance (m)          Metric Baseline Scenario value    Change % change
      1           40         Patches        3              2        -1    -33.3
      2           40       Mesh (ha)    0.915          0.743    -0.173    -18.9
      3           40    P(connected) 3.67e-05       2.97e-05 -6.91e-06    -18.9
      4           40  Mean area (m2)     8320           9200       879     10.6
      5           40 Total area (ha)      2.5           1.84    -0.657    -26.3

# a comparison is wide by default and long when asked

    Code
      names(wide)
    Output
      [1] "Distance (m)"   "Metric"         "Baseline"       "Scenario value"
      [5] "Change"         "% change"      

---

    Code
      wide$Metric
    Output
      [1] "Patches"         "Mesh (ha)"       "P(connected)"    "Mean area (m2)" 
      [5] "Total area (ha)"

---

    Code
      names(long)
    Output
       [1] "Scenario"        "Measure"         "Species"         "Distance (m)"   
       [5] "Patches"         "Mesh (ha)"       "P(connected)"    "Mean area (m2)" 
       [9] "Total area (ha)" "Resolution (m)" 

# a comparison with several scenarios stays numeric

    Code
      names(display$data)
    Output
      [1] "Scenario"       "Distance (m)"   "Metric"         "Baseline"      
      [5] "Scenario value" "Change"         "% change"      

# the long comparison rounds metrics but not identifiers

    Code
      display$digits$column
    Output
      [1] "Patches"         "Mesh (ha)"       "P(connected)"    "Mean area (m2)" 
      [5] "Total area (ha)"

# display_ids() names the identifier columns

    Code
      display_ids(connectivity_display(test_report_data(40)$connectivity))
    Output
      [1] "Species"        "Distance (m)"   "Resolution (m)"

# a display is rejected when its digit spec doesn't fit

    Code
      connectivity_display(data.frame(a = 1))
    Condition
      Error in `connectivity_display()`:
      ! Can't display a data frame.
      i `x` must be a <connectivity>, <patch_size_tbl> or <compare_connectivity> object.
    Code
      round_by(list(data = tibble::tibble(x = 1), digits = "nope"))
    Condition
      Error in `round_by()`:
      ! `display` must be a list of a data table and a digits table of column, kind and digits.
      i Build one with `connectivity_display()`.
    Code
      round_by(list(data = tibble::tibble(x = 1), digits = tibble::tibble(column = "absent",
        kind = "round", digits = 2)))
    Condition
      Error in `round_by()`:
      ! `display` has a digit rule for a column that isn't in the data.
      x Not found: absent.
    Code
      round_by(list(data = tibble::tibble(x = 1), digits = tibble::tibble(column = "x",
        kind = "nope", digits = 2)))
    Condition
      Error in `round_by()`:
      ! A digit rule's kind must be "round" or "signif".
      x Got "nope".

