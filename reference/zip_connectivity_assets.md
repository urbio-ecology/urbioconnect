# Write the downloadable assets as a single zip

[`write_connectivity_assets()`](https://urbio-ecology.github.io/urbioconnect/reference/write_connectivity_assets.md)
into a folder named for the species and the date, archived. This is what
the Shiny app's download button returns.

## Usage

``` r
zip_connectivity_assets(x, path)
```

## Arguments

- x:

  A `connectivity_report_data` object from
  [`connectivity_report_data()`](https://urbio-ecology.github.io/urbioconnect/reference/connectivity_report_data.md).

- path:

  Path to write the `.zip` to.

## Value

`path`, invisibly.

## See also

[`write_connectivity_assets()`](https://urbio-ecology.github.io/urbioconnect/reference/write_connectivity_assets.md)
to write the files without archiving.

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

zip_path <- zip_connectivity_assets(report_data, tempfile(fileext = ".zip"))
#> <SpatRaster> resampled to 500688 cells.
#> <SpatRaster> resampled to 500688 cells.
#> <SpatRaster> resampled to 500688 cells.
#> <SpatRaster> resampled to 500688 cells.
zip::zip_list(zip_path)$filename
#>  [1] "superb-fairy-wren-connectivity-2026-10-01/"                                               
#>  [2] "superb-fairy-wren-connectivity-2026-10-01/README.md"                                      
#>  [3] "superb-fairy-wren-connectivity-2026-10-01/interpatch-200m/"                               
#>  [4] "superb-fairy-wren-connectivity-2026-10-01/interpatch-200m/gis/"                           
#>  [5] "superb-fairy-wren-connectivity-2026-10-01/interpatch-200m/gis/patches.cpg"                
#>  [6] "superb-fairy-wren-connectivity-2026-10-01/interpatch-200m/gis/patches.dbf"                
#>  [7] "superb-fairy-wren-connectivity-2026-10-01/interpatch-200m/gis/patches.gpkg"               
#>  [8] "superb-fairy-wren-connectivity-2026-10-01/interpatch-200m/gis/patches.prj"                
#>  [9] "superb-fairy-wren-connectivity-2026-10-01/interpatch-200m/gis/patches.shp"                
#> [10] "superb-fairy-wren-connectivity-2026-10-01/interpatch-200m/gis/patches.shx"                
#> [11] "superb-fairy-wren-connectivity-2026-10-01/interpatch-200m/gis/patches.tif"                
#> [12] "superb-fairy-wren-connectivity-2026-10-01/interpatch-200m/maps/"                          
#> [13] "superb-fairy-wren-connectivity-2026-10-01/interpatch-200m/maps/habitat-buffer-barrier.png"
#> [14] "superb-fairy-wren-connectivity-2026-10-01/interpatch-200m/maps/patches.png"               
#> [15] "superb-fairy-wren-connectivity-2026-10-01/summary/"                                       
#> [16] "superb-fairy-wren-connectivity-2026-10-01/summary/connectivity-summary.csv"               
#> [17] "superb-fairy-wren-connectivity-2026-10-01/summary/patch-areas.csv"                        
# }
```
