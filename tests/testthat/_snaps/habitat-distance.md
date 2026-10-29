# habitat_within() refuses a radius past the surface's reach

    Code
      habitat_within(surface, 40)
    Condition
      Error in `habitat_within()`:
      ! Can't buffer by 40m using a surface measured to 20m.
      x Cells past the surface's reach are unmeasured, so the buffer would be truncated.
      i Measure the surface to at least 40m.

# a habitat layer with several layers is an error

    Code
      habitat_buffer(stacked, 20)
    Condition
      Error in `habitat_buffer()`:
      ! `habitat` must have one layer, not 2.
    Code
      habitat_connectivity(stacked, layer, "lizard", 40, verbose = FALSE)
    Condition
      Error in `drop_habitat_under_barrier()`:
      ! `habitat` must have one layer, not 2.

# habitat_buffer() rejects radii it can't use

    Code
      habitat_buffer(layer, -20)
    Condition
      Error in `habitat_buffer()`:
      ! `buffer_radius` must be finite and not negative.
      x Not usable: -20.
    Code
      habitat_buffer(layer, c(20, NA))
    Condition
      Error in `habitat_buffer()`:
      ! `buffer_radius` must be finite and not negative.
      x Not usable: NA.
    Code
      habitat_buffer(layer, Inf)
    Condition
      Error in `habitat_buffer()`:
      ! `buffer_radius` must be finite and not negative.
      x Not usable: Inf.
    Code
      habitat_buffer(layer, c(20, 20))
    Condition
      Error in `habitat_buffer()`:
      ! `buffer_radius` must not repeat a distance.
      x Repeated: 20.

# habitat_buffer() gives one layer per radius, each as if alone

    Code
      names(both)
    Output
      [1] "radius_50" "radius_20"

# habitat_buffer() warns below one cell and keeps only the habitat

    Code
      buffered <- habitat_buffer(layer, c(5, 20))
    Condition
      Warning:
      Can't represent an `interpatch_distance` of 10m at a resolution of 10m.
      x Half that distance (5m) is smaller than one raster cell.
      i Gaps between patches aren't bridged; only touching patches are linked.
      i Rule of thumb: keep resolution <= interpatch_distance / 2 (use finer cells, or a larger interpatch distance).
      i See `vignette(urbioconnect::interpatch-distance-and-resolution)`.

# habitat_buffer() judges 'below one cell' by the smaller cell side

    Code
      buffered <- habitat_buffer(layer, 9.7)
    Condition
      Warning:
      `interpatch_distance` doesn't align with the raster resolution.
      x 19.4 m isn't a multiple of 19 m.
      i It snaps to 19 m.
      i Connectivity may shift for patches near the cut-off.
      i See `vignette(urbioconnect::interpatch-distance-and-resolution)`.

