# Connected habitat patch areas for Blue-tongued Lizard

Pre-computed per-patch areas for the lizard example data at a 50 metre
interpatch distance. This is a `patch_size_tbl` – the per-patch table
carried inside the `connectivity` object returned by
[`habitat_connectivity()`](https://urbio-ecology.github.io/urbioconnect/reference/habitat_connectivity.md),
extracted with the
[`patch_sizes()`](https://urbio-ecology.github.io/urbioconnect/reference/patch_sizes.md)
accessor. Contains one row per connected habitat patch.

## Usage

``` r
lizard_areas_connected
```

## Format

A `patch_size_tbl` with columns:

- patch_id:

  Integer. Connected fragment ID.

- area:

  Numeric. Total area of the connected patch in square metres.

## Source

Generated from
[`example_habitat()`](https://urbio-ecology.github.io/urbioconnect/reference/example-lizard-data.md)
and
[`example_barrier()`](https://urbio-ecology.github.io/urbioconnect/reference/example-lizard-data.md)
at 50 metre interpatch distance.

## See also

[`habitat_connectivity()`](https://urbio-ecology.github.io/urbioconnect/reference/habitat_connectivity.md),
[`patch_sizes()`](https://urbio-ecology.github.io/urbioconnect/reference/patch_sizes.md),
[`summarise_connectivity()`](https://urbio-ecology.github.io/urbioconnect/reference/summarise-connectivity.md)

## Examples

``` r
# This was the code that was run to create this object. We don't run it
# as it takes some time to run
if (FALSE) { # \dontrun{
lizard_connectivity <- habitat_connectivity(
    habitat = example_habitat(),
    barrier = example_barrier(),
    species = "Blue-tongued Lizard",
    interpatch_distance = 50,
    verbose = FALSE
  )
lizard_areas_connected <- patch_sizes(lizard_connectivity)[[1]]
} # }
lizard_areas_connected
#> # patch_size_tbl:      data.frame
#> # Species:             Blue-tongued Lizard
#> # Patches:             73
#> # Resolution:          2x2
#> # Interpatch Distance: 50 m
#>   patch_id   area
#>      <dbl>  <dbl>
#> 1        1   172.
#> 2        2  1592.
#> 3        3 98006.
#> 4        4  2416.
#> 5        5  1304.
#> # ℹ 68 more rows
```
