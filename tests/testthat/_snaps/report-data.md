# connectivity_report_data() keeps a summary and layers per distance

    Code
      names(report_data)
    Output
       [1] "connectivity"              "habitat"                  
       [3] "barrier"                   "buffered_habitat"         
       [5] "patch_id_raster"           "species"                  
       [7] "interpatch_distance"       "scenario_kind"            
       [9] "scenario_habitat"          "scenario_barrier"         
      [11] "scenario_buffered_habitat" "comparison"               

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
      report_data(scenario = layers$barrier, scenario_kind = "barrier")
    Condition
      Warning:
      The scenario is identical to the baseline barrier.
      i Every change value will be zero.
    Output
      $connectivity
      # A tibble: 1 x 9
        species     interpatch_distance n_patches effective_mesh_ha prob_connectedness
        <chr>                     <dbl>     <int>             <dbl>              <dbl>
      1 Test Speci~                  40         3             0.915          0.0000367
      # i 4 more variables: patch_area_mean <dbl>, patch_area_total_ha <dbl>,
      #   data_resolution <chr>, patch_size <list>
      
      $habitat
      class       : SpatRaster
      size        : 40, 40, 1  (nrow, ncol, nlyr)
      resolution  : 10, 10  (x, y)
      extent      : 0, 400, 0, 400  (xmin, xmax, ymin, ymax)
      coord. ref. : WGS 84 / UTM zone 54S (EPSG:32754)
      source(s)   : memory
      name        : lyr.1
      min value   :     1
      max value   :     1
      
      $barrier
      class       : SpatRaster
      size        : 40, 40, 1  (nrow, ncol, nlyr)
      resolution  : 10, 10  (x, y)
      extent      : 0, 400, 0, 400  (xmin, xmax, ymin, ymax)
      coord. ref. : WGS 84 / UTM zone 54S (EPSG:32754)
      source(s)   : memory
      name        : lyr.1
      min value   :     1
      max value   :     1
      
      $buffered_habitat
      $buffered_habitat$`40`
      class       : SpatRaster
      size        : 40, 40, 1  (nrow, ncol, nlyr)
      resolution  : 10, 10  (x, y)
      extent      : 0, 400, 0, 400  (xmin, xmax, ymin, ymax)
      coord. ref. : WGS 84 / UTM zone 54S (EPSG:32754)
      source(s)   : memory
      name        : focal_max
      min value   :         1
      max value   :         1
      
      
      $patch_id_raster
      $patch_id_raster$`40`
      class       : SpatRaster
      size        : 40, 40, 2  (nrow, ncol, nlyr)
      resolution  : 10, 10  (x, y)
      extent      : 0, 400, 0, 400  (xmin, xmax, ymin, ymax)
      coord. ref. : WGS 84 / UTM zone 54S (EPSG:32754)
      source(s)   : memory
      names       : patch_id,      area
      min values  :        1, 99.471135
      max values  :        3, 99.472081
      
      
      $species
      [1] "Test Species"
      
      $interpatch_distance
      [1] 40
      
      $scenario_kind
      [1] "barrier"
      
      $scenario_habitat
      class       : SpatRaster
      size        : 40, 40, 1  (nrow, ncol, nlyr)
      resolution  : 10, 10  (x, y)
      extent      : 0, 400, 0, 400  (xmin, xmax, ymin, ymax)
      coord. ref. : WGS 84 / UTM zone 54S (EPSG:32754)
      source(s)   : memory
      name        : lyr.1
      min value   :     1
      max value   :     1
      
      $scenario_barrier
      class       : SpatRaster
      size        : 40, 40, 1  (nrow, ncol, nlyr)
      resolution  : 10, 10  (x, y)
      extent      : 0, 400, 0, 400  (xmin, xmax, ymin, ymax)
      coord. ref. : WGS 84 / UTM zone 54S (EPSG:32754)
      source(s)   : memory
      name        : lyr.1
      min value   :     1
      max value   :     1
      
      $scenario_buffered_habitat
      $scenario_buffered_habitat$`40`
      class       : SpatRaster
      size        : 40, 40, 1  (nrow, ncol, nlyr)
      resolution  : 10, 10  (x, y)
      extent      : 0, 400, 0, 400  (xmin, xmax, ymin, ymax)
      coord. ref. : WGS 84 / UTM zone 54S (EPSG:32754)
      source(s)   : memory
      name        : focal_max
      min value   :         1
      max value   :         1
      
      
      $comparison
      # Connectivity comparison: baseline / scenario / change / pct_change
      # A tibble: 4 x 10
        scenario_name measure    species      interpatch_distance n_patches
        <chr>         <chr>      <chr>                      <dbl>     <dbl>
      1 <NA>          baseline   Test Species                  40         3
      2 <NA>          scenario   Test Species                  40         3
      3 <NA>          change     Test Species                  40         0
      4 <NA>          pct_change Test Species                  40         0
        effective_mesh_ha prob_connectedness patch_area_mean patch_area_total_ha
                    <dbl>              <dbl>           <dbl>               <dbl>
      1             0.915          0.0000367           8322.                2.50
      2             0.915          0.0000367           8322.                2.50
      3             0              0                      0                 0   
      4             0              0                      0                 0   
        data_resolution
        <chr>          
      1 10x10          
      2 10x10          
      3 10x10          
      4 10x10          
      # change = scenario - baseline (positive = scenario is higher)
      # pct_change = 100 * change / baseline
      
      attr(,"class")
      [1] "connectivity_report_data"

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

