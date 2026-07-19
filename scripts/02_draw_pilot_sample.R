# step0_draw_sample.R
# Draws a fixed 200-row sample for development.
rm(list = ls())
source("config.R", encoding = "UTF-8")
source("scripts/utils.R", encoding = "UTF-8")

# Create output directory
dir.create("data/samples", recursive = TRUE, showWarnings = FALSE)

library(readr)
library(dplyr)

set.seed(2101)
cat("Loading full dataset from:", INPUT_FILE, "\n")
data_full <- read_csv(INPUT_FILE, show_col_types = FALSE)

cat("Drawing 200-row sample...\n")
sample_200 <- data_full %>%
  sample_n(200) %>%
  mutate(row_num = row_number())

write_csv(sample_200, SAMPLE_200_FILE)
cat("Sample drawn:", nrow(sample_200), "rows saved to", SAMPLE_200_FILE, "\n")
