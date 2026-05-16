# ============================================================
# test_translate_5rows.R
# Quick 5-row test to verify the translation pipeline works
# before running the full dataset.
# ============================================================

library(readr)

# Load the project configuration and API utilities
source("../../config.R")
source("../utils_api.R")
check_api_config()

# Load the translation engine
source("bacchuss_translate.R")

# Load the full dataset
cat("Loading dataset...\n")
all_multi_paragraphs_2022 <- readRDS("professor_dataset/share_dataset/all_multi_paragraphs_2022_2026.RDS")
cat(sprintf("Dataset loaded: %d rows, columns: %s\n", nrow(all_multi_paragraphs_2022), paste(names(all_multi_paragraphs_2022), collapse=", ")))

# Take only the first 5 rows for the test
test_5 <- all_multi_paragraphs_2022[1:5, ]

# Load the translation prompt
system_prompt <- read_file("translate_prompt.txt")
cat("Prompt loaded.\n")

# Run translation on 5 rows
cat("Starting translation test on 5 rows...\n")
translated <- bacchuss_translate(
  test_5,
  input_column  = "text_block",
  instructions  = system_prompt,
  reminder      = "Preserve names, numbers, and quotes exactly. Return only the translation. Do not comment on the translation.",
  default_ctx   = 7680,
  model         = API_MODEL,
  host          = API_HOST,
  api_key       = API_KEY,
  backend       = API_BACKEND,
  expected_response_format = "plain"
)

# Show results
cat("\n=== TRANSLATION RESULTS ===\n")
for (i in 1:nrow(translated)) {
  cat(sprintf("\n--- Row %d ---\n", i))
  cat(sprintf("ORIGINAL : %s\n", substr(translated$text_block[i], 1, 150)))
  cat(sprintf("TRANSLATED: %s\n", substr(translated$translated_texts[i], 1, 150)))
}

# Save test output
write_csv(translated, "out_test_translate_5rows.csv")
cat("\n\nTest output saved to: out_test_translate_5rows.csv\n")
cat("Test COMPLETE. Check the translations above before running the full 300-row job.\n")
