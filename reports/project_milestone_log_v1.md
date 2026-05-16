# Project Milestone Log: Professional Annotation Pipeline
**Date:** 2026-05-05
**Status:** Step 2.1 Complete | Step 2.2 In Progress

---

## 1. Repository Reorganization (The "Professional" Shift)
### What was done:
We executed a complete structural overhaul of the project workspace, transforming it from a loose collection of files into a strictly segregated, industry-standard research repository.
*   **Hierarchical Folders:** Created `data/` (with `raw`, `samples`, `fewshot`, `validation`), `scripts/`, `outputs/`, and `reports/`.
*   **Standardized Naming:** Renamed all pipeline scripts to follow the `stepX_Y` convention mandated by the Senior Guide.
*   **Single Source of Truth:** Centralized all prompts and configuration into `00_config.R`.

### Why we did this:
*   **Scalability:** Processing 10,000 rows generates massive data. Without subfolders like `outputs/step2_1/`, files overwrite each other and cause confusion.
*   **Reproducibility:** A professional structure ensures that any other researcher can understand the workflow instantly just by looking at the folder tree.

---

## 2. Data Foundation & Human Baseline
### What was done:
*   **Fixed Sampling:** Used `set.seed(2101)` to draw 200 rows into `sample_200.csv`.
*   **English-First Strategy:** Confirmed that the entire pipeline targets the `text_block_english` column.
*   **Human Ground Truth:** You (the Senior Annotator) manually labeled the 200-row sample to create `gold_200.csv`.

### Why we did this:
*   **Scientific Validity:** We cannot measure the system's "Accuracy" if we don't have a human "Gold Standard" to compare it against.
*   **Seed Regularization:** Using a fixed seed (`2101`) ensures that if we ever need to re-draw the sample, we get the exact same rows, making the test consistent across runs.

---

## 3. Step 2.1 — The Baseline Evaluation
### What was done:
We ran the first full processing pass on the 200 rows using "Zero-Shot" (instructions only, no examples). 
*   **Instruction v1:** Integrated the mandatory "Occurrence Rule" and sub-question checklists (T1–T5 for Threat, B1–B5 for Benefit).
*   **Classification Report:** Calculated Precision, Recall, and F1 scores against your `gold_200.csv`.

### Why we did this:
*   **Identifying the Gap:** We discovered that the system is currently "over-coding" (Precision is 0.48 for Threat and 0.16 for Benefit). It is calling too many things YES.
*   **Metric-Driven Decisions:** We now know exactly how much "sharper" our instructions need to be to hit the target F1 score of **0.80**.

---

## 4. Current Phase: Step 2.2 — Hard-Case Detection
### What is happening now:
We are running the `briseus()` routine on the 200 rows (5 runs each at high temperature).

### Why we are doing this:
*   **Uncovering Ambiguity:** If the system says YES in run 1 and NO in run 2 for the same text, that text is an "Ambiguous Case." 
*   **Targeted Optimization:** Instead of guessing why the classification is failing, we will look at these specific "flip-flop" cases. This tells us exactly which sentence in our instructions needs more detail to prevent errors and confusion.

---

## 5. Summary of Future Steps
1.  **Instruction Tuning:** Use the hard cases from Step 2.2 to update `00_config.R`.
2.  **Step 3.2 (Inference):** Add the training blocks to provide the system with clear "Yes/No" examples.
3.  **Final Gate:** Re-run validation. Once F1 is ≥ 0.80, we trigger the full 10,000-row execution.
