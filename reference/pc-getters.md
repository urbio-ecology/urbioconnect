# Metadata from a `patch_size_tbl` object

Metadata from a `patch_size_tbl` object

## Usage

``` r
pc_species(x)

pc_patches(x)

pc_res(x)

pc_interpatch_distance(x)
```

## Arguments

- x:

  A
  [`patch_size_tbl()`](https://urbio-ecology.github.io/urbioconnect/reference/new_patch_size_tbl.md)
  object.

## Value

- `pc_species()` returns the species (character, length 1).

- `pc_interpatch_distance()` returns the interpatch distance (numeric,
  length 1).

- `pc_res()` returns the resolution (character, length 1 - e.g., "2x2").

- `pc_patches()` returns the number of patches - computed live from the
  number of rows (numeric, length 1).

## Examples

``` r
# the patch areas behind a lizard analysis
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

pc_species(lizard_areas_connected)
#> [1] "Blue-tongued Lizard"
pc_interpatch_distance(lizard_areas_connected)
#> [1] 50
pc_res(lizard_areas_connected)
#> [1] "2x2"
pc_patches(lizard_areas_connected)
#> [1] 73
```
