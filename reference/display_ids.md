# Which display columns identify a row rather than measure it

So a consumer that has to pivot or drop the identifiers can ask, rather
than hardcoding the label text.

## Usage

``` r
display_ids(display)
```

## Arguments

- display:

  A list from
  [`connectivity_display()`](https://urbio-ecology.github.io/urbioconnect/reference/connectivity_display.md).

## Value

A character vector of column labels.

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

display_ids(connectivity_display(lizard))
#> [1] "Species"        "Distance (m)"   "Resolution (m)"
```
