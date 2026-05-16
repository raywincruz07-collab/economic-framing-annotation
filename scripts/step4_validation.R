rm(list = ls())
source("config.R", encoding = "UTF-8")
source("scripts/utils.R", encoding = "UTF-8")

# Ensure output directories exist
dir.create("outputs/step4", recursive = TRUE, showWarnings = FALSE)
dir.create("reports/classification_reports", recursive = TRUE, showWarnings = FALSE)

suppressPackageStartupMessages({
  library(bacchuss)
  library(readr)
  library(dplyr)
  library(caret)
  library(irr)
})

# ── Load human gold validation labels ────────────────────────
VAL_GOLD <- "data/validation/human_gold_validation.csv"

if (!file.exists(VAL_GOLD)) {
  stop("Validation gold standard not found. Please create data/validation/human_gold_validation.csv first.")
}

human_gold <- read_csv(VAL_GOLD, show_col_types = FALSE) %>%
  mutate(text_block_english = clean_text_api(text_block_english))

# ── THREAT: LLM pass ─────────────────────────────────────────
cat("\n--- Running THREAT validation pass ---\n")
llm_val_threat <- bacchuss(
  human_gold,
  input_column = "text_block_english",
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
write_csv(llm_val_threat, "outputs/step4/llm_val_threat.csv")

# ── BENEFIT: LLM pass ────────────────────────────────────────
cat("\n--- Running BENEFIT validation pass ---\n")
llm_val_benefit <- bacchuss(
  human_gold,
  input_column = "text_block_english",
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
write_csv(llm_val_benefit, "outputs/step4/llm_val_benefit.csv")

# ── Metrics ───────────────────────────────────────────────────
cat("\n=== STEP 4: THREAT LLM vs HUMAN ===\n")
merged_t <- llm_val_threat %>%
  mutate(llm   = factor(clean_label(labels),           levels=c("YES","NO")),
         human = factor(toupper(trimws(threat_human)), levels=c("YES","NO")))
print(confusionMatrix(merged_t$llm, merged_t$human, positive="YES", mode="prec_recall"))

cat("\n=== STEP 4: BENEFIT LLM vs HUMAN ===\n")
merged_b <- llm_val_benefit %>%
  mutate(llm   = factor(clean_label(labels),            levels=c("YES","NO")),
         human = factor(toupper(trimws(benefit_human)), levels=c("YES","NO")))
print(confusionMatrix(merged_b$llm, merged_b$human, positive="YES", mode="prec_recall"))
