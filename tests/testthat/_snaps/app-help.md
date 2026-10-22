# every input but target_resolution has an i

    Code
      ids[!has_help]
    Output
      [1] "target_resolution"

# help_label() fails for an input with no help

    Code
      help_label("speceis")
    Condition
      Error in `help_label()`:
      ! There is no help text for the "speceis" input.

