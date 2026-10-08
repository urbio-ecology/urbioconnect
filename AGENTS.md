# NA

## This package

urbioconnect analyses habitat connectivity in urban landscapes, and
ships a Shiny app, “Urban Connectedness”, to assist urban planning
(E.g., Local Government, NGOs).

### Where things live

- `R/`: package code.
- `inst/shiny/`: the Shiny app, started with
  [`run_connectivity_app()`](https://urbio-ecology.github.io/urbioconnect/reference/run_connectivity_app.md).
  It is a legacy-layout shiny app: `global.R`, then `ui.R` and
  `server.R`, all sourced by shiny itself. `global.R` is the one place
  packages are attached, and it sources `colours.R`. Don’t add an
  `app.R`: shiny checks for `server.R` first, so an `app.R` here is
  never read. Only change UI and server code in `inst/shiny/ui.R` and
  `inst/shiny/server.R`.
- `inst/non-targets-workflow.R` and `inst/scenario-workflow.R`: example
  workflows.
- `dev/`: specs and reviews. Build-ignored.

### Code

- **The package is pre-release, and we are not keeping backwards
  compatibility.** Always prefer the best API over the existing one.
  Change signatures outright, update the tests, snapshots, docs and app
  in the same commit, and skip deprecation cycles. Don’t carry an
  awkward argument because something already calls it.
- `connectivity` and `patch_size_tbl` are S3 tibble subclasses. Keep
  them S3; don’t use S7 or R6 or S4.
- For S3 dispatch on input type, write a `.default` method rather than a
  `character` method.

### Tests

These add to the general test style later in this file.

- No `for` loops. Use
  [`purrr::walk()`](https://purrr.tidyverse.org/reference/map.html) or
  [`purrr::map()`](https://purrr.tidyverse.org/reference/map.html).
- Prefer `expect_snapshot()` to asserting exact names or values. For
  example, `expect_snapshot(names(x))` rather than
  `expect_named(x, c(...))`.
- Mock with `local_mocked_bindings()`, never mockery.
- Use small synthetic rasters for quick code paths. Keep the real
  spatial data (the lizard or wren examples) for at least one content or
  snapshot test per file.
- Check test speed with `devtools::test(reporter = "slow")`.
- **The suite runs in parallel** (`Config/testthat/parallel: true`), one
  subprocess per test file. testthat uses 2 workers unless
  `getOption("Ncpus")` or `TESTTHAT_CPUS` says otherwise. Two things
  follow: test files must not depend on each other, and package code
  must namespace-qualify everything, because a subprocess starts with
  fewer packages attached than your session. A bare
  [`globalVariables()`](https://rdrr.io/r/utils/globalVariables.html) in
  the package file worked for years and broke the moment this was turned
  on.
- `devtools::test()` passing does not mean `R CMD check` will. It uses
  `load_all()`, so it never sees a missing export, a broken example, or
  anything that only shows up once the package is installed. The local
  gate for that is `devtools::check()`, which installs the package, runs
  `tests/testthat.R` with `NOT_CRAN=true`, and checks the examples and
  docs as well.
- Don’t hand-roll the installed test run (`R CMD INSTALL` then
  `cd tests && Rscript testthat.R`). It takes as long as a check while
  testing less, and GitHub CI already does it on every push - that is
  what CI is for. `devtools::check()` locally, CI for the rest.

### Testing the shiny app

Two kinds of test, and they see different things. Both are needed.

- **`testServer()`** (`test-shiny-app.R`) drives the server function. It
  is cheap and good for reactives, handlers and outputs. It **cannot**
  tell you whether shiny can run the app directory at all, because it
  sources `global.R` and `server.R` by hand. An app that fails to start
  passes every one of these.
- **[`shinytest2::AppDriver`](https://rstudio.github.io/shinytest2/reference/AppDriver.html)**
  (`test-app-starts.R`) starts the app for real in a browser. This is
  the only thing that catches a broken app directory, a UI that errors
  on render, or a `conditionalPanel` that doesn’t. Needs `NOT_CRAN=true`
  and Chrome; `AppDriver$new()` calls `skip_on_cran()` itself.

Helpers in `helper-shiny-app.R`: `skip_if_no_app()`,
`local_app_server()`, `app_lizard_inputs()` and `app_example_inputs()`
for `testServer()`; `skip_if_no_browser_app()` and `local_app_driver()`
for `shinytest2`.

**Use the lizard dataset, not the wren one.** The app offers both as
example data; `app_lizard_inputs()` picks the lizard. It is ~200x200
cells after
[`prepare_rasters()`](https://urbio-ecology.github.io/urbioconnect/reference/prepare_rasters.md)
against the wren’s 1500x1400, so a full analysis with a scenario
comparison runs in under a second instead of tens of seconds. Each
dataset has its own scenarios (`lizard_road`; `knox_barrier` and
`knox_habitat`), so nothing needs the wren data to exercise a
comparison. `app_upload_inputs()` covers the upload path with the same
landscape, as a GeoTIFF habitat and a shapefile barrier, so it exercises
both readers.

Nothing in the suite should run a wren analysis. Doing so costs 10-27s
per distance, and that one habit was most of a 183s suite.

How to write the browser tests:

- **Give every navset an `id`** and drive it with
  `app$set_inputs(main_nav = "Results")`, not
  `app$run_js('$("a[data-value=...]").tab("show")')`. The app has
  `main_nav`, `results_view` and `landscape_view` for this. Outputs
  suspend while hidden, so a test must open every panel down to the one
  it asserts on, or the output is never rendered and `getElementById`
  returns null.
- **`app$upload_file()` takes exactly one input per call.** Two uploads,
  two calls.
- Reach for `app$get_js()`/`app$run_js()` only for what is genuinely
  client-side, such as driving the diffviewer widget. Anything with an
  input or output id should go through `set_inputs()`/`get_values()`.
- The before/after comparison is **diffviewer** (`visual_diff()`), the
  widget behind
  [`testthat::snapshot_review()`](https://testthat.r-lib.org/reference/snapshot_accept.html),
  which gives difference, toggle and slider views for free. It compares
  files, so each side is written to a PNG first, at twice the display
  size because `ZOOM_DEFAULT` in its JS is hardcoded to 1:2. Don’t
  hand-roll an image comparison here; the one that was here before is in
  the git history and diffviewer replaced all of it.

Three traps, all of which have cost real time here:

- **`system.file("shiny", ...)` points somewhere different depending on
  how you run.** Under `devtools::test()` it is `inst/shiny/` in the
  source tree; under `R CMD check` it is the installed copy. So editing
  `inst/shiny/` and running `devtools::test()` works, while the running
  app does not until you reinstall. If you are checking that a test
  catches an app bug, break the **source** copy, not the installed one,
  or you will prove nothing.
- **A `selectInput`’s own `<select>` is hidden** behind its selectize
  widget, so `$("#id").is(":visible")` is always `FALSE` for one. Ask
  about `#id-label` instead.
- **`testServer()` gives you R types; the browser gives you whatever
  JSON says.** A `numericInput` arrives as a double under `testServer()`
  and as an integer from the browser, so `identical(input$n, 10)` passes
  in one and fails in the other. Compare with `==`. A guard written this
  way looked fine in `testServer()` and broke the real app.

### The Shiny app

- Use bslib (Bootstrap 5) with cards and a modern theme. Show loading
  indicators while data uploads and while the analysis runs.
- Read [Mastering Shiny](https://mastering-shiny.org/) for how to
  structure the app.

Inputs:

- Habitat and barrier layers, as raster or vector data.
- `species`, for example `"Superb Fairy Wren"`.
- `interpatch_distance`, one to four values, for example
  `c(100, 250, 400)`.
- `data_resolution`, for example `10`.

Outputs, on a results tab:

- The `connectivity` summary for each distance, as a table and a CSV.
- The per-patch areas for each distance (from
  [`patch_sizes()`](https://urbio-ecology.github.io/urbioconnect/reference/patch_sizes.md)),
  as a table and a CSV.
- A map of habitat, buffer and barrier.
- A map of habitat by connected patch, plus the GeoTIFF behind it for
  use in GIS.
- A plot of how the key statistics change over distance, shown only when
  more than one distance is given.
- A single report (HTML or PDF) containing all of the above.
- Every one of these can be downloaded.

## Package development

### Key commands

(All these functions have been optimized for agentic use, so they can be
called directly without other arguments.)

``` r

# Executing code
devtools::load_all()
code

# Tests
devtools::test() # all tests
devtools::test(filter = "^{name}") # tests for files starting with {name}
devtools::test_active_file("R/{name}.R") # tests for R/{name}.R
devtools::test_active_file("R/{name}.R", desc = 'blah') # single test with exact description "blah" (no regexp)

# Test coverage
devtools::test_coverage() # all files
devtools::test_coverage_active_file("R/{name}.R") # coverage for R/{name}.R from tests in tests/testthat/test-{name}.R

# Documentation
devtools::document() # redocument package
pkgdown::check_pkgdown() # check website

# Run complete R CMD check
devtools::check()
```

### Running R

There are three possible ways to run code, listed in rough order of
desirability:

- If you’re running inside Posit Assistant or otherwise have an
  `executeCode()` tool available, use it to run code in a session that
  the user can also interact with.

- Otherwise, if an R REPL (e.g. `mcp__r__repl` or `btw::run_r`) is
  available, use that. Note that `mcp__r__repl` uses a sandbox that
  blocks network requests and reads/writes outside of the current
  directory.

- Otherwise, use `Rscript -e "code"`. On Windows, `Rscript -e` can
  segfault on multiline or complex code; in that case, write it to a
  temporary `.R` file and run `Rscript path/to/file.R`.

### Code style

- Never ever use nonAscii contents in files
- Never use ” — ” always use “-”
- Follow the tidyverse style guide
- Always run `air format .` after generating code. (air is bundled with
  Positron so look there if you can’t otherwise find it.)
- Use the base pipe operator (`|>`), not the magrittr pipe (`%>%`).
- Use `\() ...` for single-line anonymous functions. For all other
  cases, use `function() {...}`.

### Test style

- Tests for `R/{name}.R` go in `tests/testthat/test-{name}.R`.
- All new code should have an accompanying test.
- If there are existing tests, place new tests next to similar existing
  tests.
- Strive to keep your tests minimal with few comments.
- Never put code in a `test-{name}.R` file outside of a `test_that()`
  block. Instead, use `tests/testthat/helper.R` or
  `tests/testthat/helper-{name}.R`.
- Avoid `expect_true()` and `expect_false()` in favor of a specific
  expectation with a better failure message. A few expectations in newer
  releases that you might not know about are `expect_all_true()`,
  `expect_all_equal()`, and `expect_r6_class()`.
- When testing errors and warnings:
  - Only use `expect_error()` or `expect_warning()` if the error or
    warning has a known class.
  - Generally, prefer `expect_snapshot(error = TRUE)` for errors and
    `expect_snapshot()` for warnings because these allow the user to
    review the full text of the output.
- Avoid the `.package` argument to `local_mocked_bindings()`; this
  modifies the namespace of another package, which is not good practice.
  Instead create a mockable version of the function in the current
  package. See `?local_mocked_bindings` for more details.

### Documentation

- Never ever use nonAscii contents in files
- Never use ” — ” always use “-”
- Every user-facing function should be exported and have roxygen2
  documentation.
- Internal functions may have roxygen blocks, as long as they use
  `@noRd`.
- Wrap roxygen2 comments to 80 characters.
- Whenever you add a new (non-internal) documentation topic, also add
  the topic to `_pkgdown.yml`.
- Always re-document the package after changing a roxygen2 comment.
- Use
  [`pkgdown::check_pkgdown()`](https://pkgdown.r-lib.org/reference/check_pkgdown.html)
  to check that all topics are included in the reference index.

### `NEWS.md`

- Never ever use nonAscii contents in files
- Never use ” — ” always use “-”
- Every user-facing change should be given a bullet in `NEWS.md`.
- Changes that shouldn’t get a bullet:
  - Small documentation changes.
  - Internal refactorings.
  - Fixes to bugs introduced in the current dev version.
- Each bullet should briefly describe the change to the end user and
  mention the related issue in parentheses.
- A bullet can consist of multiple sentences but should not contain any
  newlines (i.e. DO NOT line wrap).
- If the change is related to a function, put the name of the function
  early in the bullet.
- If the change is related to an issue, include the issue number in
  parentheses.
- Only include a GitHub username if the PR was created by someone who
  isn’t an author.
- Order bullets alphabetically by function name. Put all bullets that
  don’t mention function names at the beginning.

## Specialized skills

- Do you need to deprecate a function or argument? Read
  `usethis::learn_tidy_skill("deprecate")`.
- Are you adding input checking to an existing function or writing a new
  exported function? Read `usethis::learn_tidy_skill("arg-checking")`.
- Are you creating a new package? Read
  `usethis::learn_tidy_skill("package-setup")`.

## Git

- Never commit, push or merge without explicit approval for that
  specific commit. Approval for one commit does not carry over to the
  next.
- If the user asks you to commit, use markdown in the commit message,
  and don’t line wrap.
- Draft commit messages should be terse, and state the changes made
  clearly. One sentence as a heading, then bulleted lists to describe
  changes
- If the commit fixes an issue, include `Fixes #num.` on its own line.
- Only push when the user explicitly requests it.

## Writing

- Never ever use nonAscii contents in files
- Never use ” — ” always use “-”
- Use sentence case for headings.
- Use Australian English.

### Proofreading

If the user asks you to proofread a file, act as an expert proofreader
and editor with a deep understanding of clear, engaging, and
well-structured writing.

Work paragraph by paragraph, always starting by making a TODO list that
includes individual items for each top-level section.

Fix spelling, grammar, and other minor problems without asking the user.
Label any unclear, confusing, or ambiguous sentences with a FIXME
comment.

Only report what you have changed.
