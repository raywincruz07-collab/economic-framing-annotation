rm(list = ls())
source("config.R", encoding = "UTF-8")
source("scripts/utils.R", encoding = "UTF-8")

# Ensure output directories exist
dir.create("outputs/step5", recursive = TRUE, showWarnings = FALSE)

suppressPackageStartupMessages({
  library(bacchuss)
  library(readr)
  library(dplyr)
})

# ── Config ────────────────────────────────────────────────────
CHECKPOINT_THREAT  <- "checkpoint_step4_threat.rds"
CHECKPOINT_BENEFIT <- "checkpoint_step4_benefit.rds"
CHECKPOINT_EVERY   <- 200
LOG_FILE           <- "step4_annotation.log"

append_note <- function(text) {
  write(text, file = NOTES_FILE, append = TRUE)
  cat(text, "\n")
}
log_msg <- function(...) {
  msg <- paste0("[", format(Sys.time(), "%Y-%m-%d %H:%M:%S"), "] ", ...)
  cat(msg, "\n")
  write(msg, file = LOG_FILE, append = TRUE)
}
ts <- function() format(Sys.time(), "%Y-%m-%d %H:%M:%S")

# ── Load few-shot examples ────────────────────────────────────
few <- read_csv(FEWSHOT_FILE, show_col_types = FALSE)
few_threat_codes  <- ifelse(few$threat_label  == "YES", "YES", "NO")
few_benefit_codes <- ifelse(few$benefit_label == "YES", "YES", "NO")

# ── Load full dataset ─────────────────────────────────────────
log_msg("Loading 10K dataset...")
data_all <- read_csv(INPUT_FILE, show_col_types = FALSE) %>%
  mutate(text_block_english = clean_text_api(text_block_english))
log_msg(paste("Loaded", nrow(data_all), "rows"))

# ============================================================
# THREAT PASS
# ============================================================
log_msg("=== STARTING THREAT PASS ===")

start_threat <- 1
df_threat    <- data_all
df_threat$threat_label  <- NA_character_
df_threat$threat_expl   <- NA_character_
df_threat$threat_status <- NA_character_

if (file.exists(CHECKPOINT_THREAT)) {
  log_msg("Threat checkpoint found — resuming...")
  cp <- readRDS(CHECKPOINT_THREAT)
  df_threat    <- cp$df
  start_threat <- cp$next_row
  log_msg(paste("Resuming threat from row", start_threat))
}

