# Render a connectivity report

One document holding the maps, tables and summary for an analysis: the
same figures
[`write_connectivity_assets()`](https://urbio-ecology.github.io/urbioconnect/reference/write_connectivity_assets.md)
writes, laid out to read. HTML is a single self-contained file; PDF is
rendered through Typst, so no LaTeX is needed.

## Usage

``` r
generate_connectivity_report(x, path = NULL, format = report_format(path))
```

## Arguments

- x:

  A `connectivity_report_data` object from
  [`connectivity_report_data()`](https://urbio-ecology.github.io/urbioconnect/reference/connectivity_report_data.md).

- path:

  File to write. The extension sets the format. Defaults to the species,
  today's date and `.html`, in the working directory. The directory must
  already exist.

- format:

  The Quarto format, when `path` can't say. Taken from `path`'s
  extension by default, which is what you want unless the destination is
  a name something else chose, as
  [`shiny::downloadHandler()`](https://rdrr.io/pkg/shiny/man/downloadHandler.html)
  does.

## Value

The absolute path written, invisibly.

## Details

[`write_connectivity_report()`](https://urbio-ecology.github.io/urbioconnect/reference/write_connectivity_report.md)
then
[`render_connectivity_report()`](https://urbio-ecology.github.io/urbioconnect/reference/render_connectivity_report.md),
in one call, through a temporary directory. Use those two instead when
you want the Quarto source to keep or to change.

The report covers the tabular and visual results. The GIS layers travel
with
[`zip_connectivity_assets()`](https://urbio-ecology.github.io/urbioconnect/reference/zip_connectivity_assets.md),
since a GeoTIFF can't live inside a document.

The format comes from `path`'s extension, as it does for
[`ggplot2::ggsave()`](https://ggplot2.tidyverse.org/reference/ggsave.html):
`"report.pdf"` writes a PDF and `"report.html"` an HTML file. Write both
by calling this twice.

Any format Quarto can write to a single file works, so `"report.docx"`
and `"report.rtf"` also do what they look like. The Shiny app offers
HTML and PDF only. A `.pdf` renders through Typst rather than Quarto's
LaTeX-based `pdf` format, so no TeX install is needed.

Formats that keep their figures in a folder beside the document, such as
`.md`, are refused: a report has to be one file, and copying the
document alone would lose every figure. Note too that the tabbed
sections are HTML-only and fall back to plain headings everywhere else.

## See also

[`connectivity_report_data()`](https://urbio-ecology.github.io/urbioconnect/reference/connectivity_report_data.md)
to build `x`,
[`write_connectivity_report()`](https://urbio-ecology.github.io/urbioconnect/reference/write_connectivity_report.md)
for the Quarto source, and
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

# rendering needs the Quarto command line tool
if (quarto_available()) {
  generate_connectivity_report(
    report_data,
    file.path(tempdir(), "lizard-report.html")
  )
}
#> Rendering html report...
#> Wrote /tmp/RtmpGvKVZO/lizard-report.html
# }
```
