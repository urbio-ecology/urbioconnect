# The default figure size for urbioconnect maps and plots

Shared by the downloadable PNGs and the report, so a map keeps its shape
across both. Width and heights are inches and `dpi` is dots per inch, as
[`ggplot2::ggsave()`](https://ggplot2.tidyverse.org/reference/ggsave.html)
and Quarto's `fig-width`, `fig-height` and `fig-dpi` expect.
`tall_height` is for the faceted over-distance plot, which needs more
vertical room than a map.

## Usage

``` r
urbio_figure_size()
```

## Value

A named list: `width`, `height`, `tall_height` and `dpi`.

## Examples

``` r
urbio_figure_size()
#> $width
#> [1] 8
#> 
#> $height
#> [1] 6
#> 
#> $tall_height
#> [1] 8
#> 
#> $dpi
#> [1] 150
#> 
```
