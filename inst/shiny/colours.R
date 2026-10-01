# Urban Connectivity Color Palette
# Based on scico tofino palette

# Generate urbio palette
urbio_pal <- scico::scico(n = 11, palette = "tofino")
urbio_pal_cut <- urbio_pal[c(6:11)]

# The map colours come from the package, so downloaded maps match the screen
urbio_cols <- urbio_colours()

# Define UI color variables
urbio_ui_cols <- list(
  primary = urbio_pal_cut[4], # Medium green for buttons
  success = urbio_pal_cut[5], # Light green for alerts
  accent = urbio_pal_cut[3] # Darker green
)

# Export individual colors for easy access
col_habitat <- urbio_cols$habitat
col_interpatch_distance <- urbio_cols$interpatch_distance
col_barrier <- urbio_cols$barrier
col_primary <- urbio_ui_cols$primary
col_success <- urbio_ui_cols$success
col_accent <- urbio_ui_cols$accent

# Create complete Bootstrap theme
urbio_theme <- function() {
  bs_theme(
    version = 5,
    preset = "shiny",

    # Primary colors using urbio palette
    primary = col_primary, # Medium green for primary actions
    secondary = "#6c757d", # Keep default grey
    success = col_success, # Light green for success states
    info = urbio_pal_cut[6], # Lightest green for info
    warning = "#f9a825",
    danger = "#d32f2f",

    base_font = font_google("Inter"),
    heading_font = font_google("Roboto"),
    code_font = font_google("Fira Code"),

    bg = "#ffffff",
    fg = "#212529",

    # Additional customization
    "card-border-color" = "#dee2e6",
    "card-cap-bg" = "#f8f9fa",
    "btn-border-radius" = "0.375rem",
    "input-border-radius" = "0.375rem"
  )
}

# Optional: Dark theme variant
urbio_theme_dark <- function() {
  bs_theme(
    version = 5,
    preset = "shiny",
    bootswatch = "darkly",

    # Primary colors using urbio palette
    primary = col_primary,
    secondary = "#6c757d",
    success = col_success,
    info = urbio_pal_cut[6],
    warning = "#f9a825",
    danger = "#d32f2f",

    # Typography
    base_font = font_google("Inter"),
    heading_font = font_google("Roboto"),
    code_font = font_google("Fira Code")
  )
}
