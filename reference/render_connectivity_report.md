# Render a connectivity report's source

Renders a `.qmd` from
[`write_connectivity_report()`](https://urbio-ecology.github.io/urbioconnect/reference/write_connectivity_report.md).
The document carries its own figure sizes, so rendering it yourself with
the Render button or
[`quarto::quarto_render()`](https://quarto-dev.github.io/quarto-r/reference/quarto_render.html)
gives the same figures; this adds the choice of format by extension, the
Typst routing for a `.pdf`, and puts the output where you ask rather
than beside the input.

## Usage

``` r
render_connectivity_report(input, path = NULL, format = report_format(path))
```

## Arguments

- input:

  The `.qmd` to render, from
  [`write_connectivity_report()`](https://urbio-ecology.github.io/urbioconnect/reference/write_connectivity_report.md).
  Its `-data.rds` must still be beside it.

- path:

  File to write. The extension sets the format, as it does for
  [`ggplot2::ggsave()`](https://ggplot2.tidyverse.org/reference/ggsave.html).
  Defaults to `input` with a `.html` extension. The directory must
  already exist.

- format:

  The Quarto format, when `path` can't say. See
  [`generate_connectivity_report()`](https://urbio-ecology.github.io/urbioconnect/reference/generate_connectivity_report.md).

## Value

The absolute path written, invisibly.

## See also

[`write_connectivity_report()`](https://urbio-ecology.github.io/urbioconnect/reference/write_connectivity_report.md)
to write the source.

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

# rendering needs the Quarto command line tool
if (quarto_available()) {
  render_connectivity_report(qmd)
}
#> Rendering html report...
#> Wrote /tmp/RtmpGvKVZO/lizard-report.html
# }
```
