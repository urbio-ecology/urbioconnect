# connectivity_report_data() keeps a summary and layers per distance

    Code
      names(report_data)
    Output
       [1] "connectivity"              "habitat"                  
       [3] "barrier"                   "buffered_habitat"         
       [5] "patch_id_raster"           "species"                  
       [7] "interpatch_distance"       "directions"               
       [9] "settings"                  "run_time"                 
      [11] "scenario_kind"             "scenario_habitat"         
      [13] "scenario_barrier"          "scenario_buffered_habitat"
      [15] "comparison"               

# a scenario and its kind have to arrive together

    Code
      report_data(scenario = layers$barrier_scenario)
    Condition
      Error in `connectivity_report_data()`:
      ! `scenario_kind` must say which layer `scenario` replaces.
      i Either "habitat" or "barrier".
    Code
      report_data(scenario_kind = "barrier")
    Condition
      Error in `connectivity_report_data()`:
      ! `scenario_kind` needs a `scenario` to describe.
    Code
      report_data(scenario = layers$barrier_scenario, scenario_kind = "both")
    Condition
      Error in `connectivity_report_data()`:
      ! `scenario_kind` must be one of "habitat" or "barrier", not "both".

---

    Code
      invisible(report_data(scenario = layers$barrier, scenario_kind = "barrier"))
    Condition
      Warning:
      The scenario is identical to the baseline barrier.
      i Every change value will be zero.

# read_report_data() rejects an rds holding something else

    Code
      read_report_data(path)
    Condition
      Error in `read_report_data()`:
      ! 'not-report-data.rds' doesn't hold a <connectivity_report_data> object.
      x It holds a list.
      i Write one with `write_report_data()`.

# connectivity_report_data() checks its arguments

    Code
      connectivity_report_data(habitat = layers$habitat, barrier = layers$barrier,
      species = "Test Species", verbose = FALSE)
    Condition
      Error in `connectivity_report_data()`:
      ! `interpatch_distance` is absent but must be supplied.
    Code
      connectivity_report_data(habitat = layers$habitat, barrier = layers$barrier,
      species = c("one", "two"), interpatch_distance = 40, verbose = FALSE)
    Condition
      Error in `connectivity_report_data()`:
      ! `species` must be a scalar (length 1), not length 2.
      i Did you mean to pass a single value?

# connectivity_settings() records the run as one row per setting

    Code
      settings$setting
    Output
       [1] "species"               "interpatch_distance_m" "directions"           
       [4] "grid_resolution_m"     "grid_dimensions"       "crs"                  
       [7] "crs_code"              "scenario_kind"         "scenario_name"        
      [10] "run_time"              "urbioconnect_version"  "terra_version"        
      [13] "r_version"             "platform"             

# connectivity_settings() carries the caller's own settings

    Code
      settings$setting
    Output
       [1] "species"               "interpatch_distance_m" "directions"           
       [4] "habitat_source"        "data_resolution_m"     "grid_resolution_m"    
       [7] "grid_dimensions"       "crs"                   "crs_code"             
      [10] "scenario_kind"         "scenario_name"         "run_time"             
      [13] "urbioconnect_version"  "terra_version"         "r_version"            
      [16] "platform"             

# connectivity_settings() records real data's grid

    Code
      as.data.frame(dplyr::filter(connectivity_settings(report_data), !setting %in%
        volatile))
    Output
                      setting               value
      1               species  Blue Tongue Lizard
      2 interpatch_distance_m                 100
      3            directions     4 (rook's case)
      4     grid_resolution_m 10.01307 x 9.973856
      5       grid_dimensions           153 x 153
      6                   crs GDA94 / MGA zone 55
      7              crs_code          EPSG:28355
      8         scenario_kind                none
      9         scenario_name                <NA>

# connectivity_report_data() rejects settings it can't record

    Code
      test_report_data(settings = "no names")
    Condition
      Error in `connectivity_report_data()`:
      ! Every element of `settings` needs a name of its own.
      i The analysis records these itself: species, interpatch_distance_m, directions, grid_resolution_m, grid_dimensions, crs, crs_code, scenario_kind, scenario_name, run_time, urbioconnect_version, terra_version, r_version, and platform.
    Code
      test_report_data(settings = list(a = 1, 2))
    Condition
      Error in `connectivity_report_data()`:
      ! Every element of `settings` needs a name of its own.
      i The analysis records these itself: species, interpatch_distance_m, directions, grid_resolution_m, grid_dimensions, crs, crs_code, scenario_kind, scenario_name, run_time, urbioconnect_version, terra_version, r_version, and platform.
    Code
      test_report_data(settings = list(species = "mine"))
    Condition
      Error in `connectivity_report_data()`:
      ! Every element of `settings` needs a name of its own.
      i The analysis records these itself: species, interpatch_distance_m, directions, grid_resolution_m, grid_dimensions, crs, crs_code, scenario_kind, scenario_name, run_time, urbioconnect_version, terra_version, r_version, and platform.
    Code
      test_report_data(settings = rlang::set_names(list(1, 2), c("a", "a")))
    Condition
      Error in `connectivity_report_data()`:
      ! Every element of `settings` needs a name of its own.
      i The analysis records these itself: species, interpatch_distance_m, directions, grid_resolution_m, grid_dimensions, crs, crs_code, scenario_kind, scenario_name, run_time, urbioconnect_version, terra_version, r_version, and platform.

