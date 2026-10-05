test_that("asset_manifest() lays out one folder per distance", {
  expect_snapshot(asset_manifest(test_report_data(c(40, 80)))$path)
})

test_that("asset_manifest() only plots over distance when there are several", {
  one <- asset_manifest(test_report_data(40))$path
  several <- asset_manifest(test_report_data(c(40, 80)))$path

  expect_false("summary/connectivity-over-distance.png" %in% one)
  expect_true("summary/connectivity-over-distance.png" %in% several)
})

test_that("connectivity_file_stem() slugs the species and dates it", {
  report_data <- test_report_data(40)

  expect_equal(
    connectivity_file_stem(report_data),
    paste0("superb-fairy-wren-connectivity-", Sys.Date())
  )
  expect_snapshot(connectivity_file_stem(lizard_areas_connected), error = TRUE)
})

test_that("asset writing rejects a reports argument that isn't TRUE or FALSE", {
  report_data <- test_report_data(40)
  dir <- withr::local_tempdir()

  expect_snapshot(error = TRUE, {
    write_connectivity_assets(report_data, dir, reports = 1)
    write_connectivity_assets(report_data, dir, reports = NA)
    write_connectivity_assets(report_data, dir, reports = c(TRUE, TRUE))
    write_connectivity_assets(report_data, dir, reports = "yes")
  })
})

test_that("write_connectivity_assets() checks for Quarto before writing", {
  local_mocked_bindings(quarto_available = function() FALSE)

  dir <- withr::local_tempdir()

  # rendering happens last, so aborting then would leave a folder of files
  # with no README
  expect_snapshot(
    write_connectivity_assets(test_report_data(40), dir, reports = TRUE),
    error = TRUE
  )
  expect_equal(length(list.files(dir)), 0)
})

test_that("the manifest lists the reports only when asked", {
  report_data <- test_report_data(40)

  expect_false(
    any(startsWith(asset_manifest(report_data)$path, "report."))
  )
  expect_snapshot(asset_manifest(report_data, reports = TRUE)$path)
})

test_that("write_connectivity_assets() skips the reports without Quarto", {
  local_mocked_bindings(quarto_available = function() FALSE)

  report_data <- test_report_data(40)
  dir <- withr::local_tempdir()

  # the maps, tables and GIS layers are still written: a missing Quarto costs
  # the reports, not the download
  expect_snapshot(manifest <- write_connectivity_assets(report_data, dir))

  expect_true(all(file.exists(file.path(dir, manifest$path))))
  expect_false(any(startsWith(manifest$path, "report.")))
  expect_equal(length(list.files(dir, pattern = "^report[.]")), 0)
})

test_that("write_connectivity_assets() writes every file it promises", {
  report_data <- test_report_data(c(40, 80))
  dir <- withr::local_tempdir()

  manifest <- write_connectivity_assets(report_data, dir, reports = FALSE)

  expect_true(all(file.exists(file.path(dir, manifest$path))))
  expect_true(all(file.size(file.path(dir, manifest$path)) > 0))
})

test_that("write_connectivity_assets() writes readable tables", {
  report_data <- test_report_data(c(40, 80))
  dir <- withr::local_tempdir()
  write_connectivity_assets(report_data, dir, reports = FALSE)

  summary_csv <- readr::read_csv(
    file.path(dir, "summary", "connectivity-summary.csv"),
    show_col_types = FALSE
  )
  patches_csv <- readr::read_csv(
    file.path(dir, "summary", "patch-areas.csv"),
    show_col_types = FALSE
  )

  expect_equal(nrow(summary_csv), 2)
  expect_false("patch_size" %in% names(summary_csv))
  expect_snapshot(names(summary_csv))

  expect_setequal(unique(patches_csv$interpatch_distance), c(40, 80))
  expect_true(all(c("patch_id", "area") %in% names(patches_csv)))
})

test_that("patch polygons carry patch_id and area, in both formats", {
  report_data <- test_report_data(40)
  dir <- withr::local_tempdir()
  write_connectivity_assets(report_data, dir, reports = FALSE)

  gpkg <- terra::vect(file.path(dir, "interpatch-40m", "gis", "patches.gpkg"))
  shp <- terra::vect(file.path(dir, "interpatch-40m", "gis", "patches.shp"))

  expect_setequal(names(gpkg), c("patch_id", "area"))
  expect_setequal(names(shp), c("patch_id", "area"))
  expect_equal(nrow(gpkg), nrow(shp))

  # one polygon per patch in the summary
  expect_equal(nrow(gpkg), report_data$connectivity$n_patches)

  # same.crs(), not equality: writing rewrites the WKT text
  expect_true(terra::same.crs(gpkg, report_data$habitat))
  expect_true(terra::same.crs(shp, report_data$habitat))
})

test_that("the README lists every file and describes the run", {
  report_data <- test_report_data(c(40, 80))
  dir <- withr::local_tempdir()
  manifest <- write_connectivity_assets(report_data, dir, reports = FALSE)

  readme <- readLines(file.path(dir, "README.md"))

  purrr::walk(manifest$path, function(path) {
    expect_true(any(grepl(path, readme, fixed = TRUE)))
  })

  expect_true(any(grepl("Superb Fairy Wren", readme, fixed = TRUE)))
  expect_true(any(grepl("40m and 80m", readme, fixed = TRUE)))
  expect_true(any(grepl("square metres", readme, fixed = TRUE)))
})

test_that("zip_connectivity_assets() archives one named folder", {
  report_data <- test_report_data(40)
  path <- withr::local_tempfile(fileext = ".zip")

  zip_connectivity_assets(report_data, path, reports = FALSE)

  contents <- zip::zip_list(path)$filename
  folder <- connectivity_file_stem(report_data)

  expect_true(all(startsWith(contents, folder)))
  expect_true(paste0(folder, "/README.md") %in% contents)
  expect_true(
    paste0(folder, "/interpatch-40m/gis/patches.gpkg") %in% contents
  )
})

test_that("zip_connectivity_assets() takes a relative path", {
  report_data <- test_report_data(40)

  withr::with_tempdir({
    dir.create("out")
    path <- zip_connectivity_assets(
      report_data,
      "out/wren.zip",
      reports = FALSE
    )

    expect_equal(basename(path), "wren.zip")
    expect_equal(path, normalizePath(path, winslash = "/"))
    expect_true(file.exists("out/wren.zip"))
  })
})

test_that("zip_connectivity_reports() archives both reports", {
  skip_if_no_quarto()

  report_data <- test_report_data(40)
  path <- withr::local_tempfile(fileext = ".zip")

  suppressMessages(zip_connectivity_reports(report_data, path))

  contents <- zip::zip_list(path)
  folder <- connectivity_file_stem(report_data)

  # the archive carries the folder itself as an entry, so compare the files
  files <- contents[!endsWith(contents$filename, "/"), ]

  expect_setequal(
    files$filename,
    paste0(folder, "/", c("report.html", "report.pdf"))
  )
  expect_true(all(files$uncompressed_size > 0))
})

test_that("asset writing rejects anything but a connectivity_report_data", {
  dir <- withr::local_tempdir()

  expect_snapshot(error = TRUE, {
    write_connectivity_assets(lizard_areas_connected, dir)
    zip_connectivity_assets("not report data", tempfile(fileext = ".zip"))
    zip_connectivity_assets(test_report_data(40), "no/such/dir/out.zip")
  })
})
