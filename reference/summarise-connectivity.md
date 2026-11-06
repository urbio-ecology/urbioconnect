# Summarise connectivity metrics

Calculates habitat connectivity metrics including effective mesh size,
probability of connectedness, and patch statistics.
[`habitat_connectivity()`](https://urbio-ecology.github.io/urbioconnect/reference/habitat_connectivity.md)
runs the analysis and calls this for you, so you only need it to
summarise patch areas you already have.

## Usage

``` r
summarise_connectivity(connectivity, ...)

# Default S3 method
summarise_connectivity(
  connectivity,
  interpatch_distance,
  data_resolution,
  species,
  ...
)
```

## Arguments

- connectivity:

  A `patch_size_tbl`, such as an element of
  [`patch_sizes()`](https://urbio-ecology.github.io/urbioconnect/reference/patch_sizes.md)
  (`patch_sizes(x)[[1]]`) or the result of
  [`sf_habitat_connectivity()`](https://urbio-ecology.github.io/urbioconnect/reference/sf_habitat_connectivity.md),
  whose resolution is `"NA"` as it has no cells. Or a numeric vector of
  connected patch areas, in square metres.

- ...:

  extra arguments to pass through for default method.

- interpatch_distance:

  Numeric. The interpatch distance, in metres, the areas were found
  with. It is recorded in the summary, not used to calculate it.

- data_resolution:

  Numeric. The cell size, in metres, the areas were found at. Recorded
  in the summary, like `interpatch_distance`.

- species:

  Character. Name of species analysed.

## Value

A tibble with connectivity metrics including number of patches,
probability of connectedness, effective mesh size, mean and total patch
areas.

## Details

A `patch_size_tbl` carries its own species, interpatch distance and
resolution. For a vector of patch areas, give those three yourself, each
a single value.

## Examples

``` r
# a `patch_size_tbl` carries its species, interpatch distance and resolution
summarise_connectivity(lizard_areas_connected)
#> # A tibble: 1 × 9
#>   species     interpatch_distance n_patches effective_mesh_ha prob_connectedness
#>   <chr>                     <dbl>     <int>             <dbl>              <dbl>
#> 1 Blue-tongu…                  50        73              4.47              0.170
#> # ℹ 4 more variables: patch_area_mean <dbl>, patch_area_total_ha <dbl>,
#> #   data_resolution <chr>, patch_size <list>

# a vector of areas does not: these were found at an interpatch distance of
# 50 m on the lizard's 2 m cells
summarise_connectivity(
  connectivity = lizard_areas_connected$area,
  interpatch_distance = 50,
  data_resolution = 2,
  species = "Blue-tongued Lizard"
)
#> # A tibble: 1 × 9
#>   species     interpatch_distance n_patches effective_mesh_ha prob_connectedness
#>   <chr>                     <dbl>     <int>             <dbl>              <dbl>
#> 1 Blue-tongu…                  50        73              4.47              0.170
#> # ℹ 4 more variables: patch_area_mean <dbl>, patch_area_total_ha <dbl>,
#> #   data_resolution <dbl>, patch_size <list>
```
