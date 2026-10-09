# Appended to the bundled R's etc/Rprofile.site by build-desktop-app.yaml, so
# a desktop build can find the Quarto and the library shipped beside it.
#
# Rprofile.site is the hook because R reads it at the startup of every session
# using this R, which is the only place reaching both the Shiny process
# Electron spawns and the R that Quarto's knitr engine spawns under it.

tryCatch(
  local({
    # R.home() is runtime/R/<version>, so the app's library sits beside it and
    # runtime/ is one further up.
    exe <- if (.Platform$OS.type == "windows") ".exe" else ""
    quarto <- file.path(
      R.home(),
      "..",
      "..",
      "quarto",
      "bin",
      paste0("quarto", exe)
    )

    if (file.exists(quarto)) {
      # A deliberately set QUARTO_PATH wins. QUARTO_R gets no such guard: the
      # bundled R is the only one with the app's packages in it.
      if (!nzchar(Sys.getenv("QUARTO_PATH"))) {
        Sys.setenv(QUARTO_PATH = normalizePath(quarto, winslash = "/"))
      }
      # Quarto's knitr engine looks for R on the PATH, and there is none here.
      Sys.setenv(QUARTO_R = file.path(R.home("bin"), paste0("Rscript", exe)))
    }

    # Electron sets .libPaths() for the Shiny process alone, so the R that
    # Quarto spawns under it would not see the app's packages.
    library_dir <- file.path(R.home(), "..", "library")

    if (dir.exists(library_dir)) {
      .libPaths(c(normalizePath(library_dir, winslash = "/"), .libPaths()))
    }
  }),
  # An error in a site profile halts R, so a surprise here must cost the app
  # its reports, not its launch.
  error = function(e) {
    message("Could not reach the bundled Quarto: ", conditionMessage(e))
  }
)
