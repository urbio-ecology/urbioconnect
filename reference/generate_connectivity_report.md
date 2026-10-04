# Render a connectivity report

One document holding the maps, tables and summary for an analysis: the
same figures
[`write_connectivity_assets()`](https://urbio-ecology.github.io/urbioconnect/reference/write_connectivity_assets.md)
writes, laid out to read. HTML is a single self-contained file; PDF is
rendered through Typst, so no LaTeX is needed.

## Usage

``` r
generate_connectivity_report(
  x,
  output_format = c("html", "pdf", "both"),
  output_dir = ".",
  output_file = NULL
)
```

## Arguments

- x:

  A `connectivity_report_data` object from
  [`connectivity_report_data()`](https://urbio-ecology.github.io/urbioconnect/reference/connectivity_report_data.md).

- output_format:

  One of `"html"`, `"pdf"`, or `"both"`.

- output_dir:

  Directory to write the report to, defaulting to the working directory.
  Created if it doesn't exist.

- output_file:

  File name, without extension. Defaults to the species and today's
  date, matching the asset bundle's folder name.

## Value

The absolute path(s) written, invisibly.

## Details

The report covers the tabular and visual results. The GIS layers travel
with
[`zip_connectivity_assets()`](https://urbio-ecology.github.io/urbioconnect/reference/zip_connectivity_assets.md),
since a GeoTIFF can't live inside a document.

## See also

[`connectivity_report_data()`](https://urbio-ecology.github.io/urbioconnect/reference/connectivity_report_data.md)
to build `x`, and
[`zip_connectivity_assets()`](https://urbio-ecology.github.io/urbioconnect/reference/zip_connectivity_assets.md)
for the GIS layers and full tables.

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

generate_connectivity_report(report_data, output_dir = tempdir())
#> Rendering html report...
#> Wrote /tmp/RtmplosYiV/blue-tongue-lizard-connectivity-2026-10-04.html
# }
```
