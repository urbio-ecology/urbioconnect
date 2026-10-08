# The layer a scenario changed

An analysis carrying a scenario holds both of its landscapes, so the
layer that actually changed is whichever of them the scenario stood in
for. Ask rather than branching on `scenario_kind` at every call site.

## Usage

``` r
scenario_layer(x)
```

## Arguments

- x:

  A `connectivity_report_data`, from
  [`connectivity_report_data()`](https://urbio-ecology.github.io/urbioconnect/reference/connectivity_report_data.md).

## Value

The scenario's `SpatRaster`, or `NULL` when there is no scenario.

## See also

[`connectivity_report_data()`](https://urbio-ecology.github.io/urbioconnect/reference/connectivity_report_data.md),
and
[`gg_layer()`](https://urbio-ecology.github.io/urbioconnect/reference/gg_layer.md)
to draw it.

## Examples

``` r
# \donttest{
analysis <- connectivity_report_data(
  habitat = example_wren_habitat(),
  barrier = example_wren_barrier(),
  species = "Superb Fairy Wren",
  interpatch_distance = 200,
  scenario = example_wren_barrier_scenario(),
  scenario_kind = "barrier",
  verbose = FALSE
)

scenario_layer(analysis)
#> class       : SpatRaster
#> size        : 1500, 1400, 1  (nrow, ncol, nlyr)
#> resolution  : 9.996731, 10.00151  (x, y)
#> extent      : 340888.6, 354884, 5796348, 5811351  (xmin, xmax, ymin, ymax)
#> coord. ref. : GDA94 / MGA zone 55 (EPSG:28355)
#> source      : wren_barrier_scenario_rast.tif
#> name        : layer
#> min value   :     0
#> max value   :     1
# }
```
