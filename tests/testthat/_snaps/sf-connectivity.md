# sf_add_patch_area adds area column in square metres

    Code
      result
    Output
      Simple feature collection with 1 feature and 2 fields
      Geometry type: POLYGON
      Dimension:     XY
      Bounding box:  xmin: 0 ymin: 0 xmax: 100 ymax: 100
      Projected CRS: WGS 84 / UTM zone 54S
        patch_id                       geometry        area
      1        1 POLYGON ((0 0, 100 0, 100 1... 10000 [m^2]

# sf_aggregate_connected_patches groups by patch_id

    Code
      names(result)
    Output
      [1] "patch_id" "area"    

# sf_habitat_connectivity returns a data frame with expected columns

    Code
      names(result)
    Output
      [1] "patch_id" "area"    

