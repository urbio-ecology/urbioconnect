# col2hex converts colour name to hex

    Code
      col2hex("forestgreen")
    Output
      [1] "#228B22"

---

    Code
      col2hex("blue")
    Output
      [1] "#0000FF"

# to_sentence converts snake_case to sentence case

    Code
      to_sentence("prob_connectedness")
    Output
      [1] "Prob connectedness"

---

    Code
      to_sentence(c("n_patches", "patch_area_mean"))
    Output
      [1] "N patches"       "Patch area mean"

# gg_layer rejects a layer it has no colours for

    Code
      gg_layer(example_habitat(), "interpatch")
    Condition
      Error in `gg_layer()`:
      ! `kind` must be one of "habitat" or "barrier", not "interpatch".

