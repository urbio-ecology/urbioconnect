# The settings one analysis was run with

A key-value record of the run: what was analysed, what the caller
recorded about it, what grid that produced, and what built it. One row
per setting, so a run with one interpatch distance and a run with four
have the same shape, and a caller recording something of its own adds a
row rather than a column.

## Usage

``` r
connectivity_settings(x)
```

## Arguments

- x:

  A `connectivity_report_data` object from
  [`connectivity_report_data()`](https://urbio-ecology.github.io/urbioconnect/reference/connectivity_report_data.md).

## Value

A tibble of `setting` and `value`, both character. A setting that
doesn't apply is `NA`, which is written to the CSV as an empty cell.

## Details

The rows an analysis can't know for itself, where the layers came from
and the resolutions
[`prepare_rasters()`](https://urbio-ecology.github.io/urbioconnect/reference/prepare_rasters.md)
was called with, are whatever the caller passed as `settings` to
[`connectivity_report_data()`](https://urbio-ecology.github.io/urbioconnect/reference/connectivity_report_data.md).

`grid_resolution_m` is the grid the analysis actually ran on, unrounded.
A nominally 10 m grid comes out as `10.01307 x 9.973856`, and a
reproduction landing on exactly 10 x 10 is a different grid, so this is
the one place that doesn't go through
[`format_resolution()`](https://urbio-ecology.github.io/urbioconnect/reference/format_resolution.md).

## See also

[`connectivity_report_data()`](https://urbio-ecology.github.io/urbioconnect/reference/connectivity_report_data.md),
whose `settings` argument fills the caller's rows, and
[`write_connectivity_assets()`](https://urbio-ecology.github.io/urbioconnect/reference/write_connectivity_assets.md),
which writes this into the download bundle as `summary/settings.csv`.

## Examples

``` r
# \donttest{
report_data <- connectivity_report_data(
  habitat = example_habitat(),
  barrier = example_barrier(),
  species = "Blue Tongue Lizard",
  interpatch_distance = c(100, 250, 400),
  settings = list(
    habitat_source = "example data: lizard",
    data_resolution_m = 10
  ),
  verbose = FALSE
)

connectivity_settings(report_data)
#> # A tibble: 15 × 2
#>    setting               value                   
#>    <chr>                 <chr>                   
#>  1 species               Blue Tongue Lizard      
#>  2 interpatch_distance_m 100, 250, 400           
#>  3 habitat_source        example data: lizard    
#>  4 data_resolution_m     10                      
#>  5 grid_resolution_m     2 x 2                   
#>  6 grid_dimensions       763 x 766               
#>  7 crs                   GDA94 / MGA zone 55     
#>  8 crs_code              EPSG:28355              
#>  9 scenario_kind         none                    
#> 10 scenario_name         NA                      
#> 11 run_time              2026-10-28T04:38:52+0000
#> 12 urbioconnect_version  0.1.0.9000              
#> 13 terra_version         1.9.50                  
#> 14 r_version             4.6.1                   
#> 15 platform              x86_64-pc-linux-gnu     
# }
```
