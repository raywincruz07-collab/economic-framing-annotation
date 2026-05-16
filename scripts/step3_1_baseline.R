rm(list = ls())
source("config.R", encoding = "UTF-8")
source("scripts/utils.R", encoding = "UTF-8")

# Ensure output directories exist
dir.create("outputs/step3_1", recursive = TRUE, showWarnings = FALSE)
dir.create("reports/classification_reports", recursive = TRUE, showWarnings = FALSE)

suppressPackageStartupMessages({
  library(bacchuss)
  library(readr)
  library(dplyr)
  library(caret)
})

append_note <- function(text) {
  write(text, file = NOTES_FILE, append = TRUE)
  cat(text, "\n")
}
ts <- function() format(Sys.time(), "%Y-%m-%d %H:%M:%S")

# ── Load gold standard ────────────────────────────────────────
cat("Loading gold standard...\n")

if (!file.exists(GOLD_FILE)) {
  stop(paste0(
    "Gold standard file not found: ", GOLD_FILE, "\n",
    "Please fill in gold_standard_10k.csv with your human labels first.\n",
    "Columns needed: row_num, threat_human (YES/NO), benefit_human (YES/NO)"
  ))
}

gold <- read_csv(GOLD_FILE, show_col_types = FALSE) %>%
  filter(!is.na(threat_human), !is.na(benefit_human)) %>%
  mutate(
    threat_human  = toupper(trimws(threat_human)),
    benefit_human = toupper(trimws(benefit_human))
  )

cat("Gold standard rows loaded:", nrow(gold), "\n")
if (nrow(gold) < 10) stop("Too few gold standard rows. Please label at least 10 rows.")

# ── Load full dataset and join to gold ────────────────────────
val_input <- gold
cat("Validation rows matched:", nrow(val_input), "\n")

# ── LLM annotation on gold rows — THREAT ─────────────────────
cat("\n--- Running THREAT annotation on gold rows ---\n")
t_start <- Sys.time()

val_threat <- bacchuss(
  val_input,
  input_column = "text_block_english",
  instructions = instructions_threat,
  reminder     = reminder_threat,
  explanations = TRUE,
  model        = API_MODEL,
  host         = API_HOST,
  api_key      = API_KEY,
  backend      = API_BACKEND
) %>%
  transmute(row_num,
            threat_llm  = sapply(labels, clean_label),
            threat_expl = if ("explanation" %in% names(.)) explanation else NA_character_)

t_threat <- round(as.numeric(difftime(Sys.time(), t_start, units="mins")), 1)

# ── LLM annotation on gold rows — BENEFIT ────────────────────
cat("\n--- Running BENEFIT annotation on gold rows ---\n")
b_start <- Sys.time()

val_benefit <- bacchuss(
  val_input,
  input_column = "text_block_english",
  instructions = instructions_benefit,
  reminder     = reminder_benefit,
  explanations = TRUE,
  model        = API_MODEL,
  host         = API_HOST,
  api_key      = API_KEY,
  backend      = API_BACKEND
) %>%
  transmute(row_num,
            benefit_llm  = sapply(labels, clean_label),
            benefit_expl = if ("explanation" %in% names(.)) explanation else NA_character_)

t_benefit <- round(as.numeric(difftime(Sys.time(), b_start, units="mins")), 1)

# ── Merge and compute metrics ─────────────────────────────────
eval_df <- gold %>%
  select(row_num, threat_human, benefit_human, text_block_english) %>%
  inner_join(val_threat,  by = "row_num") %>%
  inner_join(val_benefit, by = "row_num")

write_csv(eval_df, "outputs/step3_1/out_step3_validation.csv")
cat("\nValidation results saved: out_step3_validation.csv\n")

# ── Confusion matrix — THREAT ─────────────────────────────────
cat("\n=== THREAT CONFUSION MATRIX ===\n")
mt_threat <- table(
  LLM   = eval_df$threat_llm   == "YES",
  Human = eval_df$threat_human == "YES"
)
print(mt_threat)
cm_threat <- tryCatch(
  confusionMatrix(mt_threat, mode = "prec_recall", positive = "TRUE"),
  error = function(e) { cat("Could not compute threat metrics:", e$message, "\n"); NULL }
)
if (!is.null(cm_threat)) print(cm_threat)

