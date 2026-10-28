# Calculate effective mesh size

Computes the effective mesh size metric for habitat connectivity. This
is the expected area of habitat reachable from a randomly chosen point
in habitat without crossing a barrier. Intended for usage from objects
created by
[`habitat_connectivity()`](https://urbio-ecology.github.io/urbioconnect/reference/habitat_connectivity.md).
See examples below.

## Usage

``` r
effective_mesh_size(area, area_baseline = area)
```

## Arguments

- area:

  Numeric vector. Area of each connected patch, in square metres.

- area_baseline:

  Optional. Defaults to `area` if not specified. Numeric vector of the
  baseline's connected patch areas, in square metres. This is to allow
  for comparing the effective mesh size when comparing different
  scenarios.

## Value

Numeric. Effective mesh size, in hectares.

## Examples

``` r
effective_mesh_size(lizard_areas_connected$area)
#> [1] 4.473824
```
