# resolve_buffer_radius requires exactly one of the two args

    Code
      resolve_buffer_radius(interpatch_distance = 250, buffer_radius = 125)
    Condition
      Error in `resolve_buffer_radius()`:
      ! Specify exactly one of `interpatch_distance` or `buffer_radius`.
      x Both were supplied.

---

    Code
      resolve_buffer_radius(interpatch_distance = NULL, buffer_radius = NULL)
    Condition
      Error in `resolve_buffer_radius()`:
      ! Specify exactly one of `interpatch_distance` or `buffer_radius`.
      x Neither was supplied.

# warn_buffer_resolution warns when the radius is smaller than one cell

    Code
      warn_buffer_resolution(buffer_radius = 100, resolution = 500)
    Condition
      Warning:
      Can't represent the buffer at a resolution of 500m.
      x Buffer radius (100m) is smaller than one raster cell.
      i This radius corresponds to an `interpatch_distance` of 200m.
      i Gaps between patches aren't bridged; only touching patches are linked.
      i Rule of thumb: keep resolution <= interpatch_distance / 2 (use finer cells, or a larger interpatch distance).
      i See `vignette(urbioconnect::interpatch-distance-and-resolution)`.

# warn_buffer_resolution reports the effective distance when not a clean multiple

    Code
      warn_buffer_resolution(buffer_radius = 600, resolution = 500)
    Condition
      Warning:
      Buffer radius doesn't align with the raster resolution.
      x 600 m isn't a multiple of 500 m.
      i It snaps to 500 m (interpatch distance 1000 m).
      i Connectivity may shift for patches near the cut-off.
      i See `vignette(urbioconnect::interpatch-distance-and-resolution)`.

