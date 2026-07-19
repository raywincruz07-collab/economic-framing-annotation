rm(list = ls())
source("config.R", encoding = "UTF-8")
source("scripts/utils.R", encoding = "UTF-8")

# Ensure output directories exist
dir.create("outputs/step3_2", recursive = TRUE, showWarnings = FALSE)
dir.create("reports/classification_reports", recursive = TRUE, showWarnings = FALSE)

suppressPackageStartupMessages({
  library(httr2)
  library(jsonlite)
  library(readr)
  library(dplyr)
  library(progress)
})

# Custom robust annotation function
annotate_direct <- function(df, instructions, examples, codes, explanations, reminder, model, host, api_key) {
  
  results <- list()
  pb <- progress_bar$new(format = "  [:bar] :current/:total (:percent) in :elapsed ETA: :eta", 
                         total = nrow(df), clear = FALSE, width = 60)
  
  # Format examples once
  example_msgs <- list()
  for(i in seq_along(examples)) {
    example_msgs[[length(example_msgs)+1]] <- list(role = "user", content = paste0("Text: '", examples[i], "'"))
    example_content <- paste0(ifelse(!is.na(explanations[i]), paste0("Explanation: ", explanations[i], "\n"), ""), "Label: ", codes[i])
    example_msgs[[length(example_msgs)+1]] <- list(role = "assistant", content = example_content)
  }
  
  for(i in 1:nrow(df)) {
    messages <- c(
      list(list(role = "system", content = instructions)),
      example_msgs,
      list(list(role = "user", content = paste0("Text: '", df$text_block_english[i], "'\nReminder: ", reminder)))
    )
    
    body <- list(model = model, messages = messages, temperature = 0.2)
    
    success <- FALSE
    attempts <- 0
    while(!success && attempts < 3) {
      attempts <- attempts + 1
      tryCatch({
        req <- request(paste0(host, "/chat/completions")) %>%
          req_headers(Authorization = paste0("Bearer ", api_key)) %>%
          req_body_json(body) %>%
          req_timeout(120) # Increase timeout to 2 mins
          
        resp <- req_perform(req)
        res_json <- resp_body_json(resp)
        txt <- res_json$choices[[1]]$message$content
        
        # Parse label and explanation using config helpers
        label <- clean_label(txt)
        explanation <- stringr::str_match(txt, "Explanation:\\s*((?s).*?)(?=\\nLabel:|\\n*$)")[, 2]
        
        results[[i]] <- list(row_num = df$row_num[i], labels = label, explanation = explanation, raw = txt)
        success <- TRUE
      }, error = function(e) {
        cat("\nAttempt", attempts, "failed for row", df$row_num[i], ":", e$message, "\n")
        if (attempts < 3) Sys.sleep(5)
      })
    }
    
    if (!success) {
      results[[i]] <- list(row_num = df$row_num[i], labels = NA_character_, explanation = "FAILED AFTER 3 ATTEMPTS", raw = NA_character_)
    }
    pb$tick()
  }
  
  bind_rows(results)
}

# Note: clean_text_api moved to scripts/utils.R

# ── LOAD DATA ──────────────────────────────────────────────────
gold <- read_csv(GOLD_FILE, show_col_types = FALSE) %>%
  filter(!is.na(threat_human), !is.na(benefit_human)) %>%
  mutate(text_block_english = clean_text_api(text_block_english))

# Clean examples
fewshot_threat_starter <- fewshot_threat_starter %>%
  mutate(input = clean_text_api(input), explanation = clean_text_api(explanation))
fewshot_benefit_starter <- fewshot_benefit_starter %>%
  mutate(input = clean_text_api(input), explanation = clean_text_api(explanation))

cat("Validation rows:", nrow(gold), "\n")

# ── RUN THREAT ─────────────────────────────────────────────────
cat("\n--- Running THREAT few-shot + CoT (Fixed Script) ---\n")
threat_res <- annotate_direct(
  gold,
  instructions = instructions_threat_cot,
  examples     = fewshot_threat_starter$input,
  codes        = fewshot_threat_starter$label,
  explanations = fewshot_threat_starter$explanation,
  reminder     = reminder_threat_cot,
  model        = API_MODEL,
  host         = API_HOST,
  api_key      = API_KEY
)

# ── RUN BENEFIT ────────────────────────────────────────────────
cat("\n--- Running BENEFIT few-shot + CoT (Fixed Script) ---\n")
benefit_res <- annotate_direct(
  gold,
  instructions = instructions_benefit_cot,
  examples     = fewshot_benefit_starter$input,
  codes        = fewshot_benefit_starter$label,
  explanations = fewshot_benefit_starter$explanation,
  reminder     = reminder_benefit_cot,
  model        = API_MODEL,
  host         = API_HOST,
  api_key      = API_KEY
)

# ── SAVE RESULTS ───────────────────────────────────────────────
final <- gold %>%
  left_join(threat_res %>% select(row_num, threat_llm_few = labels, threat_expl_few = explanation), by = "row_num") %>%
  left_join(benefit_res %>% select(row_num, benefit_llm_few = labels, benefit_expl_few = explanation), by = "row_num")

write_csv(final, "outputs/step3_2/out_step3_2_fewshot_validation.csv")
cat("\nResults saved to outputs/step3_2/out_step3_2_fewshot_validation.csv\n")

# ── COMPUTE METRICS ────────────────────────────────────────────
cat("\n--- Classification Report (Few-shot + CoT) ---\n")

clean_res <- final %>%
  mutate(
    threat_llm_few  = sapply(threat_llm_few, clean_label),
    benefit_llm_few = sapply(benefit_llm_few, clean_label)
  )

t_metrics <- caret::confusionMatrix(
  factor(clean_res$threat_llm_few, levels = c("YES", "NO")),
  factor(clean_res$threat_human, levels = c("YES", "NO")),
  positive = "YES"
)

b_metrics <- caret::confusionMatrix(
  factor(clean_res$benefit_llm_few, levels = c("YES", "NO")),
  factor(clean_res$benefit_human, levels = c("YES", "NO")),
  positive = "YES"
)

cat("\nTHREAT Metrics:\n")
print(t_metrics$byClass[c("Precision", "Recall", "F1")])

cat("\nBENEFIT Metrics:\n")
print(b_metrics$byClass[c("Precision", "Recall", "F1")])
