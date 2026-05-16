# ============================================================
# scripts/check_project_integrity.R
# Validates the project structure and readiness for submission.
# ============================================================

library(readr)

failures <- character()

check_file <- function(path) {
  if (!file.exists(path)) failures <<- c(failures, paste("Missing file:", path))
}

check_dir <- function(path) {
  if (!dir.exists(path)) failures <<- c(failures, paste("Missing folder:", path))
}

required_dirs <- c(
  "scripts", "data", "data/raw", "data/samples", "data/fewshot",
  "data/validation", "outputs", "outputs/step5", "reports", "docs", "references"
)

required_files <- c(
  "README.md",
  "config.R",
  "scripts/utils.R",
  "scripts/step0_draw_sample.R",
  "scripts/step2_1_zeroshot.R",
  "scripts/step2_2_hardcases.R",
  "scripts/step3_1_baseline.R",
  "scripts/step3_2_fewshot_cot.R",
  "scripts/step3_3_hardcases_few.R",
  "scripts/step4_validation.R",
  "scripts/step5_full_annotation.R",
  "scripts/step6_report.R",
  "data/raw/dataset_10k_translated.csv",
  "outputs/step5/final_annotated_10k.csv",
  "outputs/step5/spot_check_50rows.csv",
  "reports/prompt_version_log.csv",
  "docs/METHODOLOGY.md"
)

invisible(lapply(required_dirs, check_dir))
invisible(lapply(required_files, check_file))

if (file.exists("outputs/step5/final_annotated_10k.csv")) {
  final <- read_csv("outputs/step5/final_annotated_10k.csv", show_col_types = FALSE)
  if (nrow(final) != 10000) failures <- c(failures, paste("Final output row count is not 10000:", nrow(final)))

  expected_cols <- c(
    "article_id", "pub", "par_index", "group", "length",
    "text_block_german", "text_block_english", "row_num",
    "threat_label", "threat_expl", "benefit_label", "benefit_expl", "frame_type"
  )

  missing_cols <- setdiff(expected_cols, names(final))
  if (length(missing_cols) > 0) failures <- c(failures, paste("Missing final columns:", paste(missing_cols, collapse = ", ")))
}

files_to_scan <- list.files(".", recursive = TRUE, full.names = TRUE, all.files = TRUE)
files_to_scan <- files_to_scan[!grepl("^./.git/|/.git/|^./reports/|/reports/", files_to_scan)]
files_to_scan <- files_to_scan[!grepl("\\.pdf$|\\.csv$|\\.RDS$|\\.rds$", files_to_scan, ignore.case = TRUE)]

for (f in files_to_scan) {
  if (file.info(f)$isdir) next
  txt <- tryCatch(readLines(f, warn = FALSE, encoding = "UTF-8"), error = function(e) character())
  if (any(grepl("sk-[A-Za-z0-9_-]+", txt))) {
    failures <- c(failures, paste("Possible hard-coded API key in:", f))
  }
}

if (length(failures) == 0) {
  cat("PROJECT INTEGRITY CHECK PASSED\n")
} else {
  cat("PROJECT INTEGRITY CHECK FAILED\n")
  cat(paste0("- ", failures, collapse = "\n"), "\n")
  # We don't quit with error here to allow the agent to continue, but we log it.
}
