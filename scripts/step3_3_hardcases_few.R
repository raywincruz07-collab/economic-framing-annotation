rm(list = ls())
source("config.R", encoding = "UTF-8")
source("scripts/utils.R", encoding = "UTF-8")

# Ensure output directories exist
dir.create("outputs/step3_3", recursive = TRUE, showWarnings = FALSE)

suppressPackageStartupMessages({
  library(bacchuss)
  library(readr)
  library(dplyr)
})

# ── Load 200-row sample ──────────────────────────────────────
sample_200 <- read_csv(SAMPLE_200_FILE, show_col_types = FALSE) %>%
  mutate(text_block_english = clean_text_api(text_block_english))

# ── THREAT: 5 runs at temp 0.7 ────────────────────────────────
cat("\n--- Running THREAT hard-case check (briseus) ---\n")
hard_3_3_threat <- briseus(
  sample_200,
  input_column = "text_block_english",
  n_runs       = 5,
  temperature  = 0.7,
  instructions = instructions_threat_cot,
  examples     = fewshot_threat_starter$input,
  codes        = fewshot_threat_starter$label,
  explanations = fewshot_threat_starter$explanation,
  reminder     = reminder_threat_cot,
  model        = API_MODEL,
  host         = API_HOST,
  api_key      = API_KEY,
  backend      = API_BACKEND
)
write_csv(hard_3_3_threat, "outputs/step3_3/hard_3_3_threat.csv")

# ── BENEFIT: 5 runs at temp 0.7 ───────────────────────────────
cat("\n--- Running BENEFIT hard-case check (briseus) ---\n")
hard_3_3_benefit <- briseus(
  sample_200,
  input_column = "text_block_english",
  n_runs       = 5,
  temperature  = 0.7,
  instructions = instructions_benefit_cot,
  examples     = fewshot_benefit_starter$input,
  codes        = fewshot_benefit_starter$label,
  explanations = fewshot_benefit_starter$explanation,
  reminder     = reminder_benefit_cot,
  model        = API_MODEL,
  host         = API_HOST,
  api_key      = API_KEY,
  backend      = API_BACKEND
)
write_csv(hard_3_3_benefit, "outputs/step3_3/hard_3_3_benefit.csv")

cat("\nStep 3.3 complete. Residual hard cases (agreement < 1.0):\n")
cat("Threat:", sum(hard_3_3_threat$agreement < 1.0), "/ 200\n")
cat("Benefit:", sum(hard_3_3_benefit$agreement < 1.0), "/ 200\n")
