rm(list = ls())
source("config.R", encoding = "UTF-8")
source("scripts/utils.R", encoding = "UTF-8")

# Ensure output directories exist
dir.create("outputs/step2_2", recursive = TRUE, showWarnings = FALSE)

suppressPackageStartupMessages({
  library(bacchuss)
  library(readr)
  library(dplyr)
})

# ── Load 200-row sample ──────────────────────────────────────
cat("Loading 200-row sample...\n")
sample_200 <- read_csv(SAMPLE_200_FILE, show_col_types = FALSE)
cat("Loaded:", nrow(sample_200), "rows\n")

# ── THREAT hard cases ─────────────────────────────────────────
cat("\n--- Running THREAT hard-case detection (briseus) ---\n")
cat("Measuring consistency over 5 runs per row...\n")
t_start <- Sys.time()

hard_threat <- briseus(
  sample_200,
  input_column = "text_block_english",
  n_runs       = 5,
  temperature  = 0.7,
  instructions = instructions_threat,
  reminder     = reminder_threat,
  model        = API_MODEL,
  host         = API_HOST,
  api_key      = API_KEY,
  backend      = API_BACKEND
)

# Clean labels and sort by agreement ascending (lowest first)
hard_threat <- hard_threat %>%
  mutate(majority_label = sapply(majority_label, clean_label)) %>%
  arrange(agreement)

t_threat <- round(as.numeric(difftime(Sys.time(), t_start, units="mins")), 2)
write_csv(hard_threat, "outputs/step2_2/hard_threat_200.csv")

# ── BENEFIT hard cases ────────────────────────────────────────
cat("\n--- Running BENEFIT hard-case detection (briseus) ---\n")
b_start <- Sys.time()

hard_benefit <- briseus(
  sample_200,
  input_column = "text_block_english",
  n_runs       = 5,
  temperature  = 0.7,
  instructions = instructions_benefit,
  reminder     = reminder_benefit,
  model        = API_MODEL,
  host         = API_HOST,
  api_key      = API_KEY,
  backend      = API_BACKEND
)

# Clean labels and sort by agreement ascending
hard_benefit <- hard_benefit %>%
  mutate(majority_label = sapply(majority_label, clean_label)) %>%
  arrange(agreement)

t_benefit <- round(as.numeric(difftime(Sys.time(), b_start, units="mins")), 2)
write_csv(hard_benefit, "outputs/step2_2/hard_benefit_200.csv")

# ── Summary ───────────────────────────────────────────────────
cat("\n=== STEP 2.2 COMPLETE ===\n")
cat("Hard cases identified for Threat:", sum(hard_threat$agreement < 1.0), "\n")
cat("Hard cases identified for Benefit:", sum(hard_benefit$agreement < 1.0), "\n")
cat("Outputs saved to outputs/step2_2/\n")
cat("Runtime: Threat =", t_threat, "min | Benefit =", t_benefit, "min\n")
