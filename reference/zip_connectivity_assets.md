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

The absolute path written, invisibly.

## See also

[`write_connectivity_assets()`](https://urbio-ecology.github.io/urbioconnect/reference/write_connectivity_assets.md)
to write the files without archiving.

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

zip_path <- zip_connectivity_assets(report_data, tempfile(fileext = ".zip"))
#> <SpatRaster> resampled to 500554 cells.
#> <SpatRaster> resampled to 500554 cells.
#> <SpatRaster> resampled to 500554 cells.
#> <SpatRaster> resampled to 500554 cells.
zip::zip_list(zip_path)$filename
#>  [1] "blue-tongue-lizard-connectivity-2026-10-04/"                                              
#>  [2] "blue-tongue-lizard-connectivity-2026-10-04/README.md"                                     
#>  [3] "blue-tongue-lizard-connectivity-2026-10-04/interpatch-20m/"                               
#>  [4] "blue-tongue-lizard-connectivity-2026-10-04/interpatch-20m/gis/"                           
#>  [5] "blue-tongue-lizard-connectivity-2026-10-04/interpatch-20m/gis/patches.cpg"                
#>  [6] "blue-tongue-lizard-connectivity-2026-10-04/interpatch-20m/gis/patches.dbf"                
#>  [7] "blue-tongue-lizard-connectivity-2026-10-04/interpatch-20m/gis/patches.gpkg"               
#>  [8] "blue-tongue-lizard-connectivity-2026-10-04/interpatch-20m/gis/patches.prj"                
#>  [9] "blue-tongue-lizard-connectivity-2026-10-04/interpatch-20m/gis/patches.shp"                
#> [10] "blue-tongue-lizard-connectivity-2026-10-04/interpatch-20m/gis/patches.shx"                
#> [11] "blue-tongue-lizard-connectivity-2026-10-04/interpatch-20m/gis/patches.tif"                
#> [12] "blue-tongue-lizard-connectivity-2026-10-04/interpatch-20m/maps/"                          
#> [13] "blue-tongue-lizard-connectivity-2026-10-04/interpatch-20m/maps/habitat-buffer-barrier.png"
#> [14] "blue-tongue-lizard-connectivity-2026-10-04/interpatch-20m/maps/patches.png"               
#> [15] "blue-tongue-lizard-connectivity-2026-10-04/summary/"                                      
#> [16] "blue-tongue-lizard-connectivity-2026-10-04/summary/connectivity-summary.csv"              
#> [17] "blue-tongue-lizard-connectivity-2026-10-04/summary/patch-areas.csv"                       
# }
```
