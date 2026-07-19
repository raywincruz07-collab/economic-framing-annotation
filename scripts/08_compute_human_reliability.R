
library(dplyr)
library(readr)
library(irr)
library(tidyr)

outputs_dir <- "outputs/reliability_1002"
long_df <- read_csv(file.path(outputs_dir, "human_annotations_long.csv"), show_col_types = FALSE)

# Pairwise
pairs <- list(
  Part_A = c("raywin", "pravallika"),
  Part_B = c("raywin", "namrath"),
  Part_C = c("namrath", "pravallika")
)

results <- data.frame()
conf_tables <- data.frame()
disagreements <- data.frame()

calc_metrics <- function(df, label_col) {
  df <- df %>% select(sample_id, coder, val = !!sym(label_col)) %>% pivot_wider(names_from = coder, values_from = val)
  coders <- colnames(df)[2:3]
  
  v1 <- as.numeric(df[[coders[1]]])
  v2 <- as.numeric(df[[coders[2]]])
  
  both_pos <- sum(v1 == 1 & v2 == 1, na.rm=T)
  both_neg <- sum(v1 == 0 & v2 == 0, na.rm=T)
  disag <- sum(v1 != v2, na.rm=T)
  n <- length(v1)
  
  pct_agr <- (both_pos + both_neg) / n
  pos_agr <- 2 * both_pos / (sum(v1==1, na.rm=T) + sum(v2==1, na.rm=T))
  neg_agr <- 2 * both_neg / (sum(v1==0, na.rm=T) + sum(v2==0, na.rm=T))
  
  k <- kappa2(df[, 2:3], weight="unweighted")
  
  return(list(
    n=n, pos1=sum(v1==1,na.rm=T), pos2=sum(v2==1,na.rm=T), both_pos=both_pos, both_neg=both_neg,
    disagreements=disag, pct_agr=pct_agr, pos_agr=pos_agr, neg_agr=neg_agr,
    kappa=k$value, expected_agr=NA
  ))
}

for (b in names(pairs)) {
  pair_df <- long_df %>% filter(block == b)
  for (lbl in c("economic_threat", "economic_benefit")) {
    m <- calc_metrics(pair_df, lbl)
    res <- data.frame(
      block=b, coder1=pairs[[b]][1], coder2=pairs[[b]][2], label=lbl,
      n=m$n, pos1=m$pos1, pos2=m$pos2, both_pos=m$both_pos, both_neg=m$both_neg,
      disagreements=m$disagreements, pct_agreement=m$pct_agr, pos_agreement=m$pos_agr,
      neg_agreement=m$neg_agr, cohens_kappa=m$kappa
    )
    results <- bind_rows(results, res)
    
    # Identify disagreements
    df_wide <- pair_df %>% select(sample_id, coder, val=!!sym(lbl), text_block_german, text_block_english,
                                  threat_criterion, threat_uncertain, benefit_criterion, benefit_uncertain, coder_note) %>%
      pivot_wider(names_from=coder, values_from=c(val, threat_criterion, threat_uncertain, benefit_criterion, benefit_uncertain, coder_note))
    
    val_cols <- paste0("val_", pairs[[b]])
    disag_df <- df_wide[df_wide[[val_cols[1]]] != df_wide[[val_cols[2]]], ]
    if(nrow(disag_df) > 0) {
      disag_df$label_type <- lbl
      disag_df$block <- b
      disagreements <- bind_rows(disagreements, disag_df)
    }
  }
}

write_csv(results, file.path(outputs_dir, "pairwise_reliability.csv"))

# Krippendorff's alpha
ka_df <- data.frame()
for (lbl in c("economic_threat", "economic_benefit")) {
  mat_df <- long_df %>% select(sample_id, coder, val=!!sym(lbl)) %>%
    pivot_wider(names_from=sample_id, values_from=val)
  
  mat <- as.matrix(mat_df[, -1])
  rownames(mat) <- mat_df$coder
  
  # irr kripp.alpha requires matrix where rows are raters and cols are subjects
  ka <- kripp.alpha(mat, method="nominal")
  ka_df <- bind_rows(ka_df, data.frame(
    label=lbl, alpha=ka$value, units=ka$subjects, coders=ka$raters,
    valid_pairable_observations=sum(!is.na(mat)), missing_by_design="Yes"
  ))
}
write_csv(ka_df, file.path(outputs_dir, "krippendorff_alpha.csv"))

# Save disagreements
threat_dis <- if("label_type" %in% names(disagreements)) disagreements %>% filter(label_type == "economic_threat") else data.frame()
benefit_dis <- if("label_type" %in% names(disagreements)) disagreements %>% filter(label_type == "economic_benefit") else data.frame()

if(nrow(threat_dis) == 0) {
  writeLines("sample_id,coder_1,coder_2", file.path(outputs_dir, "human_disagreements_threat.csv"))
} else {
  write_csv(threat_dis, file.path(outputs_dir, "human_disagreements_threat.csv"))
}
if(nrow(benefit_dis) == 0) {
  writeLines("sample_id,coder_1,coder_2", file.path(outputs_dir, "human_disagreements_benefit.csv"))
} else {
  write_csv(benefit_dis, file.path(outputs_dir, "human_disagreements_benefit.csv"))
}

# MD Report
report_txt <- c(
  "# HUMAN HUMAN RELIABILITY RESULTS\n",
  "## 1. Study design", "Missing-by-design, 3 coders.",
  "## 2. Block assignments", "Part A: Pravallika/Raywin, Part B: Raywin/Namrath, Part C: Namrath/Pravallika",
  paste("## 3. Number of coder observations:", nrow(long_df)),
  "## 4. Pairwise percent agreement", paste(capture.output(print(results %>% select(block, label, pct_agreement))), collapse="\n"),
  "## 5. Pairwise Cohen's kappa", paste(capture.output(print(results %>% select(block, label, cohens_kappa))), collapse="\n"),
  "## 6. Krippendorff's Alpha", paste(capture.output(print(ka_df)), collapse="\n"),
  paste("## 8. Number of disagreements:", nrow(disagreements)),
  "## 11. Limitation", "The submitted paired files were byte-identical for all three blocks, producing perfect observed agreement. The analysis reports this result as present in the submitted data. File-level identity alone does not independently establish how the coding process was conducted."
)
writeLines(report_txt, file.path("reports/reliability_1002", "HUMAN_HUMAN_RELIABILITY_RESULTS.md"))

cat(sprintf("PAIRWISE_AGREEMENT_MEAN: %f\n", mean(results$pct_agreement, na.rm=T)))
cat(sprintf("KAPPA_MEAN: %f\n", mean(results$cohens_kappa, na.rm=T)))
cat(sprintf("KRIPPENDORFF_THREAT: %f\n", ka_df$alpha[ka_df$label == "economic_threat"]))
cat(sprintf("KRIPPENDORFF_BENEFIT: %f\n", ka_df$alpha[ka_df$label == "economic_benefit"]))
cat(sprintf("DISAGREEMENTS: %d\n", nrow(disagreements)))
