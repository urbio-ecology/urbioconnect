# Write a connectivity report's source, so you can render it yourself

Writes the report as a Quarto document you own a copy of, next to the
data it draws. Open it, change it, render it.
[`render_connectivity_report()`](https://urbio-ecology.github.io/urbioconnect/reference/render_connectivity_report.md)
renders it the way the package does, and
[`generate_connectivity_report()`](https://urbio-ecology.github.io/urbioconnect/reference/generate_connectivity_report.md)
does both steps at once when the source isn't wanted.

## Usage

``` r
write_connectivity_report(x, path = NULL)
```

## Arguments

- x:

  A `connectivity_report_data` object from
  [`connectivity_report_data()`](https://urbio-ecology.github.io/urbioconnect/reference/connectivity_report_data.md).

- path:

  File to write, ending in `.qmd`. Defaults to the species and today's
  date, in the working directory. The directory must already exist.

## Value

The absolute path of the `.qmd`, invisibly.

## Details

Two files are written: `path`, and the analysis beside it as
`<name>-data.rds`. The document reads that file by name, so the two
travel together. Moving one without the other breaks the render.

## See also

[`render_connectivity_report()`](https://urbio-ecology.github.io/urbioconnect/reference/render_connectivity_report.md)
to render it,
[`generate_connectivity_report()`](https://urbio-ecology.github.io/urbioconnect/reference/generate_connectivity_report.md)
to do both.

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

qmd <- write_connectivity_report(
  report_data,
  file.path(tempdir(), "lizard-report.qmd")
)

readLines(qmd, n = 5)
#> [1] "---"                                   
#> [2] "title: \"Habitat connectivity report\""
#> [3] "date: today"                           
#> [4] "params:"                               
#> [5] "  report_data: null"                   
# }
```
