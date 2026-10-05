# The one place the app attaches packages. app.R sources this before ui.R and
# server.R, so neither of those declares its own.
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
