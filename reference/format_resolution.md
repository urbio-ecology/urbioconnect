# Format a raster resolution for reading

A reprojected raster rarely has round cells: a nominally 10m grid comes
out as `9.99673 x 10.00151`. That precision matters in the data and
reads as noise on a screen, so round it for display.

## Usage

``` r
format_resolution(res, digits = 1)
```

## Arguments

- res:

  Either the numeric pair
  [`terra::res()`](https://rspatial.github.io/terra/reference/dimensions.html)
  returns, or the `"9.99673x10.00151"` string carried in a
  `connectivity` object's `data_resolution` column.

- digits:

  Decimal places to round to. Default 1.

## Value

A character vector, e.g. `"10 x 10"`.

## Examples

``` r
format_resolution(c(9.99673, 10.00151))
#> [1] "10 x 10"
format_resolution("9.99673x10.00151")
#> [1] "10 x 10"
```
