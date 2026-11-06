# Extract the per-patch tables from a `connectivity` object

A `connectivity` object (from
[`habitat_connectivity()`](https://urbio-ecology.github.io/urbioconnect/reference/habitat_connectivity.md)
or
[`summarise_connectivity()`](https://urbio-ecology.github.io/urbioconnect/reference/summarise-connectivity.md))
carries the underlying per-patch areas in a `patch_size` list-column.
`patch_sizes()` returns them.

## Usage

``` r
patch_sizes(x)
```

## Arguments

- x:

  A `connectivity` object.

## Value

A list of
[`patch_size_tbl()`](https://urbio-ecology.github.io/urbioconnect/reference/new_patch_size_tbl.md)
objects, one per row of `x` (always a list, even for a single-row
summary).

## Examples

``` r
lizard_connectivity <- habitat_connectivity(
  habitat = example_habitat(),
  barrier = example_barrier(),
  species = "Blue-tongued Lizard",
  interpatch_distance = 20,
  verbose = FALSE
)

# a list with a table of patch areas for each row of the summary
lizard_patch_sizes <- patch_sizes(lizard_connectivity)

lizard_patch_sizes[[1]]
#> # patch_size_tbl:      data.frame
#> # Species:             Blue-tongued Lizard
#> # Patches:             163
#> # Resolution:          2x2
#> # Interpatch Distance: 20 m
#>   patch_id   area
#>      <dbl>  <dbl>
#> 1        1 97878.
#> 2        2  2416.
#> 3        3  1304.
#> 4        4  1592.
#> 5        5     4 
#> # ℹ 158 more rows
```
