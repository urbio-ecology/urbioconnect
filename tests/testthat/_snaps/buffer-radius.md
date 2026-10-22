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

# representable_distance() is the distance habitat_buffer()'s window spans

    Code
      representable_distance(distances, 10)
    Output
      [1]    0   20  100  240 1000

# representable_distance() checks its arguments

    Code
      representable_distance("100", 10)
    Condition
      Error in `representable_distance()`:
      ! `interpatch_distance` must be <numeric>, not <character>.
      i You supplied: a string
    Code
      representable_distance(100, c(10, 20))
    Condition
      Error in `representable_distance()`:
      ! `resolution` must be a scalar (length 1), not length 2.
      i Did you mean to pass a single value?
    Code
      representable_distance(100, 0)
    Condition
      Error in `representable_distance()`:
      ! `resolution` must be a positive number, not 0.

