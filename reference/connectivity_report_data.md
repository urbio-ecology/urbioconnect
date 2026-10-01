# Everything one connectivity analysis produces

Runs the connectivity pipeline once per distance and keeps both the
summary and the spatial layers the maps need.
[`habitat_connectivity()`](https://urbio-ecology.github.io/urbioconnect/reference/habitat_connectivity.md)
returns the summary alone; this also keeps the buffered habitat and the
patch-ID raster for each distance, which is what the downloadable assets
and the report are built from.

## Usage

``` r
connectivity_report_data(
  habitat,
  barrier,
  species,
  interpatch_distance,
  verbose = TRUE
)
```

## Arguments

- habitat:

  Terra SpatRaster. The habitat layer.

- barrier:

  Terra SpatRaster. The barrier layer.

- species:

  Species name. E.g., "Superb Fairy Wren".

- interpatch_distance:

  Numeric. The distance (in metres) at which habitat patches are
  considered connected. May be a scalar or a vector; a vector runs the
  pipeline once per distance.

- verbose:

  Logical. Display progress messages (default: TRUE).

## Value

A `connectivity_report_data` object: a list of

- `connectivity`, a `connectivity` summary with one row per distance

- `habitat` and `barrier`, the layers as supplied

- `buffered_habitat` and `patch_id_raster`, lists of `SpatRaster`, one
  per distance and named by it

- `species` and `interpatch_distance`

## See also

[`habitat_connectivity()`](https://urbio-ecology.github.io/urbioconnect/reference/habitat_connectivity.md)
when only the summary is wanted.

## Examples

``` r
# \donttest{
report_data <- connectivity_report_data(
  habitat = example_wren_habitat(),
  barrier = example_wren_barrier(),
  species = "Superb Fairy Wren",
  interpatch_distance = 200,
  verbose = FALSE
)

report_data$connectivity
#> # A tibble: 1 × 9
#>   species     interpatch_distance n_patches effective_mesh_ha prob_connectedness
#>   <chr>                     <dbl>     <int>             <dbl>              <dbl>
#> 1 Superb Fai…                 200       282              334.          0.0000225
#> # ℹ 4 more variables: patch_area_mean <dbl>, patch_area_total_ha <dbl>,
#> #   data_resolution <chr>, patch_size <list>
names(report_data$patch_id_raster)
#> [1] "200"
# }
```
