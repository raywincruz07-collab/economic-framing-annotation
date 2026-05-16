# ============================================================
# scripts/utils.R
# Shared helper functions for the annotation pipeline
# ============================================================

# ── Label cleaning helper (v2 — scalar function for use with sapply) ─
clean_label <- Vectorize(function(x) {
  if (is.null(x) || is.na(x)) return(NA_character_)
  x <- as.character(x)
  x <- trimws(gsub("\\*", "", x))   # remove all asterisks
  x <- trimws(gsub("`",  "", x))    # remove backticks
  x <- toupper(x)
  
  if (grepl("LABEL:\\s*YES", x)) return("YES")
  if (grepl("LABEL:\\s*NO", x)) return("NO")
  
  matches <- regmatches(x, gregexpr("\\b(YES|NO)\\b", x))[[1]]
  if (length(matches) > 0) {
    return(matches[length(matches)])
  }
  
  return(NA_character_)
})

# ── Text cleaning helper (to prevent API 400 errors from non-ASCII) ──
clean_text_api <- Vectorize(function(x) {
  if (is.null(x) || is.na(x)) return(x)
  # Replace common weird characters
  x <- iconv(x, to = "UTF-8", sub = "")
  x <- gsub("[^\x01-\x7F]", " ", x) # Replace remaining non-ASCII with spaces
  x
})