# ── Confusion matrix — BENEFIT ────────────────────────────────
cat("\n=== BENEFIT CONFUSION MATRIX ===\n")
mt_benefit <- table(
  LLM   = eval_df$benefit_llm   == "YES",
  Human = eval_df$benefit_human == "YES"
)
print(mt_benefit)
cm_benefit <- tryCatch(
  confusionMatrix(mt_benefit, mode = "prec_recall", positive = "TRUE"),
  error = function(e) { cat("Could not compute benefit metrics:", e$message, "\n"); NULL }
)
if (!is.null(cm_benefit)) print(cm_benefit)

# ── Extract key metrics ───────────────────────────────────────
extract_metrics <- function(cm) {
  if (is.null(cm)) return(list(precision=NA, recall=NA, f1=NA, accuracy=NA))
  list(
    precision = round(cm$byClass["Precision"], 3),
    recall    = round(cm$byClass["Recall"],    3),
    f1        = round(cm$byClass["F1"],        3),
    accuracy  = round(cm$overall["Accuracy"],  3)
  )
}

m_threat  <- extract_metrics(cm_threat)
m_benefit <- extract_metrics(cm_benefit)

cat("\n=== ZERO-SHOT VALIDITY SUMMARY ===\n")
cat(sprintf("THREAT  — Precision: %.3f | Recall: %.3f | F1: %.3f | Accuracy: %.3f\n",
            m_threat$precision, m_threat$recall, m_threat$f1, m_threat$accuracy))
cat(sprintf("BENEFIT — Precision: %.3f | Recall: %.3f | F1: %.3f | Accuracy: %.3f\n",
            m_benefit$precision, m_benefit$recall, m_benefit$f1, m_benefit$accuracy))

threat_ok  <- !is.na(m_threat$f1)  && m_threat$f1  >= 0.80
benefit_ok <- !is.na(m_benefit$f1) && m_benefit$f1 >= 0.80

cat(sprintf("\nThreat  F1 ≥ 0.80: %s\n", ifelse(threat_ok,  "YES ✓", "NO → run step3_fewshot.R")))
cat(sprintf("Benefit F1 ≥ 0.80: %s\n", ifelse(benefit_ok, "YES ✓", "NO → run step3_fewshot.R")))

# ── Append to project notes ───────────────────────────────────
append_note(paste0("\n---\n\n## Step 3 — Zero-Shot Validation (", ts(), ")\n"))
append_note("**Routine ref:** Freudenthaler routine.md §Step 3\n")
append_note(paste0("**Gold standard rows:** ", nrow(eval_df),
                   " | **Method:** ", API_MODEL, "\n"))
append_note(paste0("**Runtime:** Threat=", t_threat, " min | Benefit=", t_benefit, " min\n"))

append_note("\n### Validity Metrics — Zero-Shot")
append_note("| Dimension | Precision | Recall | F1     | Accuracy |")
append_note("|-----------|-----------|--------|--------|----------|")
append_note(sprintf("| Threat    | %.3f     | %.3f  | %.3f  | %.3f    |",
                    m_threat$precision, m_threat$recall,
                    m_threat$f1, m_threat$accuracy))
append_note(sprintf("| Benefit   | %.3f     | %.3f  | %.3f  | %.3f    |",
                    m_benefit$precision, m_benefit$recall,
                    m_benefit$f1, m_benefit$accuracy))

append_note(paste0("\n**Threshold F1 ≥ 0.80:**"))
append_note(paste0("- Threat:  ", ifelse(threat_ok,  "PASSED ✓", "FAILED → proceed to step3_fewshot.R")))
append_note(paste0("- Benefit: ", ifelse(benefit_ok, "PASSED ✓", "FAILED → proceed to step3_fewshot.R")))

append_note("\n### Observations (fill in manually)")
append_note("- [ ] Which cases did the LLM get wrong?")
append_note("- [ ] Is there a systematic error (e.g., always codes hedged language wrong)?")
append_note("- [ ] Does few-shot seem necessary?\n")

cat("\n=== STEP 3 COMPLETE ===\n")
cat("Output: out_step3_validation.csv\n")
cat("Notes appended to: project_notes.md\n")
if (!threat_ok || !benefit_ok) {
  cat("⚠ F1 below 0.80 for one or both dimensions.\n")
  cat("Next: Run step3_2_fewshot.R to add few-shot + CoT\n")
} else {
  cat("✓ F1 ≥ 0.80 for both dimensions. Proceed to step4_full_annotation.R\n")
}
