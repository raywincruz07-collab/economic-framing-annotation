# ============================================================
# scripts/step4_0_intercoder_reliability.R
# Computes Krippendorff's Alpha for human-human overlap.
# ============================================================

rm(list = ls())
source("config.R", encoding = "UTF-8")
source("scripts/utils.R", encoding = "UTF-8")

# Ensure output directory exists
dir.create("reports/reliability", recursive = TRUE, showWarnings = FALSE)

suppressPackageStartupMessages({
  library(readr)
  library(dplyr)
  library(irr)
})

cat("=== INTERCODER RELIABILITY CHECK ===\n")

# Load overlap data
overlap_file <- "data/intercoder/overlap_1000_template.csv"

if (!file.exists(overlap_file)) {
  cat("No intercoder overlap data found at:", overlap_file, "\n")
  cat("Skipping reliability calculation.\n")
} else {
  df <- read_csv(overlap_file, show_col_types = FALSE)
  
  # Select coder columns (starting with coder_)
  coder_cols <- grep("^coder_", names(df), value = TRUE)
  
  if (length(coder_cols) < 2) {
    cat("Insufficient coder columns for reliability check.\n")
  } else {
    cat("Analyzing coders:", paste(coder_cols, collapse = ", "), "\n")
    
    # Prepare data for irr (transpose: rows = coders, cols = units)
    mat <- as.matrix(t(df[, coder_cols]))
    
    # Compute Krippendorff's Alpha
    alpha_res <- kripp.alpha(mat, method = "nominal")
    print(alpha_res)
    
    # Save result
    sink("reports/reliability/intercoder_alpha.txt")
    print(alpha_res)
    sink()
    
    cat("\nReliability report saved: reports/reliability/intercoder_alpha.txt\n")
  }
}
