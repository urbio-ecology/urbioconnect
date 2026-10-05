# generate_connectivity_report() rejects anything else

    Code
      generate_connectivity_report(lizard_areas_connected)
    Condition
      Error in `generate_connectivity_report()`:
      ! `x` must be a <connectivity_report_data> object, not <patch_size_tbl/tbl_df/tbl/data.frame>.
      i Build one with `connectivity_report_data()`.
    Code
      generate_connectivity_report(test_report_data(), "report")
    Condition
      Error in `generate_connectivity_report()`:
      ! `path` needs a file extension, to say which format to write.
      x `path` is 'report'.
      i Try '.html' or '.pdf'.
    Code
      generate_connectivity_report(test_report_data(), c("a.html", "b.html"))
    Condition
      Error in `generate_connectivity_report()`:
      ! `path` must be a scalar (length 1), not length 2.
      i Did you mean to pass a single value?
    Code
      generate_connectivity_report(test_report_data(), "no/such/dir/report.html")
    Condition
      Error in `generate_connectivity_report()`:
      ! Can't write `path` to 'no/such/dir/report.html'.
      x The directory 'no/such/dir' doesn't exist.
      i Create it first, or give a path in a directory that exists.

# write_connectivity_report() writes a qmd beside its data

    Code
      sort(basename(list.files(dir)))
    Output
      [1] "wren-data.rds" "wren.qmd"     

# write_connectivity_report() rejects a path that isn't a qmd

    Code
      write_connectivity_report(test_report_data(), "report.html")
    Condition
      Error in `write_connectivity_report()`:
      ! `path` must end in '.qmd'.
      x `path` is 'report.html'.
      i This writes the report's source. To write a rendered report, see `generate_connectivity_report()`.
    Code
      write_connectivity_report(lizard_areas_connected, "report.qmd")
    Condition
      Error in `write_connectivity_report()`:
      ! `x` must be a <connectivity_report_data> object, not <patch_size_tbl/tbl_df/tbl/data.frame>.
      i Build one with `connectivity_report_data()`.

# render_connectivity_report() needs a file that exists

    Code
      render_connectivity_report("absent.qmd")
    Condition
      Error in `render_connectivity_report()`:
      ! `input` doesn't exist: 'absent.qmd'.
      i Write one with `write_connectivity_report()`.

# a format whose figures sit in a folder is refused, not mangled

    Code
      suppressMessages(generate_connectivity_report(test_report_data(40), file.path(
        dir, "report.md")))
    Condition
      Error in `render_report()`:
      ! Can't write a md report.
      x md keeps its figures in a separate folder, and a report has to be one file.
      i Use a self-contained format: '.html', '.pdf', '.docx' or '.rtf'.

