# Write the downloadable assets for one analysis

Writes every map, table and GIS layer a planner needs into `dir`, laid
out in folders by interpatch distance, with a README explaining each
file.
[`zip_connectivity_assets()`](https://urbio-ecology.github.io/urbioconnect/reference/zip_connectivity_assets.md)
wraps this into a single archive, which is what the Shiny app's download
button uses.

## Usage

``` r
write_connectivity_assets(x, dir, reports = quarto_available())
```

## Arguments

- x:

  A `connectivity_report_data` object from
  [`connectivity_report_data()`](https://urbio-ecology.github.io/urbioconnect/reference/connectivity_report_data.md).

- dir:

  Directory to write into. Created if it doesn't exist.

- reports:

  Also render the HTML and PDF reports into `dir`. Defaults to whether
  the Quarto command line tool is installed, since it is the one thing
  here that needs it: without Quarto the maps, tables and GIS layers are
  still written, and a message says the reports were skipped. Costs
  about 15 seconds per format.

## Value

The manifest, invisibly: a tibble of `path`, `kind` and `description`,
one row per file written, with paths relative to `dir`.

## See also

[`connectivity_report_data()`](https://urbio-ecology.github.io/urbioconnect/reference/connectivity_report_data.md),
[`zip_connectivity_assets()`](https://urbio-ecology.github.io/urbioconnect/reference/zip_connectivity_assets.md),
and
[`generate_connectivity_report()`](https://urbio-ecology.github.io/urbioconnect/reference/generate_connectivity_report.md)
for one report on its own.

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

assets <- write_connectivity_assets(
  report_data,
  dir = tempfile(),
  reports = FALSE
)
#> <SpatRaster> resampled to 500554 cells.
#> <SpatRaster> resampled to 500554 cells.
#> <SpatRaster> resampled to 500554 cells.
#> <SpatRaster> resampled to 500554 cells.
assets$path
#> [1] "README.md"                                     
#> [2] "summary/connectivity-summary.csv"              
#> [3] "summary/patch-areas.csv"                       
#> [4] "interpatch-20m/maps/habitat-buffer-barrier.png"
#> [5] "interpatch-20m/maps/patches.png"               
#> [6] "interpatch-20m/gis/patches.tif"                
#> [7] "interpatch-20m/gis/patches.gpkg"               
#> [8] "interpatch-20m/gis/patches.shp"                
# }
```
