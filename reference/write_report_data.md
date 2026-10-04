# Save and reload a connectivity analysis

Writes a `connectivity_report_data` object to an `.rds` file, and reads
it back. The summary, the habitat and barrier layers, and the patch
raster for each distance all travel together in the one file.

## Usage

``` r
write_report_data(x, path)

read_report_data(path)
```

## Arguments

- x:

  A `connectivity_report_data` object from
  [`connectivity_report_data()`](https://urbio-ecology.github.io/urbioconnect/reference/connectivity_report_data.md).

- path:

  File to write to, or read from.

## Value

`write_report_data()` returns `path` invisibly; `read_report_data()`
returns the `connectivity_report_data`.

## Details

[`base::saveRDS()`](https://rdrr.io/r/base/readRDS.html) on its own
isn't enough. A `SpatRaster` points at memory or at a file on disk
rather than carrying its own values, so it saves as a null pointer and
comes back unusable.
[`terra::wrap()`](https://rspatial.github.io/terra/reference/wrap.html)
packs the values into the object on the way out, and
[`terra::unwrap()`](https://rspatial.github.io/terra/reference/wrap.html)
restores them on the way in.

This is also how an analysis reaches the separate R session that Quarto
renders the report in.

## See also

[`connectivity_report_data()`](https://urbio-ecology.github.io/urbioconnect/reference/connectivity_report_data.md)

## Examples

``` r
# \donttest{
report_data <- connectivity_report_data(
  habitat = example_habitat(),
  barrier = example_barrier(),
  species = "Blue Tongue Lizard",
  interpatch_distance = 20,
  verbose = FALSE
)

path <- write_report_data(report_data, tempfile(fileext = ".rds"))
read_report_data(path)$connectivity
#> # A tibble: 1 × 9
#>   species     interpatch_distance n_patches effective_mesh_ha prob_connectedness
#>   <chr>                     <dbl>     <int>             <dbl>              <dbl>
#> 1 Blue Tongu…                  20       163              4.42          0.0000168
#> # ℹ 4 more variables: patch_area_mean <dbl>, patch_area_total_ha <dbl>,
#> #   data_resolution <chr>, patch_size <list>
# }
```
