# Write the downloadable assets for one analysis

Writes every map, table and GIS layer a planner needs into `dir`, laid
out in folders by interpatch distance, with a README explaining each
file.
[`zip_connectivity_assets()`](https://urbio-ecology.github.io/urbioconnect/reference/zip_connectivity_assets.md)
wraps this into a single archive, which is what the Shiny app's download
button uses.

## Usage

``` r
write_connectivity_assets(x, dir)
```

## Arguments

- x:

  A `connectivity_report_data` object from
  [`connectivity_report_data()`](https://urbio-ecology.github.io/urbioconnect/reference/connectivity_report_data.md).

- dir:

  Directory to write into. Created if it doesn't exist.

## Value

The manifest, invisibly: a tibble of `path`, `kind` and `description`,
one row per file written, with paths relative to `dir`.

## See also

[`connectivity_report_data()`](https://urbio-ecology.github.io/urbioconnect/reference/connectivity_report_data.md),
[`zip_connectivity_assets()`](https://urbio-ecology.github.io/urbioconnect/reference/zip_connectivity_assets.md)

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

assets <- write_connectivity_assets(report_data, dir = tempfile())
#> <SpatRaster> resampled to 500688 cells.
#> <SpatRaster> resampled to 500688 cells.
#> <SpatRaster> resampled to 500688 cells.
#> <SpatRaster> resampled to 500688 cells.
assets$path
#> [1] "README.md"                                      
#> [2] "summary/connectivity-summary.csv"               
#> [3] "summary/patch-areas.csv"                        
#> [4] "interpatch-200m/maps/habitat-buffer-barrier.png"
#> [5] "interpatch-200m/maps/patches.png"               
#> [6] "interpatch-200m/gis/patches.tif"                
#> [7] "interpatch-200m/gis/patches.gpkg"               
#> [8] "interpatch-200m/gis/patches.shp"                
# }
```
