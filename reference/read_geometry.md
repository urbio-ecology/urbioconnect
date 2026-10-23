# Read shapefile geometry

Reads a shapefile and extracts only the spatial geometry, discarding
attribute data.

## Usage

``` r
read_geometry(shapefile)

# S3 method for class 'sf'
read_geometry(shapefile)

# Default S3 method
read_geometry(shapefile)
```

## Arguments

- shapefile:

  Character. File path to a shapefile, or an SF object.

## Value

An `sfc` object containing only the spatial geometry.

## Examples

``` r
# Read geometry from a file path
barrier_path <- system.file("ex/lizard_barrier.shp", package = "urbioconnect")
barrier_geom <- read_geometry(barrier_path)

# Can also pass an existing SF object
barrier_sf <- sf::st_read(barrier_path, quiet = TRUE)
barrier_geom <- read_geometry(barrier_sf)
```
