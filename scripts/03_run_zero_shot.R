rm(list = ls())
source("config.R", encoding = "UTF-8")
source("scripts/utils.R", encoding = "UTF-8")

# Ensure output directories exist
dir.create("outputs/step2_1", recursive = TRUE, showWarnings = FALSE)
dir.create("reports/classification_reports", recursive = TRUE, showWarnings = FALSE)

suppressPackageStartupMessages({
  library(bacchuss)
  library(readr)
  library(dplyr)
  library(caret)
})

# ── Load 200-row sample ──────────────────────────────────────
cat("Loading 200-row sample...\n")
sample_200 <- read_csv(SAMPLE_200_FILE, show_col_types = FALSE)
cat("Loaded:", nrow(sample_200), "rows\n")

# ── THREAT pass ──────────────────────────────────────────────
cat("\n--- Running THREAT zero-shot (200 rows) ---\n")
t_start <- Sys.time()

out_2_1_threat <- bacchuss(
  sample_200,
  input_column = "text_block_english",
  instructions = instructions_threat,
  reminder     = reminder_threat,
  model        = API_MODEL,
  host         = API_HOST,
  api_key      = API_KEY,
  backend      = API_BACKEND
)

t_threat <- round(as.numeric(difftime(Sys.time(), t_start, units="mins")), 2)
# Clean labels using v2 clean_label helper
out_2_1_threat <- out_2_1_threat %>%
  mutate(labels = sapply(labels, clean_label))
write_csv(out_2_1_threat, "outputs/step2_1/out_2_1_threat.csv")

cat("\nThreat label distribution:\n")
threat_counts <- out_2_1_threat %>% count(labels, sort = TRUE)
print(threat_counts)

# ── BENEFIT pass ─────────────────────────────────────────────
cat("\n--- Running BENEFIT zero-shot (200 rows) ---\n")
b_start <- Sys.time()

out_2_1_benefit <- bacchuss(
  sample_200,
  input_column = "text_block_english",
  instructions = instructions_benefit,
  reminder     = reminder_benefit,
  model        = API_MODEL,
  host         = API_HOST,
  api_key      = API_KEY,
  backend      = API_BACKEND
)

t_benefit <- round(as.numeric(difftime(Sys.time(), b_start, units="mins")), 2)
# Clean labels using v2 clean_label helper
out_2_1_benefit <- out_2_1_benefit %>%
  mutate(labels = sapply(labels, clean_label))
write_csv(out_2_1_benefit, "outputs/step2_1/out_2_1_benefit.csv")

cat("\nBenefit label distribution:\n")
benefit_counts <- out_2_1_benefit %>% count(labels, sort = TRUE)
print(benefit_counts)

# ── Mistyped label check ──────────────────────────────────────
valid_labels <- c("YES", "NO")
threat_invalid  <- out_2_1_threat  %>% filter(!toupper(labels) %in% valid_labels)
benefit_invalid <- out_2_1_benefit %>% filter(!toupper(labels) %in% valid_labels)

cat("\nInvalid threat labels:", nrow(threat_invalid), "\n")
cat("Invalid benefit labels:", nrow(benefit_invalid), "\n")

# ── Classification Report ─────────────────────────────────────
if (file.exists(GOLD_FILE)) {
  cat("\nFound gold_200.csv. Computing classification reports...\n")
  gold <- read_csv(GOLD_FILE, show_col_types = FALSE)
  
  # --- THREAT ---
  compare_threat <- out_2_1_threat %>%
    select(-threat_human, -benefit_human) %>% # Remove empty columns from input
    left_join(gold %>% select(row_num, threat_human), by = "row_num") %>%
    filter(!is.na(threat_human)) %>%
    mutate(
      llm   = factor(labels,                               levels = c("YES","NO")),
      human = factor(toupper(trimws(as.character(threat_human))), levels = c("YES","NO"))
    )
  
  cat("========================================\n")
  cat("STEP 2.1 — THREAT CLASSIFICATION REPORT\n")
  cat("========================================\n")
  cm_threat <- confusionMatrix(compare_threat$llm, compare_threat$human, positive = "YES", mode = "prec_recall")
  print(cm_threat)
  
  # Export summary
  sink("reports/classification_reports/step2_1_threat.txt")
  print(cm_threat)
  sink()
  
  # --- BENEFIT ---
  compare_benefit <- out_2_1_benefit %>%
    select(-threat_human, -benefit_human) %>% # Remove empty columns from input
    left_join(gold %>% select(row_num, benefit_human), by = "row_num") %>%
    filter(!is.na(benefit_human)) %>%
    mutate(
      llm   = factor(labels,                                levels = c("YES","NO")),
      human = factor(toupper(trimws(as.character(benefit_human))), levels = c("YES","NO"))
    )
  
  cat("=========================================\n")
  cat("STEP 2.1 — BENEFIT CLASSIFICATION REPORT\n")
  cat("=========================================\n")
  cm_benefit <- confusionMatrix(compare_benefit$llm, compare_benefit$human, positive = "YES", mode = "prec_recall")
  print(cm_benefit)
  
  # Export summary
  sink("reports/classification_reports/step2_1_benefit.txt")
  print(cm_benefit)
  sink()
  
} else {
  cat("\n========================================================================\n")
  cat("WARNING: ", GOLD_FILE, " not found.\n")
  cat("Skipping classification report (Precision/Recall/F1).\n")
  cat("Please manually annotate the 200 rows in sample_200.csv and save it as gold_200.csv\n")
  cat("to proceed with the evaluation as per the Senior Guide.\n")
  cat("========================================================================\n")
}

cat("\n=== STEP 2.1 ZERO-SHOT COMPLETE ===\n")
cat("Outputs saved to outputs/step2_1/\n")
