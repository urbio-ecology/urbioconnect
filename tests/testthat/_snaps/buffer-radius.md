# habitat_connectivity() requires one numeric interpatch distance

    Code
      connectivity_at()
    Condition
      Error in `habitat_connectivity()`:
      ! `interpatch_distance` is absent but must be supplied.
    Code
      connectivity_at(interpatch_distance = c(40, 80))
    Condition
      Error in `habitat_connectivity()`:
      ! `interpatch_distance` must be a scalar (length 1), not length 2.
      i Did you mean to pass a single value?
    Code
      connectivity_at(interpatch_distance = "40")
    Condition
      Error in `habitat_connectivity()`:
      ! `interpatch_distance` must be <numeric>, not <character>.
      i You supplied: a string

# warn_buffer_resolution warns when the radius is smaller than one cell

    Code
      warn_buffer_resolution(buffer_radius = 100, resolution = 500)
    Condition
      Warning:
      Can't represent an `interpatch_distance` of 200m at a resolution of 500m.
      x Half that distance (100m) is smaller than one raster cell.
      i Gaps between patches aren't bridged; only touching patches are linked.
      i Rule of thumb: keep resolution <= interpatch_distance / 2 (use finer cells, or a larger interpatch distance).
      i See `vignette(urbioconnect::interpatch-distance-and-resolution)`.

# warn_buffer_resolution reports the effective distance when not a clean multiple

    Code
      warn_buffer_resolution(buffer_radius = 600, resolution = 500)
    Condition
      Warning:
      `interpatch_distance` doesn't align with the raster resolution.
      x 1200 m isn't a multiple of 1000 m.
      i It snaps to 1000 m.
      i Connectivity may shift for patches near the cut-off.
      i See `vignette(urbioconnect::interpatch-distance-and-resolution)`.

