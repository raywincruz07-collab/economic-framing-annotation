# Mapping to the bacchuss Annotation Routine

This document maps the project's steps to the professor’s `bacchuss` annotation routine.

## Step 1 — First draft of annotation instructions

Evidence in this project:
- `config.R`
- `docs/METHODOLOGY.md`
- `references/codebook_SCM_2025.pdf`

What was done:
- Defined two separate binary dimensions: Economic Threat and Economic Benefit.
- Created separate instruction logic for Threat and Benefit to avoid mixing coding rules.
- Used role description, context, label definitions, decision rules, exclusion rules, and structured output format.

## Step 2.1 — Test instructions on development sample

Evidence:
- `data/samples/sample_200.csv`
- `data/samples/gold_200.csv`
- `scripts/step2_1_zeroshot.R`
- `outputs/step2_1/`
- `reports/classification_reports/`

What was done:
- Tested early prompt versions against a 200-row development sample.
- Compared LLM labels with human labels using precision, recall, and F1.
- Iteratively changed rules based on observed false positives and false negatives.

## Step 2.2 — Hard-case / repeated-run consistency check

Evidence:
- `scripts/step2_2_hardcases.R`
- `outputs/step2_2/`

What was done:
- Re-ran labels multiple times to identify unstable rows using `briseus()`.
- Used uncertain cases to improve annotation rules and identify edge cases.

## Step 3.1–3.3 — Refine with hard/soft cases, few-shot examples, and structured reasoning

Evidence:
- `data/fewshot/fewshot_training_blocks.csv`
- `scripts/step3_1_baseline.R`
- `scripts/step3_2_fewshot_cot.R`
- `scripts/step3_3_hardcases_few.R`
- `reports/prompt_version_log.csv`

What was done:
- Added few-shot examples for T1–T5 and B1–B5.
- Added structured explanation (Chain-of-Thought) before final label.
- Re-tested until Threat passed the F1 gate (≥0.80) and Benefit reached acceptable recall with low-prevalence limitations.

## Step 3.4 — Compare different LLMs

Status:
- Full full multi-model benchmarking was not performed. The project used the university compute proxy model consistently for reproducibility and comparability. This is documented as a limitation.

## Step 4 — Representative human validation

Evidence:
- `data/validation/human_gold_validation.csv`
- `scripts/step4_validation.R`
- `outputs/step4/`

What was done:
- Validated the final prompt against a fresh 200-row human-labelled validation set.
- Reported LLM validity using precision, recall, and F1.

## Step 4.2 — Human-Human Intercoder Reliability

Status:
- Human-human intercoder reliability is reported if the overlapped annotation set is available. Scripts and templates are provided in `scripts/step4_0_intercoder_reliability.R` and `data/intercoder/`.

## Step 5 — Report results

Evidence:
- `README.md`
- `docs/METHODOLOGY.md`
- `reports/project_notes.md`
- `reports/prompt_version_log.csv`
- `outputs/step6/final_report.txt`

What was done:
- Reported the iterative development process across 8 iterations.
- Reported final corpus distribution (N=10,000).
- Reported validation metrics and documented limitations.
