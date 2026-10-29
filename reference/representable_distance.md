# The interpatch distance a grid can represent

Buffering grows habitat a whole cell at a time, by half the interpatch
distance from each side, so a distance is rounded down to a multiple of
twice the cell size. Below twice the cell size nothing is buffered, and
only patches that touch are joined.
[`habitat_connectivity()`](https://urbio-ecology.github.io/urbioconnect/reference/habitat_connectivity.md)
warns when either happens; this says which distance you get, before you
run anything.

## Usage

``` r
representable_distance(interpatch_distance, resolution)
```

## Arguments

- interpatch_distance:

  Numeric vector of distances, in metres.

- resolution:

  Cell size in metres, a single positive number.

## Value

A numeric vector the length of `interpatch_distance`: the distance each
is treated as. `0` where it can't be represented, which includes a
negative distance. `NA` stays `NA`.

## See also

[`vignette("interpatch-distance-and-resolution")`](https://urbio-ecology.github.io/urbioconnect/articles/interpatch-distance-and-resolution.md)

## Examples

``` r
representable_distance(c(100, 250, 15), resolution = 10)
#> [1] 100 240   0
```
