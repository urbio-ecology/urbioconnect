#' Write the downloadable assets for one analysis
#'
#' Writes every map, table and GIS layer a planner needs into `dir`, laid out
#'   in folders by interpatch distance, with a README explaining each file.
#'   [zip_connectivity_assets()] wraps this into a single archive, which is
#'   what the Shiny app's download button uses.
#'
#' @param x A `connectivity_report_data` object from
#'   [connectivity_report_data()].
#' @param dir Directory to write into. Created if it doesn't exist.
#' @param reports Also render the HTML and PDF reports into `dir`. Defaults to
#'   whether the Quarto command line tool is installed, since it is the one
#'   thing here that needs it: without Quarto the maps, tables and GIS layers
#'   are still written, and a message says the reports were skipped. Costs
#'   about 15 seconds per format.
#'
#' @returns The manifest, invisibly: a tibble of `path`, `kind` and
#'   `description`, one row per file written, with paths relative to `dir`.
#' @seealso [connectivity_report_data()], [zip_connectivity_assets()], and
#'   [generate_connectivity_report()] for one report on its own.
#' @export
#'
#' @examples
#' \donttest{
#' report_data <- connectivity_report_data(
#'   habitat = example_habitat(),
#'   barrier = example_barrier(),
#'   species = "Blue Tongue Lizard",
#'   interpatch_distance = 20,
#'   verbose = FALSE
#' )
#'
#' assets <- write_connectivity_assets(
#'   report_data,
#'   dir = tempfile(),
#'   reports = FALSE
#' )
#' assets$path
#' }
write_connectivity_assets <- function(x, dir, reports = quarto_available()) {
  check_report_data(x)
  check_bool(reports)

  # said no, or the default decided for you? Only the second is worth a word,
  # and only Quarto's absence can make the default choose FALSE.
  if (!reports && missing(reports)) {
    cli::cli_inform(c(
      "No reports: can't find the Quarto command line tool.",
      "i" = "Everything else is written. Install Quarto from
             {.url https://quarto.org/docs/get-started/} for the reports."
    ))
  }

  # checked before a single file is written: rendering happens last, and
  # aborting then would leave a half-built folder with no README
  if (reports) {
    check_quarto()
  }

  manifest <- asset_manifest(x, reports = reports)

  # every directory the manifest mentions, made once
  purrr::walk(
    unique(dirname(file.path(dir, manifest$path))),
    dir.create,
    recursive = TRUE,
    showWarnings = FALSE
  )

  write_asset_tables(x, dir)
  write_asset_plots(x, dir)
  write_asset_gis(x, dir)

  if (reports) {
    render_asset_reports(x, dir)
  }

  # last, so it lists what was written
  write_asset_readme(x, manifest, dir)

  invisible(manifest)
}

#' Write the downloadable assets as a single zip
#'
#' [write_connectivity_assets()] into a folder named for the species and the
#'   date, archived. This is what the Shiny app's download button returns.
#'
#' @param x A `connectivity_report_data` object from
#'   [connectivity_report_data()].
#' @param path Path to write the `.zip` to.
#' @param reports Also render the reports into the archive. See
#'   [write_connectivity_assets()].
#'
#' @returns The absolute path written, invisibly.
#' @seealso [write_connectivity_assets()] to write the files without
#'   archiving, and [zip_connectivity_reports()] for the reports alone.
#' @export
#'
#' @examples
#' \donttest{
#' report_data <- connectivity_report_data(
#'   habitat = example_habitat(),
#'   barrier = example_barrier(),
#'   species = "Blue Tongue Lizard",
#'   interpatch_distance = 20,
#'   verbose = FALSE
#' )
#'
#' zip_path <- zip_connectivity_assets(
#'   report_data,
#'   tempfile(fileext = ".zip"),
#'   reports = FALSE
#' )
#' zip::zip_list(zip_path)$filename
#' }
zip_connectivity_assets <- function(x, path, reports = quarto_available()) {
  check_report_data(x)
  check_bool(reports)

  if (reports) {
    check_quarto()
  }

  zip_asset_folder(x, path, write_connectivity_assets, reports = reports)
}

#' Write the reports as a single zip
#'
#' The HTML and PDF reports, in a folder named for the species and the date,
#'   archived. This is the app's reports-only download, for someone who wants
#'   the write-up without the GIS layers. The analysis is packed once and
#'   rendered twice, so this costs less than two separate calls.
#'
#' @param x A `connectivity_report_data` object from
#'   [connectivity_report_data()].
#' @param path Path to write the `.zip` to.
#'
#' @returns The absolute path written, invisibly.
#' @seealso [zip_connectivity_assets()] for everything, and
#'   [generate_connectivity_report()] for one report on its own.
#' @export
#'
#' @examples
#' \donttest{
#' report_data <- connectivity_report_data(
#'   habitat = example_habitat(),
#'   barrier = example_barrier(),
#'   species = "Blue Tongue Lizard",
#'   interpatch_distance = 20,
#'   verbose = FALSE
#' )
#'
#' # rendering needs the Quarto command line tool
#' if (quarto_available()) {
#'   zip_path <- zip_connectivity_reports(
#'     report_data,
#'     tempfile(fileext = ".zip")
#'   )
#'   zip::zip_list(zip_path)$filename
#' }
#' }
zip_connectivity_reports <- function(x, path) {
  check_report_data(x)
  check_quarto()

  zip_asset_folder(x, path, render_asset_reports)
}

#' Archive what `write_fn` puts in one folder named for the species and date
#'
#' @noRd
zip_asset_folder <- function(x, path, write_fn, ...) {
  # `zip::zip()` resolves `zipfile` against `root`, so a relative path would
  # be written into the staging directory and lost with it. Resolved here,
  # before anything is written, so a bad path fails in a moment.
  path <- absolute_path(path, arg = "path", call = rlang::caller_env())

  # staged so the archive holds one named folder, not a scatter of files
  staging <- tempfile("urbioconnect-zip")
  on.exit(unlink(staging, recursive = TRUE), add = TRUE)

  folder <- connectivity_file_stem(x)
  dir.create(file.path(staging, folder), recursive = TRUE)

  write_fn(x, file.path(staging, folder), ...)

  zip::zip(zipfile = path, files = folder, root = staging)

  invisible(path)
}

#' Make a path to a not-yet-existing file absolute
#'
#' `normalizePath()` leaves a path alone when the file isn't there yet, so the
#' directory is normalised and the file name put back on.
#'
#' @noRd
absolute_path <- function(
  path,
  arg = rlang::caller_arg(path),
  call = rlang::caller_env()
) {
  dir <- dirname(path)

  if (!dir.exists(dir)) {
    cli::cli_abort(
      c(
        "Can't write {.arg {arg}} to {.path {path}}.",
        "x" = "The directory {.path {dir}} doesn't exist.",
        "i" = "Create it first, or give a path in a directory that exists."
      ),
      call = call
    )
  }

  file.path(normalizePath(dir, winslash = "/"), basename(path))
}

#' The name to give a download: species and date
#'
#' The stem every download takes its name from, so a report, a zip and the
#'   folder inside that zip agree. The species is lower-cased with its spaces
#'   turned into dashes, which keeps it usable as a file name.
#'
#' @param x A `connectivity_report_data` object from
#'   [connectivity_report_data()].
#'
#' @returns A string, with no extension.
#' @seealso [generate_connectivity_report()] and
#'   [write_connectivity_report()], whose `path` defaults to this, and
#'   [zip_connectivity_assets()], which names the folder inside the archive
#'   with it.
#' @export
#'
#' @examples
#' \donttest{
#' report_data <- connectivity_report_data(
#'   habitat = example_habitat(),
#'   barrier = example_barrier(),
#'   species = "Blue Tongue Lizard",
#'   interpatch_distance = 20,
#'   verbose = FALSE
#' )
#'
#' connectivity_file_stem(report_data)
#' }
connectivity_file_stem <- function(x) {
  check_report_data(x)
  as.character(glue::glue("{slugify(x$species)}-connectivity-{Sys.Date()}"))
}

#' Make a string safe for a file path
#'
#' Lower case, non-alphanumerics collapsed to single dashes, no leading or
#' trailing dash. "Superb Fairy Wren" becomes "superb-fairy-wren".
#'
#' @noRd
slugify <- function(x) {
  x |>
    stringr::str_to_lower() |>
    stringr::str_replace_all("[^a-z0-9]+", "-") |>
    stringr::str_remove_all("^-|-$")
}

#' What the download contains
#'
#' The single source of truth for the layout: the writer uses it to know where
#' files go, and the README lists it, so the two can't drift.
#'
#' @noRd
asset_manifest <- function(x, reports = FALSE) {
  distances <- x$interpatch_distance

  report_rows <- tibble::tibble(
    path = paste0("report.", report_extensions()),
    kind = "report",
    description = c(
      "The whole analysis as one self-contained web page.",
      "The whole analysis as one PDF."
    )
  )

  shared <- tibble::tibble(
    path = c(
      "README.md",
      "summary/connectivity-summary.csv",
      "summary/patch-areas.csv"
    ),
    kind = c("readme", "table", "table"),
    description = c(
      "This file: what the analysis was, and what each file holds.",
      "Landscape metrics, one row per interpatch distance.",
      "Every habitat patch, with its area and interpatch distance."
    )
  )

  over_distance <- tibble::tibble(
    path = "summary/connectivity-over-distance.png",
    kind = "plot",
    description = "How the metrics change across interpatch distances."
  )

  per_distance <- purrr::map(distances, distance_manifest) |>
    purrr::list_rbind()

  dplyr::bind_rows(
    if (reports) report_rows,
    shared,
    if (has_over_distance_plot(x)) over_distance,
    per_distance
  )
}

#' The report formats the download and the app offer
#'
#' @noRd
report_extensions <- function() {
  c("html", "pdf")
}

#' Render the reports into an asset folder
#'
#' One source in one staging directory, rendered once per format. Quarto
#' re-runs the document per format whatever we do, so this saves the packing
#' rather than a render: measured at 1.6s of a 28s two-format run on real
#' data, so the gain is tidiness more than speed.
#'
#' @noRd
render_asset_reports <- function(x, dir) {
  staging <- tempfile("urbioconnect-report")
  on.exit(unlink(staging, recursive = TRUE), add = TRUE)

  qmd <- stage_report_qmd(x, staging)

  purrr::walk(report_extensions(), function(extension) {
    render_connectivity_report(
      qmd,
      file.path(dir, paste0("report.", extension))
    )
  })
}

#' @noRd
distance_manifest <- function(distance) {
  folder <- glue::glue("interpatch-{distance}m")

  tibble::tibble(
    path = as.character(glue::glue(
      "{folder}/{file}",
      file = c(
        "maps/habitat-buffer-barrier.png",
        "maps/patches.png",
        "gis/patches.tif",
        "gis/patches.gpkg",
        "gis/patches.shp"
      )
    )),
    kind = c("map", "map", "raster", "vector", "vector"),
    description = as.character(glue::glue(
      "{what} at an interpatch distance of {distance}m.",
      what = c(
        "Habitat, interpatch zone and barrier",
        "Habitat coloured by connected patch",
        "Patch ID and patch area raster (GeoTIFF)",
        "Patch polygons (GeoPackage)",
        "Patch polygons (shapefile, with its .shx, .dbf and .prj)"
      )
    ))
  )
}

#' @noRd
write_asset_tables <- function(x, dir) {
  x$connectivity |>
    dplyr::select(-"patch_size") |>
    readr::write_csv(file.path(dir, "summary", "connectivity-summary.csv"))

  # the summary already carries the per-patch tables, so unnest rather than
  # stack them back together
  x$connectivity |>
    dplyr::select("species", "interpatch_distance", "patch_size") |>
    tidyr::unnest("patch_size") |>
    readr::write_csv(file.path(dir, "summary", "patch-areas.csv"))
}

#' @noRd
write_asset_plots <- function(x, dir) {
  purrr::walk2(
    x$buffered_habitat,
    x$interpatch_distance,
    function(buffered, distance) {
      gg_barrier_habitat_interpatch_dist(
        barrier = x$barrier,
        buffered = buffered,
        habitat = x$habitat,
        interpatch_distance = distance,
        species = x$species
      ) |>
        save_asset_plot(distance_file(
          dir,
          distance,
          "maps",
          "habitat-buffer-barrier.png"
        ))
    }
  )

  purrr::walk2(
    x$patch_id_raster,
    x$interpatch_distance,
    function(patch_id, distance) {
      plot_patches(
        patch_id = patch_id,
        interpatch_distance = distance,
        species = x$species
      ) |>
        save_asset_plot(distance_file(dir, distance, "maps", "patches.png"))
    }
  )

  if (has_over_distance_plot(x)) {
    plot_connectivity(x$connectivity) |>
      save_asset_plot(
        file.path(dir, "summary", "connectivity-over-distance.png"),
        height = urbio_figure_size()$tall_height
      )
  }
}

#' @noRd
write_asset_gis <- function(x, dir) {
  purrr::pwalk(
    list(
      x$patch_id_raster,
      x$interpatch_distance,
      patch_sizes(x$connectivity)
    ),
    function(patch_id, distance, patch_table) {
      terra::writeRaster(
        patch_id,
        distance_file(dir, distance, "gis", "patches.tif"),
        overwrite = TRUE
      )

      write_patch_polygons(patch_id, patch_table, dir, distance)
    }
  )
}

#' Patch polygons, as GeoPackage and shapefile
#'
#' `as.polygons()` carries `patch_id` only, since `area` is a separate raster
#' layer. The areas come from the per-patch table rather than that layer, which
#' holds a value per cell and would multiply each polygon on the join. A
#' distance with no patches writes nothing: there is no geometry to write.
#'
#' @noRd
write_patch_polygons <- function(patch_id, patch_table, dir, distance) {
  polygons <- terra::as.polygons(patch_id[["patch_id"]], dissolve = TRUE)

  if (nrow(polygons) == 0) {
    return(invisible(NULL))
  }

  areas <- as.data.frame(patch_table)[c("patch_id", "area")]

  polygons <- terra::merge(polygons, areas, by = "patch_id")

  terra::writeVector(
    polygons,
    distance_file(dir, distance, "gis", "patches.gpkg"),
    overwrite = TRUE
  )
  terra::writeVector(
    polygons,
    distance_file(dir, distance, "gis", "patches.shp"),
    overwrite = TRUE
  )

  invisible(polygons)
}

#' @noRd
write_asset_readme <- function(x, manifest, dir) {
  template <- readLines(
    system.file("templates", "bundle-README.md", package = "urbioconnect")
  )

  file_list <- glue::glue_data(manifest, "- `{path}` - {description}")

  readme <- glue::glue_collapse(template, sep = "\n") |>
    glue::glue(
      .open = "{{",
      .close = "}}",
      species = x$species,
      distances = glue::glue_collapse(
        paste0(x$interpatch_distance, "m"),
        sep = ", ",
        last = " and "
      ),
      resolution = format_resolution(terra::res(x$habitat)),
      crs = terra::crs(x$habitat, describe = TRUE)$name,
      date = format(Sys.Date()),
      version = as.character(utils::packageVersion("urbioconnect")),
      files = glue::glue_collapse(file_list, sep = "\n")
    )

  writeLines(readme, file.path(dir, "README.md"))
}

#' @noRd
distance_file <- function(dir, distance, folder, file) {
  file.path(dir, glue::glue("interpatch-{distance}m"), folder, file)
}

#' @noRd
save_asset_plot <- function(plot, path, height = NULL) {
  size <- urbio_figure_size()

  ggplot2::ggsave(
    filename = path,
    plot = plot,
    width = size$width,
    height = height %||% size$height,
    dpi = size$dpi,
    bg = "white"
  )
}
