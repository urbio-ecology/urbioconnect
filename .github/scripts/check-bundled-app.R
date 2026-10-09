# Run by build-desktop-app.yaml with the installer's own Rscript, against the
# bundle it has just assembled.
#
# This is the only check that exercises the contract rather than its parts: a
# Quarto put somewhere nothing will look, a library path that does not reach
# the R under Quarto, a package that failed to embed, a syntax error in the
# appended profile, and the pinned Quarto itself, which nothing else renders
# with. CI renders the reports against whatever Quarto is current, so without
# this the version that actually ships is never tried.

stopifnot(
  "no QUARTO_PATH; the appended profile did not find the bundled Quarto" =
    nzchar(Sys.getenv("QUARTO_PATH")),
  "QUARTO_PATH names a file that is not there" =
    file.exists(Sys.getenv("QUARTO_PATH")),
  "urbioconnect is not in the bundled library" =
    requireNamespace("urbioconnect", quietly = TRUE),
  "the bundled Quarto does not answer --version" =
    urbioconnect::quarto_available()
)

cat("quarto", format(quarto::quarto_version()), "at", Sys.getenv("QUARTO_PATH"), "\n")

# The lizard landscape at one distance, which analyses in under a second.
report <- urbioconnect::connectivity_report_data(
  habitat = urbioconnect::example_habitat(),
  barrier = urbioconnect::example_barrier(),
  species = "Blue Tongue Lizard",
  interpatch_distance = 100,
  verbose = FALSE
)

out <- tempfile("smoke-")
dir.create(out)

# Both formats: HTML is what most people will download, and the PDF goes
# through Typst, which is the half with a version floor behind it.
render <- function(extension) {
  path <- file.path(out, paste0("smoke.", extension))
  urbioconnect::generate_connectivity_report(report, path)

  if (!file.exists(path)) {
    stop("no ", extension, " report at ", path)
  }

  cat("rendered", extension, prettyNum(file.size(path), big.mark = ","), "bytes\n")
}

render("html")
render("pdf")
