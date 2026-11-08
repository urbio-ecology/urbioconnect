# Small helpers for the server that need neither the session nor the inputs,
# so each can be tested on its own

# The entries typed in the interpatch distances box: split at the commas, with
# the blanks dropped. NULL, before the box has sent anything, gives none.
extract_interpatch_distances <- function(text) {
  typed <- text %||% ""
  pieces <- strsplit(typed, ",")[[1]]
  entries <- trimws(pieces)
  entries[entries != ""]
}
