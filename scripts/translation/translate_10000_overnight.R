# ============================================================
# translate_10000_overnight.R
#
# Translates 10,000 rows from the dataset overnight.
# Features:
#   - Fixed random seed so the same 10K rows are always selected
#   - Auto-saves checkpoint every 100 rows
#   - Resumes from checkpoint if interrupted
#   - Per-row error handling (one failure won't stop the job)
#   - Live progress log written to: translation_progress.log
#   - Final output saved to: out_translated_10000.csv
# ============================================================

library(readr)
library(dplyr)

source("../../config.R")
source("../utils_api.R")
check_api_config()

source("bacchuss_translate.R")

# ── CONFIG ──────────────────────────────────────────────────
N_ROWS        <- 10000
RANDOM_SEED   <- 42          # fixed seed → reproducible row selection
CHECKPOINT_EVERY <- 100      # save progress every N rows
CHECKPOINT_FILE  <- "checkpoint_10000.rds"
FINAL_OUTPUT     <- "out_translated_10000.csv"
LOG_FILE         <- "translation_progress.log"

# API config loaded from config.R
# ────────────────────────────────────────────────────────────

# Helper: write timestamped log
log_msg <- function(...) {
  msg <- paste0("[", format(Sys.time(), "%Y-%m-%d %H:%M:%S"), "] ", ...)
  cat(msg, "\n")
  write(msg, file = LOG_FILE, append = TRUE)
}

log_msg("=== TRANSLATION JOB STARTED ===")
log_msg(paste("Target rows:", N_ROWS, "| Checkpoint every:", CHECKPOINT_EVERY, "rows"))

# ── LOAD DATA ────────────────────────────────────────────────
log_msg("Loading full dataset (this may take ~10 seconds)...")
all_data <- readRDS("professor_dataset/share_dataset/all_multi_paragraphs_2022_2026.RDS")
log_msg(paste("Dataset loaded:", nrow(all_data), "total rows"))

# Sample 10,000 rows with fixed seed for reproducibility
set.seed(RANDOM_SEED)
sample_indices <- sample(1:nrow(all_data), N_ROWS)
df_to_translate <- all_data[sample_indices, ]
df_to_translate$row_num <- 1:N_ROWS  # track position

# Load translation prompt
system_prompt <- read_file("translate_prompt.txt")
log_msg("Prompt loaded.")

# ── RESUME FROM CHECKPOINT? ──────────────────────────────────
start_from <- 1
results_df <- df_to_translate
results_df$translated_texts  <- NA_character_
results_df$raw_output         <- NA_character_
results_df$max_context_used   <- NA_integer_
results_df$tokens_prompt      <- NA_integer_
results_df$tokens_response    <- NA_integer_
results_df$translation_status <- NA_character_

if (file.exists(CHECKPOINT_FILE)) {
  log_msg("Checkpoint found! Resuming from saved progress...")
  checkpoint <- readRDS(CHECKPOINT_FILE)
  results_df  <- checkpoint$results_df
  start_from  <- checkpoint$next_row
  log_msg(paste("Resuming from row", start_from, "of", N_ROWS))
} else {
  log_msg("No checkpoint found. Starting fresh.")
}

# ── MAIN TRANSLATION LOOP ────────────────────────────────────
job_start <- Sys.time()
log_msg(paste("Starting translation from row", start_from, "..."))

for (i in start_from:N_ROWS) {

  input_text <- results_df$text_block[i]

  # Skip if already translated (resume safety)
  if (!is.na(results_df$translated_texts[i])) {
    next
  }

  # Per-row error handling — one failure won't kill the job
  result <- tryCatch({
    bacchuss_translate_satyr(
      instructions           = system_prompt,
      reminder               = "Preserve names, numbers, and quotes exactly. Return only the translation. Do not comment on the translation.",
      input_text             = input_text,
      default_ctx            = 7680,
      model                  = API_MODEL,
      host                   = API_HOST,
      api_key                = API_KEY,
      backend                = API_BACKEND,
      expected_response_format = "plain",
      max_retries            = 3,
      retry_sleep            = 15
    )
  }, error = function(e) {
    log_msg(paste("ERROR on row", i, ":", conditionMessage(e)))
    list(text = NA_character_, raw_output = NA_character_,
         max_context_used = NA, tokens_prompt = NA, tokens_response = NA)
  })

  results_df$translated_texts[i]  <- result$text
  results_df$raw_output[i]        <- result$raw_output
  results_df$max_context_used[i]  <- result$max_context_used
  results_df$tokens_prompt[i]     <- result$tokens_prompt
  results_df$tokens_response[i]   <- result$tokens_response
  results_df$translation_status[i] <- ifelse(is.na(result$text), "FAILED", "OK")

  # ── Progress reporting ──
  if (i %% 10 == 0 || i == N_ROWS) {
    done        <- i - start_from + 1
    elapsed_min <- as.numeric(difftime(Sys.time(), job_start, units = "mins"))
    rate        <- done / elapsed_min          # rows per minute
    remaining   <- (N_ROWS - i) / rate         # minutes left
    pct         <- round(100 * i / N_ROWS, 1)
    n_ok        <- sum(results_df$translation_status == "OK",   na.rm = TRUE)
    n_fail      <- sum(results_df$translation_status == "FAILED", na.rm = TRUE)

    log_msg(sprintf(
      "Row %d/%d (%.1f%%) | OK: %d | Failed: %d | Elapsed: %.1f min | ETA: %.1f min",
      i, N_ROWS, pct, n_ok, n_fail, elapsed_min, remaining
    ))
  }

  # ── Checkpoint save ──
  if (i %% CHECKPOINT_EVERY == 0) {
    saveRDS(list(results_df = results_df, next_row = i + 1), CHECKPOINT_FILE)
    log_msg(paste("Checkpoint saved at row", i))
    # Also write partial CSV so you can inspect results any time
    write_csv(results_df[!is.na(results_df$translated_texts), ], 
              paste0("out_translated_partial_row", i, ".csv"))
  }
}

# ── FINAL SAVE ───────────────────────────────────────────────
total_time <- round(as.numeric(difftime(Sys.time(), job_start, units = "hours")), 2)
n_ok     <- sum(results_df$translation_status == "OK",    na.rm = TRUE)
n_failed <- sum(results_df$translation_status == "FAILED", na.rm = TRUE)

write_csv(results_df, FINAL_OUTPUT)

log_msg("=== JOB COMPLETE ===")
log_msg(paste("Total time     :", total_time, "hours"))
log_msg(paste("Rows translated:", n_ok, "/ 10000"))
log_msg(paste("Rows failed    :", n_failed))
log_msg(paste("Output saved to:", FINAL_OUTPUT))

# Clean up checkpoint on successful completion
if (file.exists(CHECKPOINT_FILE)) file.remove(CHECKPOINT_FILE)
log_msg("Checkpoint file removed. All done!")
