# Write the reports as a single zip

The HTML and PDF reports, in a folder named for the species and the
date, archived. This is the app's reports-only download, for someone who
wants the write-up without the GIS layers. The analysis is packed once
and rendered twice, so this costs less than two separate calls.

## Usage

``` r
zip_connectivity_reports(x, path)
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

[`zip_connectivity_assets()`](https://urbio-ecology.github.io/urbioconnect/reference/zip_connectivity_assets.md)
for everything, and
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

# rendering needs the Quarto command line tool
if (quarto_available()) {
  zip_path <- zip_connectivity_reports(
    report_data,
    tempfile(fileext = ".zip")
  )
  zip::zip_list(zip_path)$filename
}
#> Rendering html report...
#> Wrote
#> /tmp/RtmpGvKVZO/urbioconnect-zip21c732431922/blue-tongue-lizard-connectivity-2026-10-05/report.html
#> Rendering pdf report...
#> Wrote
#> /tmp/RtmpGvKVZO/urbioconnect-zip21c732431922/blue-tongue-lizard-connectivity-2026-10-05/report.pdf
#> [1] "blue-tongue-lizard-connectivity-2026-10-05/"           
#> [2] "blue-tongue-lizard-connectivity-2026-10-05/report.html"
#> [3] "blue-tongue-lizard-connectivity-2026-10-05/report.pdf" 
# }
```
