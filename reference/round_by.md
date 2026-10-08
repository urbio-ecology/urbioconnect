# Apply the rounding a display describes

`round_by()` rounds and leaves the values numeric, which is right when
each column holds one metric. `format_by()` formats each value to a
string instead, which is what a column of several metrics needs: a
numeric column spanning 1e-5 to 1e4 prints wholly in scientific
notation, so a count of 3 reads as `3.00e+00`.
[`DT::datatable()`](https://rdrr.io/pkg/DT/man/datatable.html) formats
cell by cell and so needs neither;
[`knitr::kable()`](https://rdrr.io/pkg/knitr/man/kable.html) formats by
column and so needs `format_by()` for a comparison.

## Usage

``` r
round_by(display)

format_by(display)
```

## Arguments

- display:

  A list from
  [`connectivity_display()`](https://urbio-ecology.github.io/urbioconnect/reference/connectivity_display.md).

## Value

The `data` tibble: numeric from `round_by()`, character from
`format_by()`.

## See also

[`connectivity_display()`](https://urbio-ecology.github.io/urbioconnect/reference/connectivity_display.md)

## Examples

``` r
lizard <- habitat_connectivity(
  habitat = example_habitat(),
  barrier = example_barrier(),
  species = "Blue Tongue Lizard",
  interpatch_distance = 20,
  verbose = FALSE
)

round_by(connectivity_display(lizard))
#> # A tibble: 1 × 8
#>   Species     `Distance (m)` Patches `Mesh (ha)` `P(connected)` `Mean area (m2)`
#>   <chr>                <dbl>   <int>       <dbl>          <dbl>            <dbl>
#> 1 Blue Tongu…             20     163        4.42      0.0000168            1612.
#> # ℹ 2 more variables: `Total area (ha)` <dbl>, `Resolution (m)` <chr>
```
