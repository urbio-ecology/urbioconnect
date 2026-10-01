# asset_manifest() lays out one folder per distance

    Code
      asset_manifest(test_asset_bundle(c(40, 80)))$path
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

# write_connectivity_assets() writes readable tables

    Code
      names(summary_csv)
    Output
      [1] "species"             "interpatch_distance" "n_patches"          
      [4] "effective_mesh_ha"   "prob_connectedness"  "patch_area_mean"    
      [7] "patch_area_total_ha" "data_resolution"    

# asset writing rejects anything but a bundle

    Code
      write_connectivity_assets(lizard_areas_connected, dir)
    Condition
      Error in `write_connectivity_assets()`:
      ! `x` must be a <connectivity_report_data> object, not <patch_size_tbl/tbl_df/tbl/data.frame>.
      i Build one with `connectivity_report_data()`.
    Code
      zip_connectivity_assets("not a bundle", tempfile(fileext = ".zip"))
    Condition
      Error in `zip_connectivity_assets()`:
      ! `x` must be a <connectivity_report_data> object, not <character>.
      i Build one with `connectivity_report_data()`.

