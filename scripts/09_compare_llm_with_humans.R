
library(dplyr)
library(readr)
library(digest)

outputs_dir <- "outputs/reliability_1002"
llm_file <- "data/manual_annotation_1002/master/part_A_1002.csv"
# Actually the prompt says "outputs/step5/final_annotated_10k.csv"
llm_file <- "outputs/step5/final_annotated_10k.csv"

# Record SHA
if(file.exists(llm_file)) {
  sha256 <- digest(file = llm_file, algo = "sha256")
  cat(sprintf("LLM_FILE_SHA256: %s\n", sha256))
  
  llm_df <- read_csv(llm_file, show_col_types = FALSE)
  con_df <- read_csv(file.path(outputs_dir, "human_consensus_1002.csv"), show_col_types = FALSE)
  
  # Join
  joined <- inner_join(con_df, llm_df, by = "row_num")
  
  # Map robustly
  joined <- joined %>%
    mutate(
      llm_threat = case_when(threat_label %in% c("YES", "1", "TRUE", 1, TRUE) ~ 1,
                             threat_label %in% c("NO", "0", "FALSE", 0, FALSE) ~ 0,
                             TRUE ~ NA_real_),
      llm_benefit = case_when(benefit_label %in% c("YES", "1", "TRUE", 1, TRUE) ~ 1,
                              benefit_label %in% c("NO", "0", "FALSE", 0, FALSE) ~ 0,
                              TRUE ~ NA_real_),
      threat_match = consensus_threat == llm_threat,
      benefit_match = consensus_benefit == llm_benefit
    )
  
  write_csv(joined %>% select(sample_id, row_num, block, consensus_threat, llm_threat, consensus_benefit, llm_benefit, threat_match, benefit_match),
            file.path(outputs_dir, "llm_vs_human_predictions_1002.csv"))
            
  # Metrics
  calc_met <- function(df, cons_col, llm_col) {
    tp <- sum(df[[cons_col]] == 1 & df[[llm_col]] == 1, na.rm=T)
    tn <- sum(df[[cons_col]] == 0 & df[[llm_col]] == 0, na.rm=T)
    fp <- sum(df[[cons_col]] == 0 & df[[llm_col]] == 1, na.rm=T)
    fn <- sum(df[[cons_col]] == 1 & df[[llm_col]] == 0, na.rm=T)
    
    prec <- tp / (tp + fp)
    rec <- tp / (tp + fn)
    f1 <- 2 * prec * rec / (prec + rec)
    acc <- (tp + tn) / (tp + tn + fp + fn)
    
    return(data.frame(tp=tp, tn=tn, fp=fp, fn=fn, precision=prec, recall=rec, f1=f1, accuracy=acc))
  }
  
  m_threat <- calc_met(joined, "consensus_threat", "llm_threat")
  m_benefit <- calc_met(joined, "consensus_benefit", "llm_benefit")
  m_threat$label <- "economic_threat"
  m_benefit$label <- "economic_benefit"
  
  write_csv(bind_rows(m_threat, m_benefit), file.path(outputs_dir, "llm_vs_human_metrics.csv"))
  
  # Error files
  threat_fp <- joined %>% filter(consensus_threat == 0 & llm_threat == 1)
  threat_fn <- joined %>% filter(consensus_threat == 1 & llm_threat == 0)
  write_csv(threat_fp, file.path(outputs_dir, "errors/threat_false_positives.csv"))
  write_csv(threat_fn, file.path(outputs_dir, "errors/threat_false_negatives.csv"))
  
  benefit_fp <- joined %>% filter(consensus_benefit == 0 & llm_benefit == 1)
  benefit_fn <- joined %>% filter(consensus_benefit == 1 & llm_benefit == 0)
  write_csv(benefit_fp, file.path(outputs_dir, "errors/benefit_false_positives.csv"))
  write_csv(benefit_fn, file.path(outputs_dir, "errors/benefit_false_negatives.csv"))
  
  cat(sprintf("LLM_THREAT_ACC: %f\n", m_threat$accuracy))
  cat(sprintf("LLM_THREAT_F1: %f\n", m_threat$f1))
  cat(sprintf("LLM_BENEFIT_ACC: %f\n", m_benefit$accuracy))
  cat(sprintf("LLM_BENEFIT_F1: %f\n", m_benefit$f1))
  
  rep <- c(
    "# LLM VS HUMAN CONSENSUS RESULTS",
    paste("Number of joined rows:", nrow(joined)),
    paste("Exact frozen LLM file hash:", sha256)
  )
  writeLines(rep, "reports/reliability_1002/LLM_VS_HUMAN_CONSENSUS_RESULTS.md")
  
} else {
  cat("LLM FILE NOT FOUND\n")
}
