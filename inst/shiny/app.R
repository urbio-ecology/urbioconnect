# packages.R attaches everything the app needs. Without it the app only runs
# because ui.R and server.R re-declare their own libraries, which hides which
# packages the app actually depends on.
source("packages.R")
source("colours.R")

source("ui.R")
source("server.R")

shinyApp(ui, server)
