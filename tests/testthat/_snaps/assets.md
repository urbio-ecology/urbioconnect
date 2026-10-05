# asset_manifest() lays out one folder per distance

    Code
      asset_manifest(test_report_data(c(40, 80)))$path
    Output
       [1] "README.md"                                     
       [2] "summary/connectivity-summary.csv"              
       [3] "summary/patch-areas.csv"                       
       [4] "summary/connectivity-over-distance.png"        
       [5] "interpatch-40m/maps/habitat-buffer-barrier.png"
       [6] "interpatch-40m/maps/patches.png"               
       [7] "interpatch-40m/gis/patches.tif"                
       [8] "interpatch-40m/gis/patches.gpkg"               
       [9] "interpatch-40m/gis/patches.shp"                
      [10] "interpatch-80m/maps/habitat-buffer-barrier.png"
      [11] "interpatch-80m/maps/patches.png"               
      [12] "interpatch-80m/gis/patches.tif"                
      [13] "interpatch-80m/gis/patches.gpkg"               
      [14] "interpatch-80m/gis/patches.shp"                

# connectivity_file_stem() slugs the species and dates it

    Code
      connectivity_file_stem(lizard_areas_connected)
    Condition
      Error in `connectivity_file_stem()`:
      ! `x` must be a <connectivity_report_data> object, not <patch_size_tbl/tbl_df/tbl/data.frame>.
      i Build one with `connectivity_report_data()`.

# asset writing rejects a reports argument that isn't TRUE or FALSE

    Code
      write_connectivity_assets(report_data, dir, reports = 1)
    Condition
      Error in `write_connectivity_assets()`:
      ! `reports` must be `TRUE` or `FALSE`, not a number.
      x You supplied 1.
    Code
      write_connectivity_assets(report_data, dir, reports = NA)
    Condition
      Error in `write_connectivity_assets()`:
      ! `reports` must be `TRUE` or `FALSE`, not `NA`.
      x You supplied NA.
    Code
      write_connectivity_assets(report_data, dir, reports = c(TRUE, TRUE))
    Condition
      Error in `write_connectivity_assets()`:
      ! `reports` must be `TRUE` or `FALSE`, not a logical vector.
      x You supplied TRUE and TRUE.
    Code
      write_connectivity_assets(report_data, dir, reports = "yes")
    Condition
      Error in `write_connectivity_assets()`:
      ! `reports` must be `TRUE` or `FALSE`, not a string.
      x You supplied "yes".

# write_connectivity_assets() checks for Quarto before writing

    Code
      write_connectivity_assets(test_report_data(40), dir, reports = TRUE)
    Condition
      Error in `write_connectivity_assets()`:
      ! Can't find the Quarto command line tool.
      i Install it from <https://quarto.org/docs/get-started/>.
      i The assets alone need no Quarto: see `write_connectivity_assets()`.

# the manifest lists the reports only when asked

    Code
      asset_manifest(report_data, reports = TRUE)$path
    Output
       [1] "report.html"                                   
       [2] "report.pdf"                                    
       [3] "README.md"                                     
       [4] "summary/connectivity-summary.csv"              
       [5] "summary/patch-areas.csv"                       
       [6] "interpatch-40m/maps/habitat-buffer-barrier.png"
       [7] "interpatch-40m/maps/patches.png"               
       [8] "interpatch-40m/gis/patches.tif"                
       [9] "interpatch-40m/gis/patches.gpkg"               
      [10] "interpatch-40m/gis/patches.shp"                

# write_connectivity_assets() skips the reports without Quarto

    Code
      manifest <- write_connectivity_assets(report_data, dir)
    Message
      No reports: can't find the Quarto command line tool.
      i Everything else is written. Install Quarto from <https://quarto.org/docs/get-started/> for the reports.

# write_connectivity_assets() writes readable tables

    Code
      names(summary_csv)
    Output
      [1] "species"             "interpatch_distance" "n_patches"          
      [4] "effective_mesh_ha"   "prob_connectedness"  "patch_area_mean"    
      [7] "patch_area_total_ha" "data_resolution"    

# asset writing rejects anything but a connectivity_report_data

    Code
      write_connectivity_assets(lizard_areas_connected, dir)
    Condition
      Error in `write_connectivity_assets()`:
      ! `x` must be a <connectivity_report_data> object, not <patch_size_tbl/tbl_df/tbl/data.frame>.
      i Build one with `connectivity_report_data()`.
    Code
      zip_connectivity_assets("not report data", tempfile(fileext = ".zip"))
    Condition
      Error in `zip_connectivity_assets()`:
      ! `x` must be a <connectivity_report_data> object, not <character>.
      i Build one with `connectivity_report_data()`.
    Code
      zip_connectivity_assets(test_report_data(40), "no/such/dir/out.zip")
    Condition
      Error in `zip_connectivity_assets()`:
      ! Can't write `path` to 'no/such/dir/out.zip'.
      x The directory 'no/such/dir' doesn't exist.
      i Create it first, or give a path in a directory that exists.

