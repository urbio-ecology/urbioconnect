# connectivity_report_data() keeps a summary and layers per distance

    Code
      names(report_data)
    Output
       [1] "connectivity"              "habitat"                  
       [3] "barrier"                   "buffered_habitat"         
       [5] "patch_id_raster"           "species"                  
       [7] "interpatch_distance"       "settings"                 
       [9] "run_time"                  "scenario_kind"            
      [11] "scenario_habitat"          "scenario_barrier"         
      [13] "scenario_buffered_habitat" "comparison"               

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
       [1] "species"               "interpatch_distance_m" "grid_resolution_m"    
       [4] "grid_dimensions"       "crs"                   "crs_code"             
       [7] "scenario_kind"         "scenario_name"         "run_time"             
      [10] "urbioconnect_version"  "terra_version"         "r_version"            
      [13] "platform"             

# connectivity_settings() carries the caller's own settings

    Code
      connectivity_settings(report_data)$setting
    Output
       [1] "species"               "interpatch_distance_m" "habitat_source"       
       [4] "data_resolution_m"     "grid_resolution_m"     "grid_dimensions"      
       [7] "crs"                   "crs_code"              "scenario_kind"        
      [10] "scenario_name"         "run_time"              "urbioconnect_version" 
      [13] "terra_version"         "r_version"             "platform"             

# connectivity_report_data() rejects settings it can't record

    Code
      report_data(settings = "no names")
    Condition
      Error in `connectivity_report_data()`:
      ! `settings` must be a named list of single values.
      x You supplied a string.
      i One element per setting, for example `list(data_resolution_m = 10)`.
    Code
      report_data(settings = list(a = 1:2))
    Condition
      Error in `connectivity_report_data()`:
      ! `settings` must be a named list of single values.
      x You supplied a list.
      i One element per setting, for example `list(data_resolution_m = 10)`.
    Code
      report_data(settings = list(species = "mine"))
    Condition
      Error in `connectivity_report_data()`:
      ! `settings` can't name a setting the analysis derives itself.
      x species is derived.
      i Derived: species, interpatch_distance_m, grid_resolution_m, grid_dimensions, crs, crs_code, scenario_kind, scenario_name, run_time, urbioconnect_version, terra_version, r_version, and platform.
    Code
      report_data(settings = list(a = 1, a = 2))
    Condition
      Error in `connectivity_report_data()`:
      ! `settings` names a setting more than once.
      x a is repeated.

