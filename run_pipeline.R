# run_pipeline.R
# Orchestrates 00 to 11

RUN_EXPENSIVE_STAGES <- FALSE

args <- commandArgs(trailingOnly = TRUE)
if ("RUN_EXPENSIVE_STAGES=TRUE" %in% args) {
  RUN_EXPENSIVE_STAGES <- TRUE
}

scripts <- list.files("scripts", pattern = "^\\d{2}_.*\\.R$", full.names = TRUE)
scripts <- sort(scripts)

for (s in scripts) {
  cat("Running", s, "\n")
  if (grepl("03_|05_|06_", s) && !RUN_EXPENSIVE_STAGES) {
    cat("Skipping expensive stage:", s, "\n")
    next
  }
  source(s)
}
