# The one place the app attaches packages, so neither ui.R nor server.R
# declares its own.
#
# This has to be called global.R. shiny checks for server.R before app.R, so a
# directory holding ui.R and server.R is run as the legacy two-file app and an
# app.R is never read - which is how a packages.R sourced from app.R came to be
# silently skipped. global.R is the layout's own hook, sourced before both.
#
# tidyverse is deliberately not used here: it isn't a dependency of the
# package, so a clean machine (CI included) can't load the app or test it.
# These are the tidyverse packages the app actually uses.
library(conflicted)

# Declared before the packages that create the conflicts, not after. tidyterra
# defines dplyr verbs for SpatRaster, so attaching it makes R compare the
# `filter` and `select` bindings, and conflicted errors on reading an
# undeclared one. With the preference set first there is nothing to error on.
conflicts_prefer(dplyr::filter)
conflicts_prefer(dplyr::select)

library(bslib)
library(diffviewer)
library(dplyr)
library(DT)
library(fasterize)
library(ggplot2)
library(glue)
library(purrr)
library(readr)
library(scico)
library(sf)
library(shiny)
library(shinyjs)
library(terra)
library(tidyr)
library(tidyterra)
library(urbioconnect)

# ui.R and server.R are sourced by shiny itself; colours.R is not, so it comes
# in here
source("colours.R")

# Where the before/after PNGs for diffviewer are written. One directory for
# the process, cleaned up when it exits: diffviewer compares files, not plots.
compare_png_dir <- tempfile("urbio-compare-")
dir.create(compare_png_dir, recursive = TRUE, showWarnings = FALSE)

# diffviewer opens at 1:2, because it is built for retina snapshots, so the
# PNGs are written at twice the size we want on screen.
compare_png_inches <- 6
compare_png_dpi <- 200

# Two places where diffviewer's own styling doesn't survive being embedded in
# a bslib app.
compare_css <- "
/* sized for diffviewer's font; in bslib's, 'Difference' wraps to two lines */
.diffviewer .image-diff-view-buttons > .image-diff-button {
  width: auto;
  padding-left: 10px;
  padding-right: 10px;
  white-space: nowrap;
}
/* diffviewer is a snapshot review tool, so it heads each image with the file
   name and a CHANGED badge. The tab above already says which landscape and
   which distance this is. */
.diffviewer .d2h-file-header {
  display: none;
}
"

# The example landscapes, and the scenarios that go with each. A scenario is
# only comparable against the landscape it was drawn on, so which ones are
# offered follows from which example data is chosen.
#
# The layers are functions rather than values: nothing is read off disk until
# someone asks for that dataset.
example_datasets <- list(
  lizard = list(
    label = "Blue Tongue Lizard, Darebin Creek (fast)",
    species = "Blue Tongue Lizard",
    habitat = example_habitat,
    barrier = example_barrier,
    scenarios = list(
      lizard_road = list(
        label = "A new road through the habitat",
        kind = "barrier",
        layer = example_barrier_scenario
      )
    )
  ),
  wren = list(
    label = "Superb Fairy Wren, Knox (large, slower)",
    species = "Superb Fairy Wren",
    habitat = function() {
      read_geometry(wren_file("superbHab.shp")) |> clean() |> st_as_sf()
    },
    barrier = function() {
      read_geometry(wren_file("allSFWRoads.shp")) |> clean() |> st_as_sf()
    },
    scenarios = list(
      knox_barrier = list(
        label = "Knox planning data: new barriers",
        kind = "barrier",
        layer = example_wren_barrier_scenario
      ),
      knox_habitat = list(
        label = "Habitat removed: a development",
        kind = "habitat",
        layer = example_wren_habitat_scenario
      )
    )
  )
)

wren_file <- function(name) {
  file.path(
    system.file("shiny-data/superb-fairy-wren", package = "urbioconnect"),
    name
  )
}

# "none" first, so the app opens on an upload rather than loading anything
example_data_choices <- c(
  stats::setNames("none", "None - upload my own layers"),
  stats::setNames(
    names(example_datasets),
    vapply(example_datasets, \(dataset) dataset$label, character(1))
  )
)

# What the scenario dropdown offers for a given example dataset: its own
# scenarios, if it has any, plus none and an upload. Uploading is always an
# option because an uploaded scenario is put on whatever grid is in use.
scenario_choices <- function(dataset_name) {
  supplied <- example_datasets[[dataset_name %||% ""]]$scenarios

  c(
    stats::setNames("none", "None"),
    # names(NULL) is NULL, and setNames() cannot name that
    stats::setNames(
      names(supplied) %||% character(),
      vapply(supplied, \(scenario) scenario$label, character(1))
    ),
    stats::setNames("upload", "Upload my own")
  )
}

# What every file input offers, in one place: three copies of this list is how
# the UI came to advertise .gpkg while read_uploaded_file() rejected it. The
# sidecars have to be offered because a shapefile is useless without them.
spatial_upload_accept <- c(
  ".shp",
  ".tif",
  ".tiff",
  ".geojson",
  ".gpkg",
  ".shx",
  ".dbf",
  ".prj",
  ".cpg"
)
