# Is the Quarto command line tool installed?

Quarto is separate software, not an R package, so it can be missing. The
reports need it; nothing else in urbioconnect does. Ask this to decide
what to offer: the Shiny app disables its report buttons when it returns
`FALSE`, and `reports` defaults to it in
[`write_connectivity_assets()`](https://urbio-ecology.github.io/urbioconnect/reference/write_connectivity_assets.md).

## Usage

``` r
quarto_available()
```

## Value

`TRUE` or `FALSE`.

## See also

[`generate_connectivity_report()`](https://urbio-ecology.github.io/urbioconnect/reference/generate_connectivity_report.md),
which needs it.

## Examples

``` r
quarto_available()
#> [1] TRUE
```
