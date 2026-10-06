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
        Distance (m)          Metric Baseline Scenario    Change % change
      1           40         Patches        3        2        -1    -33.3
      2           40       Mesh (ha)    0.915    0.743    -0.173    -18.9
      3           40    P(connected) 3.67e-05 2.97e-05 -6.91e-06    -18.9
      4           40  Mean area (m2)     8320     9200       879     10.6
      5           40 Total area (ha)      2.5     1.84    -0.657    -26.3

# a comparison is wide by default and long when asked

    Code
      names(wide)
    Output
      [1] "Distance (m)" "Metric"       "Baseline"     "Scenario"     "Change"      
      [6] "% change"    

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
      [1] "Measure"         "Species"         "Distance (m)"    "Patches"        
      [5] "Mesh (ha)"       "P(connected)"    "Mean area (m2)"  "Total area (ha)"
      [9] "Resolution (m)" 

