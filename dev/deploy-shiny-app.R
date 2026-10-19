# Upload inst/shiny to shinyapps.io, over the live app at
# https://njtierney.shinyapps.io/urbioconnect/. Run from the package root on
# main.
#
# inst/shiny is bundled from the working tree, but urbioconnect itself is
# installed from the r-universe build of main, so local changes under R/ do not
# reach the uploaded app.

# urbioconnect is not on CRAN, and a locally built copy carries no remote
# metadata, so without the org's r-universe renv cannot name a source for it
# and rsconnect aborts before uploading anything.
options(
  repos = c(
    urbio = "https://urbio-ecology.r-universe.dev",
    CRAN = "https://cloud.r-project.org"
  )
)

rsconnect::deployApp(
  appDir = "inst/shiny",
  appName = "urbioconnect",
  appTitle = "Urban Connectedness",
  appId = 16283987,
  account = "njtierney",
  server = "shinyapps.io",
  forceUpdate = TRUE
)
