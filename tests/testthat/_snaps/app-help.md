# every input but target_resolution has an i, outside its label

    Code
      setdiff(ids_ending("label"), ids_ending("help"))
    Output
      [1] "target_resolution"

# help_input() fails for an input with no help

    Code
      help_input(shiny::textInput, "speceis")
    Condition
      Error in `help_input()`:
      ! There is no help text for the "speceis" input.

# describe_analysis() says what the inputs add up to

    Code
      describe()
    Output
      - Blue Tongue Lizard example data, on a grid of 10 m cells.
      - Patches up to 100 m apart are joined, unless a barrier lies between them.
    Code
      describe(distances = c(100, 250, 400))
    Output
      - Blue Tongue Lizard example data, on a grid of 10 m cells.
      - The analysis runs once for each of 3 interpatch distances: 100, 250 and 400 m. At each, patches up to that distance apart are joined, unless a barrier lies between them.
      ! At 10 m cells, distances go up in steps of 20 m, so 250 m is treated as 240 m.
    Code
      describe(distances = 15)
    Output
      - Blue Tongue Lizard example data, on a grid of 10 m cells.
      - Patches up to 15 m apart are joined, unless a barrier lies between them.
      ! At 10 m cells, 15 m is too short to measure: half of it (7.5 m) is less than one cell, so only patches that touch will join. Use cells of 7 m or smaller, or a distance of at least 20 m.
    Code
      describe(distances = 1)
    Output
      - Blue Tongue Lizard example data, on a grid of 10 m cells.
      - Patches up to 1 m apart are joined, unless a barrier lies between them.
      ! At 10 m cells, 1 m is too short to measure: half of it (0.5 m) is less than one cell, so only patches that touch will join. Use a distance of at least 20 m.
    Code
      describe(data_resolution = 30, distances = c(20, 50, 100))
    Output
      - Blue Tongue Lizard example data, on a grid of 30 m cells.
      - The analysis runs once for each of 3 interpatch distances: 20, 50 and 100 m. At each, patches up to that distance apart are joined, unless a barrier lies between them.
      ! At 30 m cells, 20 and 50 m are too short to measure: half of each is less than one cell, so only patches that touch will join. Use cells of 10 m or smaller, or distances of at least 60 m.
      ! At 30 m cells, distances go up in steps of 60 m, so 100 m is treated as 60 m.
    Code
      describe(distances = c(50, 100, 150, 200, 250))
    Output
      - Blue Tongue Lizard example data, on a grid of 10 m cells.
      - The analysis runs once for each of 5 interpatch distances: 50, 100, 150, 200 and 250 m. At each, patches up to that distance apart are joined, unless a barrier lies between them.
      ! At 10 m cells, distances go up in steps of 20 m, so 50 m is treated as 40 m, 150 m as 140 m and 250 m as 240 m.
      ! You have entered 5 distances. Each is a separate analysis, so this takes longer. Up to four is usually enough to see the trend.
    Code
      describe(data = NULL)
    Output
      - Choose example data, or upload a habitat and a barrier layer. The analysis runs on a grid of 10 m cells.
      - Patches up to 100 m apart are joined, unless a barrier lies between them.
    Code
      describe(scenario = list(name = "A new road through the habitat", kind = "barrier"))
    Output
      - Blue Tongue Lizard example data, on a grid of 10 m cells.
      - Patches up to 100 m apart are joined, unless a barrier lies between them.
      - Then it runs again with "A new road through the habitat" in place of the barrier layer, and compares the two.
    Code
      describe(scenario = list(name = NULL, kind = "habitat"))
    Output
      - Blue Tongue Lizard example data, on a grid of 10 m cells.
      - Patches up to 100 m apart are joined, unless a barrier lies between them.
      - Then it runs again with your scenario layer in place of the habitat layer, and compares the two.

