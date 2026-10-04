# generate_connectivity_report() rejects anything else

    Code
      generate_connectivity_report(lizard_areas_connected)
    Condition
      Error in `generate_connectivity_report()`:
      ! `x` must be a <connectivity_report_data> object, not <patch_size_tbl/tbl_df/tbl/data.frame>.
      i Build one with `connectivity_report_data()`.
    Code
      generate_connectivity_report(test_report_data(), output_format = "word")
    Condition
      Error in `generate_connectivity_report()`:
      ! `output_format` must be one of "html", "pdf", or "both", not "word".

