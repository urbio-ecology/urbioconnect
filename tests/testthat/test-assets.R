test_asset_bundle <- function(interpatch_distance = 40) {
  layers <- scenario_test_layers()

  connectivity_report_data(
    habitat = layers$habitat,
    barrier = layers$barrier,
    species = "Superb Fairy Wren",
    interpatch_distance = interpatch_distance,
    verbose = FALSE
  )
}

test_that("asset_manifest() lays out one folder per distance", {
  expect_snapshot(asset_manifest(test_asset_bundle(c(40, 80)))$path)
})

test_that("asset_manifest() only plots over distance when there are several", {
  one <- asset_manifest(test_asset_bundle(40))$path
  several <- asset_manifest(test_asset_bundle(c(40, 80)))$path

  expect_false("summary/connectivity-over-distance.png" %in% one)
  expect_true("summary/connectivity-over-distance.png" %in% several)
})

test_that("write_connectivity_assets() writes every file it promises", {
  bundle <- test_asset_bundle(c(40, 80))
  dir <- withr::local_tempdir()

  manifest <- write_connectivity_assets(bundle, dir)

  expect_true(all(file.exists(file.path(dir, manifest$path))))
  expect_true(all(file.size(file.path(dir, manifest$path)) > 0))
})

test_that("write_connectivity_assets() writes readable tables", {
  bundle <- test_asset_bundle(c(40, 80))
  dir <- withr::local_tempdir()
  write_connectivity_assets(bundle, dir)

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
  bundle <- test_asset_bundle(40)
  dir <- withr::local_tempdir()
  write_connectivity_assets(bundle, dir)

  gpkg <- terra::vect(file.path(dir, "interpatch-40m", "gis", "patches.gpkg"))
  shp <- terra::vect(file.path(dir, "interpatch-40m", "gis", "patches.shp"))

  expect_setequal(names(gpkg), c("patch_id", "area"))
  expect_setequal(names(shp), c("patch_id", "area"))
  expect_equal(nrow(gpkg), nrow(shp))

  # one polygon per patch in the summary
  expect_equal(nrow(gpkg), bundle$connectivity$n_patches)

  # the CRS survives the round-trip, which is what makes these usable in a GIS.
  # compared with same.crs(), since writing rewrites the WKT text
  expect_true(terra::same.crs(gpkg, bundle$habitat))
  expect_true(terra::same.crs(shp, bundle$habitat))
})

test_that("the README lists every file and describes the run", {
  bundle <- test_asset_bundle(c(40, 80))
  dir <- withr::local_tempdir()
  manifest <- write_connectivity_assets(bundle, dir)

  readme <- readLines(file.path(dir, "README.md"))

  purrr::walk(manifest$path, function(path) {
    expect_true(any(grepl(path, readme, fixed = TRUE)))
  })

  expect_true(any(grepl("Superb Fairy Wren", readme, fixed = TRUE)))
  expect_true(any(grepl("40m and 80m", readme, fixed = TRUE)))
  expect_true(any(grepl("square metres", readme, fixed = TRUE)))
})

test_that("zip_connectivity_assets() archives one named folder", {
  bundle <- test_asset_bundle(40)
  path <- withr::local_tempfile(fileext = ".zip")

  zip_connectivity_assets(bundle, path)

  contents <- zip::zip_list(path)$filename
  folder <- paste0("superb-fairy-wren-connectivity-", Sys.Date())

  expect_true(all(startsWith(contents, folder)))
  expect_true(paste0(folder, "/README.md") %in% contents)
  expect_true(
    paste0(folder, "/interpatch-40m/gis/patches.gpkg") %in% contents
  )
})

test_that("asset writing rejects anything but a bundle", {
  dir <- withr::local_tempdir()

  expect_snapshot(error = TRUE, {
    write_connectivity_assets(lizard_areas_connected, dir)
    zip_connectivity_assets("not a bundle", tempfile(fileext = ".zip"))
  })
})
