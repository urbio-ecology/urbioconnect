# Summarise connectivity metrics

Calculates a comprehensive set of habitat connectivity metrics including
effective mesh size, probability of connectedness, and patch statistics.
There are two methods, the default, and one that dispatches on objects
of class, `patch_size_tbl`, created by
[`patch_size_tbl()`](https://urbio-ecology.github.io/urbioconnect/reference/new_patch_size_tbl.md),
which is used mostly internally inside of
[`habitat_connectivity()`](https://urbio-ecology.github.io/urbioconnect/reference/habitat_connectivity.md).
The default method requires "connectivity" to be a vector of areas, and
also requires scalar values (values of length 1) of interpatch distance,
resolution, and species. See examples below.

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

  data.frame of class "patch_size_tbl", obtained via
  [`patch_sizes()`](https://urbio-ecology.github.io/urbioconnect/reference/patch_sizes.md)
  from a `connectivity` object returned by
  [`habitat_connectivity()`](https://urbio-ecology.github.io/urbioconnect/reference/habitat_connectivity.md).
  Contains area measurements of connected patches.

- ...:

  extra arguments to pass through for default method.

- interpatch_distance:

  Numeric. The distance (in meters) where habitat patches are considered
  connected. E.g., if set to 500, patches 498m apart are connected,
  those 501m apart are not connected. This is passed internally to a
  spatial operation known as "buffering", where this distance is used as
  a radius from the edge of the habitat zone. This means the specified
  `interpatch_distance` is halved exactly. So an interpatch distance of
  500 will be converted to 250.

- data_resolution:

  Numeric. Data resolution in meters.

- species:

  Character. Name of species analysed.

## Value

A tibble with connectivity metrics including number of patches,
probability of connectedness, effective mesh size, mean and total patch
areas.

## Examples

``` r
# dispatch on `patch_size_tbl` class - `lizard_areas_connected`
summarise_connectivity(
  connectivity = lizard_areas_connected
)
#> # A tibble: 1 × 9
#>   species     interpatch_distance n_patches effective_mesh_ha prob_connectedness
#>   <chr>                     <dbl>     <int>             <dbl>              <dbl>
#> 1 Blue-tongu…                  50        73              4.47          0.0000170
#> # ℹ 4 more variables: patch_area_mean <dbl>, patch_area_total_ha <dbl>,
#> #   data_resolution <chr>, patch_size <list>

# default method
# manually passing area, interpatch distance, resolution, and species
summarise_connectivity(
  connectivity = lizard_areas_connected$area,
  interpatch_distance = 10,
  data_resolution = 10,
  species = "Blue-tongued Lizard"
)
#> # A tibble: 1 × 9
#>   species     interpatch_distance n_patches effective_mesh_ha prob_connectedness
#>   <chr>                     <dbl>     <int>             <dbl>              <dbl>
#> 1 Blue-tongu…                  10        73              4.47          0.0000170
#> # ℹ 4 more variables: patch_area_mean <dbl>, patch_area_total_ha <dbl>,
#> #   data_resolution <dbl>, patch_size <list>
```
