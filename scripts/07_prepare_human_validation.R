rm(list = ls())

library(digest)

# Helper function to generate hashes
get_hash <- function(filepath) {
  if(file.exists(filepath)) {
    return(digest(file = filepath, algo = "sha256"))
  } else {
    return(NA)
  }
}

# 1. Read source
raw_path <- "data/raw/dataset_10k_translated.csv"
raw_data <- read.csv(raw_path, stringsAsFactors = FALSE)

# 2. Confirm basic requirements
if(nrow(raw_data) != 10000) stop("Source dataset does not have exactly 10,000 rows.")
if(any(is.na(raw_data$row_num) | raw_data$row_num == "")) stop("row_num contains missing values.")
if(length(unique(raw_data$row_num)) != 10000) stop("row_num is not perfectly unique.")

# 3. Read exclusions
s200 <- read.csv("data/samples/sample_200.csv", stringsAsFactors = FALSE)
g200 <- read.csv("data/samples/gold_200.csv", stringsAsFactors = FALSE)
hvs <- read.csv("data/validation/human_validation_sample.csv", stringsAsFactors = FALSE)
hgv <- read.csv("data/validation/human_gold_validation.csv", stringsAsFactors = FALSE)

# 4. Deduplicate exclusion IDs
exclusion_ids <- unique(c(s200$row_num, g200$row_num, hvs$row_num, hgv$row_num))

# 5. Confirm 400 unique
if(length(exclusion_ids) != 400) stop(paste("Exclusion set does not contain exactly 400 unique row_nums. Found:", length(exclusion_ids)))

# 6. Exclude rows
eligible_data <- raw_data[!(raw_data$row_num %in% exclusion_ids), ]

# 7. Confirm 9600
if(nrow(eligible_data) != 9600) stop(paste("Eligible pool does not contain exactly 9,600 rows. Found:", nrow(eligible_data)))

# 8. Set seed
set.seed(1002)

# 9. Draw 1002 rows
sample_idx <- sample(seq_len(nrow(eligible_data)), 1002, replace = FALSE)
sample_1002 <- eligible_data[sample_idx, ]

# 10. Do not use forbidden fields
cols_to_keep <- c("row_num", "article_id", "pub", "par_index", "group", "length", "text_block_german", "text_block_english")
# 11. Preserve row_num (included above)
master_sample <- sample_1002[, cols_to_keep]

# 12. Randomize order
final_order <- sample(seq_len(nrow(master_sample)), nrow(master_sample), replace = FALSE)
master_sample <- master_sample[final_order, ]

# 13. Create sample IDs
master_sample$sample_id <- sprintf("EF%04d", 1:1002)

# 14. Assign blocks
master_sample$block <- NA
master_sample$block[1:334] <- "Part A"
master_sample$block[335:668] <- "Part B"
master_sample$block[669:1002] <- "Part C"

# Reorder columns
master_sample <- master_sample[, c("sample_id", "row_num", "article_id", "pub", "par_index", "group", "length", "text_block_german", "text_block_english", "block")]

# Save Master files
write.csv(master_sample, "data/manual_annotation_1002/master/sample_1002_master.csv", row.names = FALSE)
write.csv(master_sample[master_sample$block == "Part A", ], "data/manual_annotation_1002/master/part_A_334.csv", row.names = FALSE)
write.csv(master_sample[master_sample$block == "Part B", ], "data/manual_annotation_1002/master/part_B_334.csv", row.names = FALSE)
write.csv(master_sample[master_sample$block == "Part C", ], "data/manual_annotation_1002/master/part_C_334.csv", row.names = FALSE)
write.csv(data.frame(row_num = exclusion_ids), "data/manual_annotation_1002/master/excluded_previous_400_row_nums.csv", row.names = FALSE)

# Create Manifest
manifest <- data.frame(
  metric = c("source_dataset", "source_row_count", "exclusion_row_count", "eligible_row_count", "sampling_seed", "sample_row_count", "block_sizes", "creation_timestamp", "source_hash_sha256", "master_hash_sha256"),
  value = c(raw_path, nrow(raw_data), length(exclusion_ids), nrow(eligible_data), 1002, nrow(master_sample), 334, as.character(Sys.time()), get_hash(raw_path), get_hash("data/manual_annotation_1002/master/sample_1002_master.csv")),
  stringsAsFactors = FALSE
)
write.csv(manifest, "data/manual_annotation_1002/master/sampling_manifest.csv", row.names = FALSE)


