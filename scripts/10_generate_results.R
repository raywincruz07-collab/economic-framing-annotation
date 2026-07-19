rm(list = ls())
source("config.R", encoding = "UTF-8")
source("scripts/utils.R", encoding = "UTF-8")

# Ensure output directories exist
dir.create("outputs/step6", recursive = TRUE, showWarnings = FALSE)

suppressPackageStartupMessages({
  library(readr)
  library(dplyr)
  library(tidyr)
})

# Ensure output directory exists
if (!dir.exists("outputs/step6")) dir.create("outputs/step6", recursive = TRUE)

append_note <- function(text) {
  write(text, file = NOTES_FILE, append = TRUE)
  cat(text, "\n")
}
ts <- function() format(Sys.time(), "%Y-%m-%d %H:%M:%S")

# ── Load final annotated dataset ──────────────────────────────
cat("Loading final annotated dataset...\n")
final <- read_csv("outputs/step5/final_annotated_10k.csv", show_col_types = FALSE)
cat("Rows:", nrow(final), "\n")

# ── Overall frame distribution ─────────────────────────────────
total  <- nrow(final)
n_threat  <- sum(final$threat_label  == "YES", na.rm=TRUE)
n_benefit <- sum(final$benefit_label == "YES", na.rm=TRUE)
n_both    <- sum(final$frame_type == "BOTH",         na.rm=TRUE)
n_threat_only <- sum(final$frame_type == "THREAT_ONLY",  na.rm=TRUE)
n_benefit_only <- sum(final$frame_type == "BENEFIT_ONLY", na.rm=TRUE)
n_neither <- sum(final$frame_type == "NEITHER",       na.rm=TRUE)

cat("\n=== OVERALL FRAME DISTRIBUTION ===\n")
cat(sprintf("Total paragraphs      : %d\n", total))
cat(sprintf("Threat frame (YES)    : %d (%.1f%%)\n", n_threat,  100*n_threat/total))
cat(sprintf("Benefit frame (YES)   : %d (%.1f%%)\n", n_benefit, 100*n_benefit/total))
cat(sprintf("Both frames           : %d (%.1f%%)\n", n_both,    100*n_both/total))
cat(sprintf("Threat only           : %d (%.1f%%)\n", n_threat_only,  100*n_threat_only/total))
cat(sprintf("Benefit only          : %d (%.1f%%)\n", n_benefit_only, 100*n_benefit_only/total))
cat(sprintf("Neither frame         : %d (%.1f%%)\n", n_neither, 100*n_neither/total))

# ── By publication ────────────────────────────────────────────
cat("\n=== FRAME RATES BY PUBLICATION ===\n")
by_pub <- final %>%
  group_by(pub) %>%
  summarise(
    n          = n(),
    threat_pct = round(100 * sum(threat_label  == "YES", na.rm=TRUE) / n(), 1),
    benefit_pct = round(100 * sum(benefit_label == "YES", na.rm=TRUE) / n(), 1),
    both_pct    = round(100 * sum(frame_type == "BOTH", na.rm=TRUE) / n(), 1),
    neither_pct = round(100 * sum(frame_type == "NEITHER", na.rm=TRUE) / n(), 1),
    .groups = "drop"
  ) %>%
  arrange(desc(n))
print(by_pub, n=50)
write_csv(by_pub, "outputs/step6/by_publication.csv")

# ── Cross-tabulation ──────────────────────────────────────────
cat("\n=== CROSS-TABULATION: THREAT × BENEFIT ===\n")
xtab <- table(Threat=final$threat_label, Benefit=final$benefit_label)
print(xtab)

# ── Save full report text ─────────────────────────────────────
report_lines <- c(
  "# Final Annotation Report",
  paste0("Date: ", ts()),
  paste0("Dataset: ", INPUT_FILE, " | N = ", total),
  paste0("Method: ", API_MODEL),
  paste0("Inference: Structured Logic + reasoning"),
  "",
  "## Frame Distribution",
  sprintf("Threat frame      : %d / %d (%.1f%%)", n_threat,  total, 100*n_threat/total),
  sprintf("Benefit frame     : %d / %d (%.1f%%)", n_benefit, total, 100*n_benefit/total),
  sprintf("Both frames       : %d / %d (%.1f%%)", n_both,    total, 100*n_both/total),
  sprintf("Threat only       : %d / %d (%.1f%%)", n_threat_only,  total, 100*n_threat_only/total),
  sprintf("Benefit only      : %d / %d (%.1f%%)", n_benefit_only, total, 100*n_benefit_only/total),
  sprintf("Neither frame     : %d / %d (%.1f%%)", n_neither, total, 100*n_neither/total),
  "",
  "## Cross-tabulation: Threat × Benefit",
  capture.output(print(xtab)),
  "",
  "## By Publication",
  capture.output(print(as.data.frame(by_pub), row.names=FALSE))
)

writeLines(report_lines, "outputs/step6/final_report.txt")
cat("\nFull report saved: outputs/step6/final_report.txt\n")

# ── Append to project notes ───────────────────────────────────
append_note(paste0("\n---\n\n## Step 6 — Final Report Statistics (", ts(), ")\n"))
append_note("**Routine ref:** Freudenthaler routine.md §Step 4.3\n")

append_note("\n### Overall Frame Distribution")
append_note(paste0("| Frame          | N     | % |"))
append_note(paste0("|----------------|-------|---|"))
append_note(sprintf("| Threat (YES)   | %5d | %.1f%% |", n_threat,       100*n_threat/total))
append_note(sprintf("| Benefit (YES)  | %5d | %.1f%% |", n_benefit,      100*n_benefit/total))
append_note(sprintf("| Both           | %5d | %.1f%% |", n_both,         100*n_both/total))
append_note(sprintf("| Threat only    | %5d | %.1f%% |", n_threat_only,  100*n_threat_only/total))
append_note(sprintf("| Benefit only   | %5d | %.1f%% |", n_benefit_only, 100*n_benefit_only/total))
append_note(sprintf("| Neither        | %5d | %.1f%% |", n_neither,      100*n_neither/total))

append_note("\n**Outputs:** `outputs/step6/final_report.txt` | `outputs/step6/by_publication.csv`\n")
append_note("\n---\n\n## 🏁 Annotation Pipeline Complete\n")
append_note("All steps of the Freudenthaler bacchuss routine have been completed.\n")
append_note("Refer to `project_notes.md` for a complete log for your report Appendix.\n")

cat("\n=== STEP 6 COMPLETE — PROJECT DONE ===\n")
cat("project_notes.md contains your complete research log.\n")
