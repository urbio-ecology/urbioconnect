# The name to give a download: species and date

The stem every download takes its name from, so a report, a zip and the
folder inside that zip agree. The species is lower-cased with its spaces
turned into dashes, which keeps it usable as a file name.

## Usage

``` r
connectivity_file_stem(x)
```

## Arguments

- x:

  A `connectivity_report_data` object from
  [`connectivity_report_data()`](https://urbio-ecology.github.io/urbioconnect/reference/connectivity_report_data.md).

## Value

A string, with no extension.

## See also

[`generate_connectivity_report()`](https://urbio-ecology.github.io/urbioconnect/reference/generate_connectivity_report.md)
and
[`write_connectivity_report()`](https://urbio-ecology.github.io/urbioconnect/reference/write_connectivity_report.md),
whose `path` defaults to this, and
[`zip_connectivity_assets()`](https://urbio-ecology.github.io/urbioconnect/reference/zip_connectivity_assets.md),
which names the folder inside the archive with it.

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

connectivity_file_stem(report_data)
#> [1] "blue-tongue-lizard-connectivity-2026-10-05"
# }
```