# STEP 4 & 5 - Create Coder CSV Files
# Function to generate blank coder files
generate_coder_blank <- function(block_letter, block_data) {
  df <- data.frame(
    sample_id = block_data$sample_id,
    row_num = block_data$row_num,
    article_id = block_data$article_id,
    pub = block_data$pub,
    par_index = block_data$par_index,
    group = block_data$group,
    text_block_german = block_data$text_block_german,
    text_block_english = block_data$text_block_english,
    economic_threat = NA,
    threat_criterion = NA,
    threat_uncertain = NA,
    economic_benefit = NA,
    benefit_criterion = NA,
    benefit_uncertain = NA,
    coder_note = NA,
    stringsAsFactors = FALSE
  )
  return(df)
}

part_A <- master_sample[master_sample$block == "Part A", ]
part_B <- master_sample[master_sample$block == "Part B", ]
part_C <- master_sample[master_sample$block == "Part C", ]

pravallika_A <- generate_coder_blank("A", part_A)
pravallika_C <- generate_coder_blank("C", part_C)
raywin_A <- generate_coder_blank("A", part_A)
raywin_B <- generate_coder_blank("B", part_B)
namrath_B <- generate_coder_blank("B", part_B)
namrath_C <- generate_coder_blank("C", part_C)

write.csv(pravallika_A, "data/manual_annotation_1002/coder_blank/pravallika/pravallika_part_A.csv", row.names = FALSE, na="")
write.csv(pravallika_C, "data/manual_annotation_1002/coder_blank/pravallika/pravallika_part_C.csv", row.names = FALSE, na="")
write.csv(raywin_A, "data/manual_annotation_1002/coder_blank/raywin/raywin_part_A.csv", row.names = FALSE, na="")
write.csv(raywin_B, "data/manual_annotation_1002/coder_blank/raywin/raywin_part_B.csv", row.names = FALSE, na="")
write.csv(namrath_B, "data/manual_annotation_1002/coder_blank/namrath/namrath_part_B.csv", row.names = FALSE, na="")
write.csv(namrath_C, "data/manual_annotation_1002/coder_blank/namrath/namrath_part_C.csv", row.names = FALSE, na="")

# STEP 8 - Coder Assignment Manifest
coder_assignments <- data.frame(
  coder = c("Pravallika", "Pravallika", "Raywin", "Raywin", "Namrath", "Namrath"),
  block = c("Part A", "Part C", "Part A", "Part B", "Part B", "Part C"),
  row_count = c(334, 334, 334, 334, 334, 334),
  csv_file = c("pravallika_part_A.csv", "pravallika_part_C.csv", "raywin_part_A.csv", "raywin_part_B.csv", "namrath_part_B.csv", "namrath_part_C.csv"),
  xlsx_file = c("pravallika_part_A.xlsx", "pravallika_part_C.xlsx", "raywin_part_A.xlsx", "raywin_part_B.xlsx", "namrath_part_B.xlsx", "namrath_part_C.xlsx")
)
write.csv(coder_assignments, "data/manual_annotation_1002/master/coder_assignment_manifest.csv", row.names = FALSE)

