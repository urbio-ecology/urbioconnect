# Calculate mean patch size

This is just a wrapper around
[`mean()`](https://rspatial.github.io/terra/reference/summarize-generics.html),
however it is written to clearly identify its use in the context of the
area data. Intended for usage from objects created by
[`habitat_connectivity()`](https://urbio-ecology.github.io/urbioconnect/reference/habitat_connectivity.md).
See examples below.

## Usage

``` r
mean_patch_size(area, ...)
```

## Arguments

- area:

  Numeric vector. Area of a connected patch.

- ...:

  extra arguments to pass to
  [`mean()`](https://rspatial.github.io/terra/reference/summarize-generics.html).

## Value

Numeric. Mean patch size.

## Examples

``` r
mean_patch_size(lizard_areas_connected$area)
#> [1] 3600.334
```
