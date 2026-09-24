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
#'
#' @returns The manifest, invisibly: a tibble of `path`, `kind` and
#'   `description`, one row per file written, with paths relative to `dir`.
#' @seealso [connectivity_report_data()], [zip_connectivity_assets()]
#' @export
#'
#' @examples
#' \donttest{
#' report_data <- connectivity_report_data(
#'   habitat = example_wren_habitat(),
#'   barrier = example_wren_barrier(),
#'   species = "Superb Fairy Wren",
#'   interpatch_distance = 200,
#'   verbose = FALSE
#' )
#'
#' assets <- write_connectivity_assets(report_data, dir = tempfile())
#' assets$path
#' }
write_connectivity_assets <- function(x, dir) {
  check_report_data(x)

  manifest <- asset_manifest(x)

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
#'
#' @returns `path`, invisibly.
#' @seealso [write_connectivity_assets()] to write the files without archiving.
#' @export
#'
#' @examples
#' \donttest{
#' report_data <- connectivity_report_data(
#'   habitat = example_wren_habitat(),
#'   barrier = example_wren_barrier(),
#'   species = "Superb Fairy Wren",
#'   interpatch_distance = 200,
#'   verbose = FALSE
#' )
#'
#' zip_path <- zip_connectivity_assets(report_data, tempfile(fileext = ".zip"))
#' zip::zip_list(zip_path)$filename
#' }
zip_connectivity_assets <- function(x, path) {
  check_report_data(x)

  # staged in a temp directory so the archive contains one named folder rather
  # than a scatter of files
  staging <- tempfile("urbioconnect-assets")
  on.exit(unlink(staging, recursive = TRUE), add = TRUE)

  folder <- bundle_dir_name(x)
  write_connectivity_assets(x, file.path(staging, folder))

  zip::zip(zipfile = path, files = folder, root = staging)

  invisible(path)
}

#' The bundle's folder name: species and date
#'
#' @noRd
bundle_dir_name <- function(x) {
  glue::glue("{slugify(x$species)}-connectivity-{Sys.Date()}")
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

#' What a bundle contains
#'
#' The single source of truth for the layout: the writer uses it to know where
#' files go, and the README lists it, so the two can't drift.
#'
#' @noRd
asset_manifest <- function(x) {
  distances <- x$interpatch_distance

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

  # a single distance gives a single point, so there is nothing to plot
  over_distance <- tibble::tibble(
    path = "summary/connectivity-over-distance.png",
    kind = "plot",
    description = "How the metrics change across interpatch distances."
  )

  per_distance <- purrr::map(distances, distance_manifest) |>
    purrr::list_rbind()

  dplyr::bind_rows(
    shared,
    if (length(distances) > 1) over_distance,
    per_distance
  )
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

  patch_sizes(x$connectivity) |>
    rlang::set_names(x$interpatch_distance) |>
    purrr::list_rbind(names_to = "interpatch_distance") |>
    readr::write_csv(file.path(dir, "summary", "patch-areas.csv"))
}

#' @noRd
write_asset_plots <- function(x, dir) {
  colours <- asset_colours()

  purrr::walk2(
    x$buffered_habitat,
    x$interpatch_distance,
    function(buffered, distance) {
      gg_barrier_habitat_interpatch_dist(
        barrier = x$barrier,
        buffered = buffered,
        habitat = x$habitat,
        interpatch_distance = distance,
        species = x$species,
        col_barrier = colours$barrier,
        col_interpatch_dist = colours$interpatch_distance,
        col_habitat = colours$habitat
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

  if (length(x$interpatch_distance) > 1) {
    plot_connectivity(x$connectivity) |>
      save_asset_plot(
        file.path(dir, "summary", "connectivity-over-distance.png"),
        height = 8
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

  file_list <- glue::glue_data(manifest, "- `{path}` — {description}")

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
      resolution = paste(round(terra::res(x$habitat), 2), collapse = " x "),
      crs = terra::crs(x$habitat, describe = TRUE)$name,
      date = format(Sys.Date()),
      version = as.character(utils::packageVersion("urbioconnect")),
      files = glue::glue_collapse(file_list, sep = "\n")
    )

  writeLines(readme, file.path(dir, "README.md"))
}

#' The bundle's map colours
#'
#' The palette the Shiny app uses, so downloaded maps match what was on screen.
#'
#' @noRd
asset_colours <- function() {
  palette <- scico::scico(n = 11, palette = "tofino")[6:11]

  list(
    habitat = palette[2],
    interpatch_distance = palette[5],
    barrier = "#FFFFFF"
  )
}

#' @noRd
distance_file <- function(dir, distance, folder, file) {
  file.path(dir, glue::glue("interpatch-{distance}m"), folder, file)
}

#' @noRd
save_asset_plot <- function(plot, path, width = 8, height = 6) {
  ggplot2::ggsave(
    filename = path,
    plot = plot,
    width = width,
    height = height,
    dpi = 150,
    bg = "white"
  )
}
