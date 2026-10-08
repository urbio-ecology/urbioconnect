# Prepare a result for display

Labels the columns and says how precisely each should be shown, so a
table on screen and the same table in a report agree. Values come back
**numeric**: the rounding is described rather than applied, because
[`DT::datatable()`](https://rdrr.io/pkg/DT/man/datatable.html) needs
numbers to stay numbers to sort them, while
[`knitr::kable()`](https://rdrr.io/pkg/knitr/man/kable.html) wants them
already rounded.
[`round_by()`](https://urbio-ecology.github.io/urbioconnect/reference/round_by.md)
applies the rounding when that is what you want.

## Usage

``` r
connectivity_display(x, ...)

# S3 method for class 'connectivity'
connectivity_display(x, ...)

# S3 method for class 'patch_size_tbl'
connectivity_display(x, ...)

# S3 method for class 'compare_connectivity'
connectivity_display(x, wide = TRUE, ...)

# Default S3 method
connectivity_display(x, ...)
```

## Arguments

- x:

  A `connectivity`, `patch_size_tbl` or `compare_connectivity` object.

- ...:

  Passed to methods.

- wide:

  For a comparison, one row per metric and a column per measure, which
  is the shape a reader wants. `FALSE` keeps the object's own shape: one
  row per measure, a column per metric.

## Value

A list of

- `data`, a tibble with display labels and numeric values

- `digits`, a tibble of `column`, `kind` (`"round"` or `"signif"`) and
  `digits`, one row per column that needs rounding

## See also

[`round_by()`](https://urbio-ecology.github.io/urbioconnect/reference/round_by.md)
to apply the rounding.

## Examples

``` r
lizard <- habitat_connectivity(
  habitat = example_habitat(),
  barrier = example_barrier(),
  species = "Blue Tongue Lizard",
  interpatch_distance = 20,
  verbose = FALSE
)

display <- connectivity_display(lizard)
display$digits
#> # A tibble: 4 × 3
#>   column          kind   digits
#>   <chr>           <chr>   <dbl>
#> 1 Mesh (ha)       round       2
#> 2 P(connected)    signif      3
#> 3 Mean area (m2)  round       1
#> 4 Total area (ha) round       2
round_by(display)
#> # A tibble: 1 × 8
#>   Species     `Distance (m)` Patches `Mesh (ha)` `P(connected)` `Mean area (m2)`
#>   <chr>                <dbl>   <int>       <dbl>          <dbl>            <dbl>
#> 1 Blue Tongu…             20     163        4.42      0.0000168            1612.
#> # ℹ 2 more variables: `Total area (ha)` <dbl>, `Resolution (m)` <chr>
```