job_start <- Sys.time()
for (i in start_threat:nrow(df_threat)) {
  if (!is.na(df_threat$threat_label[i])) next

  result <- tryCatch({
    bacchuss(
      df_threat[i, ],
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
  }, error = function(e) {
    log_msg(paste("ERROR row", i, ":", conditionMessage(e)))
    NULL
  })

  if (!is.null(result) && nrow(result) > 0) {
    df_threat$threat_label[i]  <- clean_label(result$labels[1])
    df_threat$threat_expl[i]   <- if ("explanations" %in% names(result)) result$explanations[1] else NA_character_
    df_threat$threat_status[i] <- "OK"
  } else {
    df_threat$threat_status[i] <- "FAILED"
  }

  if (i %% 10 == 0 || i == nrow(df_threat)) {
    elapsed <- as.numeric(difftime(Sys.time(), job_start, units="mins"))
    done    <- i - start_threat + 1
    rate    <- done / elapsed
    eta     <- (nrow(df_threat) - i) / rate
    log_msg(sprintf("THREAT row %d/%d | OK:%d | Failed:%d | Elapsed:%.1f min | ETA:%.1f min",
                    i, nrow(df_threat),
                    sum(df_threat$threat_status=="OK", na.rm=TRUE),
                    sum(df_threat$threat_status=="FAILED", na.rm=TRUE),
                    elapsed, eta))
  }

  if (i %% CHECKPOINT_EVERY == 0) {
    saveRDS(list(df=df_threat, next_row=i+1), CHECKPOINT_THREAT)
    log_msg(paste("Threat checkpoint saved at row", i))
  }
}

write_csv(df_threat %>% select(row_num, threat_label, threat_expl, threat_status),
          "outputs/step5/out_step5_threat_labels.csv")
log_msg("=== THREAT PASS COMPLETE ===")
log_msg(paste("Threat OK:", sum(df_threat$threat_status=="OK", na.rm=TRUE),
              "| Failed:", sum(df_threat$threat_status=="FAILED", na.rm=TRUE)))
if (file.exists(CHECKPOINT_THREAT)) file.remove(CHECKPOINT_THREAT)

# ============================================================
# BENEFIT PASS
# ============================================================
log_msg("=== STARTING BENEFIT PASS ===")

start_benefit <- 1
df_benefit    <- data_all
df_benefit$benefit_label  <- NA_character_
df_benefit$benefit_expl   <- NA_character_
df_benefit$benefit_status <- NA_character_

if (file.exists(CHECKPOINT_BENEFIT)) {
  log_msg("Benefit checkpoint found — resuming...")
  cp <- readRDS(CHECKPOINT_BENEFIT)
  df_benefit    <- cp$df
  start_benefit <- cp$next_row
  log_msg(paste("Resuming benefit from row", start_benefit))
}

job_start <- Sys.time()
for (i in start_benefit:nrow(df_benefit)) {
  if (!is.na(df_benefit$benefit_label[i])) next

  result <- tryCatch({
    bacchuss(
      df_benefit[i, ],
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
  }, error = function(e) {
    log_msg(paste("ERROR row", i, ":", conditionMessage(e)))
    NULL
  })

  if (!is.null(result) && nrow(result) > 0) {
    df_benefit$benefit_label[i]  <- clean_label(result$labels[1])
    df_benefit$benefit_expl[i]   <- if ("explanations" %in% names(result)) result$explanations[1] else NA_character_
    df_benefit$benefit_status[i] <- "OK"
  } else {
    df_benefit$benefit_status[i] <- "FAILED"
  }

  if (i %% 10 == 0 || i == nrow(df_benefit)) {
    elapsed <- as.numeric(difftime(Sys.time(), job_start, units="mins"))
    done    <- i - start_benefit + 1
    rate    <- done / elapsed
    eta     <- (nrow(df_benefit) - i) / rate
    log_msg(sprintf("BENEFIT row %d/%d | OK:%d | Failed:%d | Elapsed:%.1f min | ETA:%.1f min",
                    i, nrow(df_benefit),
                    sum(df_benefit$benefit_status=="OK", na.rm=TRUE),
                    sum(df_benefit$benefit_status=="FAILED", na.rm=TRUE),
                    elapsed, eta))
  }

  if (i %% CHECKPOINT_EVERY == 0) {
    saveRDS(list(df=df_benefit, next_row=i+1), CHECKPOINT_BENEFIT)
    log_msg(paste("Benefit checkpoint saved at row", i))
  }
}

write_csv(df_benefit %>% select(row_num, benefit_label, benefit_expl, benefit_status),
          "outputs/step5/out_step5_benefit_labels.csv")
log_msg("=== BENEFIT PASS COMPLETE ===")
log_msg(paste("Benefit OK:", sum(df_benefit$benefit_status=="OK", na.rm=TRUE),
              "| Failed:", sum(df_benefit$benefit_status=="FAILED", na.rm=TRUE)))
if (file.exists(CHECKPOINT_BENEFIT)) file.remove(CHECKPOINT_BENEFIT)

# ============================================================
# MERGE FINAL DATASET
# ============================================================
final <- data_all %>%
  left_join(df_threat  %>% select(row_num, threat_label,  threat_expl),  by="row_num") %>%
  left_join(df_benefit %>% select(row_num, benefit_label, benefit_expl), by="row_num") %>%
  mutate(
    frame_type = case_when(
      threat_label=="YES" & benefit_label=="YES" ~ "BOTH",
      threat_label=="YES" & benefit_label=="NO"  ~ "THREAT_ONLY",
      threat_label=="NO"  & benefit_label=="YES" ~ "BENEFIT_ONLY",
      threat_label=="NO"  & benefit_label=="NO"  ~ "NEITHER",
      TRUE ~ "UNKNOWN"
    )
  )

write_csv(final, "outputs/step5/final_annotated_10k.csv")
log_msg("Final annotated dataset saved: outputs/step5/final_annotated_10k.csv")
log_msg(paste("Frame distribution:", paste(table(final$frame_type), collapse=" | ")))
log_msg("=== STEP 4 ALL COMPLETE ===")

# ── Append to project notes ───────────────────────────────────
frame_tab <- table(final$frame_type)
threat_pct  <- round(100 * sum(final$threat_label  == "YES", na.rm=TRUE) / nrow(final), 1)
benefit_pct <- round(100 * sum(final$benefit_label == "YES", na.rm=TRUE) / nrow(final), 1)

append_note(paste0("\n---\n\n## Step 4 — Full 10,000-Row Annotation (", ts(), ")\n"))
append_note("**Routine ref:** Freudenthaler routine.md §Step 4\n")
append_note(paste0("**Prompt used:** Few-shot + Chain-of-Thought (best validated in Step 3.2)\n"))
append_note(paste0("**Method:** ", API_MODEL, " | Rows annotated: ", nrow(final), "\n"))

append_note("\n### Frame Distribution (Full 10K)")
append_note("| Frame Type    | Count | % |")
append_note("|---------------|-------|---|")
for (nm in names(frame_tab)) {
  append_note(sprintf("| %-13s | %5d | %.1f%% |",
                      nm, frame_tab[nm], 100*frame_tab[nm]/nrow(final)))
}
append_note(paste0("\n**Threat YES:** ", threat_pct,
                   "% | **Benefit YES:** ", benefit_pct, "%\n"))
append_note("**Output:** `out_step4_final_annotated.csv`\n")
append_note("**Next:** Run step5_report.R for final statistics.\n")

cat("\n=== ALL ANNOTATION COMPLETE ===\n")
cat("Final file: out_step4_final_annotated.csv\n")
cat("Next: Run step5_report.R\n")