# STEP 6 - Create Blinded Excel Workbooks
if(requireNamespace("openxlsx", quietly = TRUE)) {
  library(openxlsx)
  
  generate_xlsx <- function(csv_path, xlsx_path) {
    df <- read.csv(csv_path, stringsAsFactors = FALSE, na.strings = character(0))
    # Replace character(0) NA representation with true NA for blank export
    is.na(df) <- df == "NA"
    
    wb <- createWorkbook()
    addWorksheet(wb, "Instructions")
    
    instructions <- c(
      "1. Threat and Benefit are coded independently.",
      "2. Use 1 when the frame explicitly occurs.",
      "3. Use 0 when the frame does not occur.",
      "4. A general economic topic is not automatically a frame.",
      "5. Code occurrence even when the author rejects or criticizes the frame.",
      "6. Legal permission to work is not automatically Economic Benefit.",
      "7. Accommodation is not automatically Economic Threat unless explicit cost, overload, capacity or financial pressure is stated.",
      "8. Statistics alone are not a frame unless connected to explicit economic harm or benefit.",
      "9. Do not consult another coder before submission.",
      "10. Do not use an LLM or automated classifier.",
      "11. Do not reorder, add or delete rows.",
      "12. Every row must receive both a Threat and Benefit label.",
      "13. Uncertainty may be marked, but a final 0 or 1 is still required.",
      "14. Save using the assigned filename."
    )
    writeData(wb, "Instructions", data.frame(Instructions = instructions))
    
    addWorksheet(wb, "Annotation")
    writeData(wb, "Annotation", df, headerStyle = createStyle(textDecoration = "bold"))
    
    # Formatting
    freezePane(wb, "Annotation", firstRow = TRUE)
    addFilter(wb, "Annotation", row = 1, cols = 1:ncol(df))
    setColWidths(wb, "Annotation", cols = 1:ncol(df), widths = "auto")
    setColWidths(wb, "Annotation", cols = which(names(df) %in% c("text_block_german", "text_block_english")), widths = 60)
    
    wrap_style <- createStyle(wrapText = TRUE, valign = "top")
    addStyle(wb, "Annotation", wrap_style, rows = 2:(nrow(df)+1), cols = which(names(df) %in% c("text_block_german", "text_block_english")), gridExpand = TRUE)
    
    # Validations
    v_01 <- c("0", "1")
    v_t_crit <- c("T1", "T2", "T3", "T4", "T5")
    v_b_crit <- c("B1", "B2", "B3", "B4", "B5")
    
    dataValidation(wb, "Annotation", cols = which(names(df) == "economic_threat"), rows = 2:(nrow(df)+1), type = "list", value = '"0,1"', allowBlank = TRUE)
    dataValidation(wb, "Annotation", cols = which(names(df) == "economic_benefit"), rows = 2:(nrow(df)+1), type = "list", value = '"0,1"', allowBlank = TRUE)
    dataValidation(wb, "Annotation", cols = which(names(df) == "threat_uncertain"), rows = 2:(nrow(df)+1), type = "list", value = '"0,1"', allowBlank = TRUE)
    dataValidation(wb, "Annotation", cols = which(names(df) == "benefit_uncertain"), rows = 2:(nrow(df)+1), type = "list", value = '"0,1"', allowBlank = TRUE)
    dataValidation(wb, "Annotation", cols = which(names(df) == "threat_criterion"), rows = 2:(nrow(df)+1), type = "list", value = '"T1,T2,T3,T4,T5"', allowBlank = TRUE)
    dataValidation(wb, "Annotation", cols = which(names(df) == "benefit_criterion"), rows = 2:(nrow(df)+1), type = "list", value = '"B1,B2,B3,B4,B5"', allowBlank = TRUE)
    
    saveWorkbook(wb, xlsx_path, overwrite = TRUE)
  }
  
  base_dir <- "data/manual_annotation_1002/coder_blank"
  generate_xlsx(file.path(base_dir, "pravallika", "pravallika_part_A.csv"), file.path(base_dir, "pravallika", "pravallika_part_A.xlsx"))
  generate_xlsx(file.path(base_dir, "pravallika", "pravallika_part_C.csv"), file.path(base_dir, "pravallika", "pravallika_part_C.xlsx"))
  generate_xlsx(file.path(base_dir, "raywin", "raywin_part_A.csv"), file.path(base_dir, "raywin", "raywin_part_A.xlsx"))
  generate_xlsx(file.path(base_dir, "raywin", "raywin_part_B.csv"), file.path(base_dir, "raywin", "raywin_part_B.xlsx"))
  generate_xlsx(file.path(base_dir, "namrath", "namrath_part_B.csv"), file.path(base_dir, "namrath", "namrath_part_B.xlsx"))
  generate_xlsx(file.path(base_dir, "namrath", "namrath_part_C.csv"), file.path(base_dir, "namrath", "namrath_part_C.xlsx"))
  
} else {
  cat("openxlsx is not available. CSVs created, Excel generation is pending.\n")
}
