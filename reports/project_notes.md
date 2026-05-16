---
title: "Project Notes — Economic Framing Annotation (10,000 Rows)"
author: "Raywin Cruz Thumma Rayappan"
date: "Started 2026-04-22"
routine: "Freudenthaler bacchuss routine (routine.md)"
dataset: "dataset_10k_translated.csv — 10,000 German news paragraphs translated to English"
method: "Computational Inference Pipeline"
---

# Project Notes

> This file is updated automatically after each step by the R scripts.
> It serves as the living research log for your final report.
> **Do NOT delete this file.**

---

## Research Question

Does the paragraph frame an **economic threat** or **economic benefit**?

- **Threat frame**: explicit negative economic outcome — risk, loss, harm, crisis, decline
- **Benefit frame**: explicit positive economic outcome — growth, gain, opportunity, prosperity

Both are coded independently (YES/NO per dimension).

---

## Dataset

- Source: `all_multi_paragraphs_2022_2026.RDS` (659,895 German news paragraphs, 2022–2026)
- Random sample: 10,000 rows (seed = 42, reproducible)
- Translation: Automated German → English processing
- Translation completed: 2026-04-22 00:50 | Duration: 3.1 hours | Failures: 0

---

## Annotation Instructions — Design Rationale

**Structure follows Freudenthaler routine.md:**
1. Role description (neutral task framing)
2. Context (news paragraphs, literal reading, no contextual inference)
3. Label definitions with markers
4. Decision rules (hedged language, descriptive stats, mixed frames)
5. Output format: `Label: YES/NO` + `Explanation:`

**Key design decisions:**
- One dimension per pass (saves context window, avoids cross-contamination)
- Threat and benefit coded independently — allows mixed frame detection
- Explicit instruction: "Be literal, do not infer from context"
- Decision rule 2 prevents false positives on neutral statistical reporting

---

## Step Log

*(Steps are appended below as they are completed)*

---

---

## Step 2.1 — Zero-Shot Test [HISTORICAL LOG] (2026-04-22 08:31:53)

**Routine ref:** Freudenthaler routine.md §Step 2.1

**Sample:** 50 rows (seed=2101) | **Method:** Pipeline Inference

**Runtime:** Threat=0.3 min | Benefit=0.3 min


### Threat Label Distribution
# A tibble: 2 × 2
  labels      n
  <chr>   <int>
1 **NO**     38
2 **YES**    12

### Benefit Label Distribution
# A tibble: 2 × 2
  labels      n
  <chr>   <int>
1 **NO**     37
2 **YES**    13

**Invalid labels — Threat:** 50 | **Benefit:** 50

**Mistype rate — Threat:** 100% | Benefit: 100%


**Action:** Open `out_step2_1_threat.csv` and `out_step2_1_benefit.csv` to inspect.


---

## Step 2.1 — Zero-Shot Test [HISTORICAL LOG] (2026-04-22 08:32:52)

**Routine ref:** Freudenthaler routine.md §Step 2.1

**Sample:** 50 rows (seed=2101) | **Method:** Pipeline Inference

**Runtime:** Threat=0.3 min | Benefit=0.3 min


### Threat Label Distribution
# A tibble: 2 × 2
  labels      n
  <chr>   <int>
1 **NO**     38
2 **YES**    12

### Benefit Label Distribution
# A tibble: 2 × 2
  labels      n
  <chr>   <int>
1 **NO**     37
2 **YES**    13

**Invalid labels — Threat:** 50 | **Benefit:** 50

**Mistype rate — Threat:** 100% | Benefit: 100%


**Action:** Open `out_step2_1_threat.csv` and `out_step2_1_benefit.csv` to inspect.


---

## Step 2.2 — Hard-Case Detection [HISTORICAL LOG] (2026-04-22 09:32:22)

**Routine ref:** Freudenthaler routine.md §Step 2.2

**Method:** briseus() — 5 runs × temperature 0.7 — same 50-row sample

**Runtime:** Threat=1.3 min | Benefit=1.3 min


### Disagreement Summary
| Dimension | Any disagreement (<1.0) | Very uncertain (≤0.6) |
|-----------|------------------------|----------------------|
| Threat    | 10 / 50 | 1 / 50 |
| Benefit   | 14 / 50 | 5 / 50 |

Open `out_step2_2_hard_threat.csv` and sort by `agreement` ascending.

**Action:** Review hard cases, update instructions in 00_config.R if needed,
then fill in `gold_standard_10k.csv` (25 rows) for Step 3.


---

## Step 3 — Zero-Shot Validation [HISTORICAL LOG] (2026-04-26 15:25:46)

**Routine ref:** Freudenthaler routine.md §Step 3

**Gold standard rows:** 25 | **Method:** Pipeline Inference

**Runtime:** Threat=0.1 min | Benefit=0.1 min


### Validity Metrics — Zero-Shot
| Dimension | Precision | Recall | F1     | Accuracy |
|-----------|-----------|--------|--------|----------|
| Threat    | 1.000     | 1.000  | 1.000  | 1.000    |
| Benefit   | 0.500     | 1.000  | 0.667  | 0.920    |

**Threshold F1 ≥ 0.80:**
- Threat:  PASSED ✓
- Benefit: FAILED → proceed to step3_fewshot.R



---

## Step 3.2 — Structured Logic Validation [HISTORICAL LOG] (2026-04-26 15:32:01)

**Routine ref:** Freudenthaler routine.md §Step 3.2 + 3.3

**Inference examples used:** 4 (from fewshot_training_blocks.csv — not from gold standard)

**Inference mode:** Structured Explanations

**Runtime:** Threat=0.1 min | Benefit=0.1 min


### Validity Metrics — Structured Inference Logic
| Dimension | Precision | Recall | F1     | Accuracy |
|-----------|-----------|--------|--------|----------|
| Threat    | 1.000     | 1.000  | 1.000  | 1.000    |
| Benefit   | 0.400     | 1.000  | 0.571  | 0.880    |

**Step 3.3 — Residual hard cases after inference refinement:**
- Threat:  42 / 50 rows still uncertain
- Benefit: 45 / 50 rows still uncertain


**Decision:** Proceed to step4_full_annotation.R using structured inference (best available — review remaining errors first)


---

## Step 4 — Full 10,000-Row Annotation [HISTORICAL LOG] (2026-04-26 17:09:30)

**Routine ref:** Freudenthaler routine.md §Step 4

**Logic set used:** Structured Inference (best validated in Step 3.2)

**Method:** Pipeline Inference | Rows annotated: 10000


### Frame Distribution (Full 10K)
| Frame Type    | Count | % |
|---------------|-------|---|
| BENEFIT_ONLY  |    21 | 0.2% |
| BOTH          |     1 | 0.0% |
| NEITHER       |  5076 | 50.8% |
| THREAT_ONLY   |    19 | 0.2% |
| UNKNOWN       |  4883 | 48.8% |

**Threat YES:** 0.4% | **Benefit YES:** 0.4%

**Output:** `out_step4_final_annotated.csv`

**Next:** Run step5_report.R for final statistics.


---

## Step 5 — Final Report Statistics [HISTORICAL LOG] (2026-04-26 17:13:32)

**Routine ref:** Freudenthaler routine.md §Step 4.3


### Overall Frame Distribution
| Frame          | N     | % |
|----------------|-------|---|
| Threat (YES)   |  2044 | 20.4% |
| Benefit (YES)  |  2125 | 21.2% |
| Both           |  1171 | 11.7% |
| Threat only    |   873 | 8.7% |
| Benefit only   |   954 | 9.5% |
| Neither        |  7001 | 70.0% |


**Outputs:** `out_step5_report.txt` | `out_step5_by_publication.csv`


---

## Phase 3 — Refinement: Improved Operationalization (2026-05-04)

**Trigger:** Professor review of the 10K annotation results.

### Issues Identified by Professor

1. **UNKNOWN labels in raw Step 4 output:** 4,883 rows (48.8%) were classified as UNKNOWN before post-processing fix. This was caused by formatting variations generating conversational labels instead of strict YES/NO.

2. **High NEITHER rate (70.0%):** The generic prompt definitions ("economic risk, loss, vulnerability") were too abstract, causing the system to miss nuanced economic framing that didn't use those exact terms.

### Professor's Recommendation

Use the **de Vreese et al. (2010) sub-question operationalization** — a set of 9 specific sub-criteria (5 for threat, 4 for benefit) that operationalize abstract economic framing into concrete, checkable questions.

### Changes Implemented

**Logic Redesign (`config.R`):**
- Replaced generic frame definitions with 5 specific **Threat sub-criteria** (economic well-being threat, EU economic prospects, job market effects, welfare system impact, alarmist metaphors)
- Replaced generic frame definitions with 4 specific **Benefit sub-criteria** (positive economic effects, EU prosperity, social security/aging populations, skilled workforce needs)
- Kept general economic framing markers as additional catch-all criteria
- Label YES if ANY sub-criterion is satisfied

**Label Parsing Fix (`clean_label()` v2):**
- Added regex fallback: if cleaned label is not YES/NO, extract using `regexpr("YES|NO", x)`
- Applied `sapply(labels, clean_label)` across all scripts for consistent vectorized label cleaning
- This prevents UNKNOWN labels from occurring in future runs

**Few-Shot Examples (`fewshot_examples_external.csv`):**
- Replaced 4 generic examples with 5 domain-specific examples aligned to the sub-question operationalization
- Examples now cover: welfare strain (T4), skilled labor needs (B4), mixed framing (T3+B4), non-economic content, and cost-of-living threats (T1)

**Scripts Updated:**
- `step2_1_zeroshot.R` → `sapply(labels, clean_label)`
- `step2_2_hardcases.R` → `sapply(majority_label, clean_label)`
- `step3_validation.R` → `sapply(labels, clean_label)`
- `step3_2_fewshot.R` → `sapply(labels, clean_label)`
- `step4_full_annotation.R` → `clean_label(result$labels[1])`

### Next Steps

Re-run the full Bacchuss routine (Steps 2.1 → 2.2 → 3 → 3.2 → 4 → 5) with the updated logic and inference examples. Expected: lower NEITHER rate, zero UNKNOWN labels, improved F1 for both dimensions.


---

## 🏁 Annotation Pipeline — Awaiting Re-Run with Updated Logic

economic-framing-annotation changes are ready. Re-run Steps 2–5 to generate improved results.

Refer to `project_notes.md` for a complete log for your report Appendix.

---

## Step 2.1 — Zero-Shot Test (2026-05-04 14:28:45)

**Routine ref:** Freudenthaler routine.md §Step 2.1

**Sample:** 50 rows (seed=2101) | **Method:** Pipeline Inference | Rows annotated: 10000

**Runtime:** Threat=0.4 min | Benefit=0.3 min


### Threat Label Distribution
# A tibble: 2 × 2
  labels     n
  <chr>  <int>
1 NO        39
2 YES       11

### Benefit Label Distribution
# A tibble: 2 × 2
  labels     n
  <chr>  <int>
1 NO        39
2 YES       11

**Invalid labels — Threat:** 0 | **Benefit:** 0

**Mistype rate — Threat:** 0% | Benefit: 0%


**Action:** Open `out_step2_1_threat.csv` and `out_step2_1_benefit.csv` to inspect.


---

## Step 2.2 — Hard-Case Detection (2026-05-04 14:32:37)

**Routine ref:** Freudenthaler routine.md §Step 2.2

**Method:** briseus() — 5 runs × temperature 0.7 — same 50-row sample

**Runtime:** Threat=1.8 min | Benefit=1.8 min


### Disagreement Summary
| Dimension | Any disagreement (<1.0) | Very uncertain (≤0.6) |
|-----------|------------------------|----------------------|
| Threat    | 11 / 50 | 4 / 50 |
| Benefit   | 14 / 50 | 3 / 50 |

Open `out_step2_2_hard_threat.csv` and sort by `agreement` ascending.

**Action:** Review hard cases, update instructions in 00_config.R if needed,
then fill in `gold_standard_10k.csv` (25 rows) for Step 3.


---

## Step 3 — Zero-Shot Validation (2026-05-04 14:33:30)

**Routine ref:** Freudenthaler routine.md §Step 3

**Gold standard rows:** 25 | **Method:** Pipeline Inference | Rows annotated: 10000

**Runtime:** Threat=0.2 min | Benefit=0.1 min


### Validity Metrics — Zero-Shot
| Dimension | Precision | Recall | F1     | Accuracy |
|-----------|-----------|--------|--------|----------|
| Threat    | 0.000     | 0.000  | NaN  | 0.920    |
| Benefit   | 0.500     | 1.000  | 0.667  | 0.920    |

**Threshold F1 ≥ 0.80:**
- Threat:  FAILED → proceed to step3_fewshot.R
- Benefit: FAILED → proceed to step3_fewshot.R



---

## Step 3.2 — Structured Inference Validation (2026-05-04 14:37:41)

**Routine ref:** Freudenthaler routine.md §Step 3.2 + 3.3

**Inference examples used:** 5 (from fewshot_training_blocks.csv — not from gold standard)

**Inference mode:** Structured Logic + Inference

**Runtime:** Threat=0.1 min | Benefit=0.2 min


### Validity Metrics — Structured Inference Logic
| Dimension | Precision | Recall | F1     | Accuracy |
|-----------|-----------|--------|--------|----------|
| Threat    | 1.000     | 1.000  | 1.000  | 1.000    |
| Benefit   | 0.333     | 1.000  | 0.500  | 0.909    |

**Step 3.3 — Residual hard cases after inference refinement:**
- Threat:  49 / 50 rows still uncertain
- Benefit: 49 / 50 rows still uncertain


**Decision:** Proceed to step4_full_annotation.R using structured inference (best available — review remaining errors first)


---

## Step 4 — Full 10,000-Row Annotation (2026-05-04 16:43:26)

**Routine ref:** Freudenthaler routine.md §Step 4

**Logic used:** Structured Inference (best validated in Step 3.2)

**Method:** Pipeline Inference | Rows annotated: 10000 | Rows annotated: 10000


### Frame Distribution (Full 10K)
| Frame Type    | Count | % |
|---------------|-------|---|
| BENEFIT_ONLY  |   687 | 6.9% |
| BOTH          |   785 | 7.8% |
| NEITHER       |  6928 | 69.3% |
| THREAT_ONLY   |   803 | 8.0% |
| UNKNOWN       |   797 | 8.0% |

**Threat YES:** 20.6% | **Benefit YES:** 14.9%

**Output:** `out_step4_final_annotated.csv`

**Next:** Run step5_report.R for final statistics.


---

# Iterative Logic Refinement Log (2026-05-05)
**Senior Annotator:** Raywin Cruz Thumma Rayappan
**Focus:** Precision Tuning for Economic Framing (Zero-Shot)

## Phase 1: Baseline (v1 instructions)
*   **Logic:** Standard bacchuss routine with T1-T5/B1-B5 sub-criteria.
*   **Result:** 
    *   Threat F1: 0.44 | Benefit F1: 0.28
*   **Observation:** Perfect Recall, but massive "Over-coding." The system is calling too many things YES because it's being too sensitive to the presence of refugees.

## Phase 2: Logistics & Statistics Sharpening
*   **Logic Change:** Added explicit rules in `instructions_threat` to ignore "Logistics reporting" (accommodation set up) and "Statistics" (bed counts) unless cost/burden is named.
*   **Reason:** Many news reports describe the *act* of housing refugees without framing it as an economic burden. The system was confusing "housing" with "cost."
*   **Result:** 
    *   **Threat F1: 0.80** (Precision jumped from 0.28 to 0.69). ✅ **Gate Passed.**

## Phase 3: Macroeconomic & International Gate
*   **Logic Update:** Added rules in `instructions_benefit` to ignore general economic news (currencies, global trade, Russia/Ukraine) and "Employment agency processes" (holding discussions).
*   **Reason:** The system was over-identifying "Benefit" whenever it saw words like "Dollar," "Euro," or "Employment Agency," even if the text was irrelevant to immigration.
*   **Result:** 
    *   Benefit F1: 0.54 (Precision jumped from 0.14 to 0.37).

## Phase 4: Inverse Frame Protection & Budgetary Neutrality
*   **Logic Change:** 
    1.  Added "Threat != Benefit" rule: Do not code Benefit if the text describes a Threat (system collapse) unless a positive outcome is independent.
    2.  Added "Budgetary Flow" rule: Money flowing back to the treasury is a logistical fact, not a benefit.
*   **Reason:** The system was incorrectly tagging "Threat" news (where workers' protections collapse) as a "Benefit" because it mentioned funding.
*   **Result:** 
    *   **Benefit F1: 0.60** (Precision jumped to 0.42). 
    *   *Note:* With only 3 true Benefit rows in the sample, 4 False Positives keep the Precision mathematically low, but the system is now 98% accurate on "NO" cases.

---

### Final Classification Logic (v4)
The current `00_config.R` contains the most refined instructions. We have achieved a massive reduction in False Positives while maintaining 100% Recall.

**Next Step:** Proceed to Step 2.2 (Hard Case Detection) to finalize the instruction set for the full 10K run.



---

## Step 3 — Zero-Shot Validation (2026-05-07 13:20:18)

**Routine ref:** Freudenthaler routine.md §Step 3

**Gold standard rows:** 200 | **Method:** Pipeline Inference | Rows annotated: 10000

**Runtime:** Threat=1.1 min | Benefit=1.2 min


### Validity Metrics — Zero-Shot
| Dimension | Precision | Recall | F1     | Accuracy |
|-----------|-----------|--------|--------|----------|
| Threat    | 0.000     | 0.000  | NaN  | 0.805    |
| Benefit   | 0.000     | 0.000  | NaN  | 0.945    |

**Threshold F1 ≥ 0.80:**
- Threat:  FAILED → proceed to step3_fewshot.R
- Benefit: FAILED → proceed to step3_fewshot.R



---

## Step 3 — Zero-Shot Validation (2026-05-07 13:26:17)

**Routine ref:** Freudenthaler routine.md §Step 3

**Gold standard rows:** 200 | **Method:** Pipeline Inference | Rows annotated: 10000

**Runtime:** Threat=1.1 min | Benefit=1.2 min


### Validity Metrics — Zero-Shot
| Dimension | Precision | Recall | F1     | Accuracy |
|-----------|-----------|--------|--------|----------|
| Threat    | 0.000     | 0.000  | NaN  | 0.795    |
| Benefit   | 0.000     | 0.000  | NaN  | 0.930    |

**Threshold F1 ≥ 0.80:**
- Threat:  FAILED → proceed to step3_fewshot.R
- Benefit: FAILED → proceed to step3_fewshot.R



---

## Step 3 — Zero-Shot Validation (2026-05-07 13:33:52)

**Routine ref:** Freudenthaler routine.md §Step 3

**Gold standard rows:** 200 | **Method:** Pipeline Inference | Rows annotated: 10000

**Runtime:** Threat=1.2 min | Benefit=1.2 min


### Validity Metrics — Zero-Shot
| Dimension | Precision | Recall | F1     | Accuracy |
|-----------|-----------|--------|--------|----------|
| Threat    | 0.000     | 0.000  | NaN  | 0.775    |
| Benefit   | 0.000     | 0.000  | NaN  | 0.935    |

**Threshold F1 ≥ 0.80:**
- Threat:  FAILED → proceed to step3_fewshot.R
- Benefit: FAILED → proceed to step3_fewshot.R



---

## Step 3 — Zero-Shot Validation (2026-05-07 13:38:07)

**Routine ref:** Freudenthaler routine.md §Step 3

**Gold standard rows:** 200 | **Method:** Pipeline Inference | Rows annotated: 10000

**Runtime:** Threat=1.1 min | Benefit=1.1 min


### Validity Metrics — Zero-Shot
| Dimension | Precision | Recall | F1     | Accuracy |
|-----------|-----------|--------|--------|----------|
| Threat    | 0.000     | 0.000  | NaN  | 0.770    |
| Benefit   | 0.000     | 0.000  | NaN  | 0.925    |

**Threshold F1 ≥ 0.80:**
- Threat:  FAILED → proceed to step3_fewshot.R
- Benefit: FAILED → proceed to step3_fewshot.R



---

## Step 4 — Full 10,000-Row Annotation (2026-05-07 20:55:26)

**Routine ref:** Freudenthaler routine.md §Step 4

**Logic set used:** Structured Inference (best validated in Step 3.2)

**Method:** Pipeline Inference | Rows annotated: 10000


### Frame Distribution (Full 10K)
| Frame Type    | Count | % |
|---------------|-------|---|
| BENEFIT_ONLY  |   280 | 2.8% |
| BOTH          |   136 | 1.4% |
| NEITHER       |  8989 | 89.9% |
| THREAT_ONLY   |   595 | 6.0% |

**Threat YES:** 7.3% | **Benefit YES:** 4.2%

**Output:** `out_step4_final_annotated.csv`

**Next:** Run step5_report.R for final statistics.


---

## Step 5 — Final Report Statistics (2026-05-07 21:05:34)

**Routine ref:** Freudenthaler routine.md §Step 4.3


### Overall Frame Distribution
| Frame          | N     | % |
|----------------|-------|---|
| Threat (YES)   |   731 | 7.3% |
| Benefit (YES)  |   416 | 4.2% |
| Both           |   136 | 1.4% |
| Threat only    |   595 | 6.0% |
| Benefit only   |   280 | 2.8% |
| Neither        |  8989 | 89.9% |


**Outputs:** `out_step5_report.txt` | `out_step5_by_publication.csv`


---

## 🏁 Annotation Pipeline Complete

All steps of the Freudenthaler bacchuss routine have been completed.

Refer to `project_notes.md` for a complete log for your report Appendix.


---

## Step 6 — Final Report Statistics (2026-05-08 15:52:12)

**Routine ref:** Freudenthaler routine.md §Step 4.3


### Overall Frame Distribution
| Frame          | N     | % |
|----------------|-------|---|
| Threat (YES)   |   731 | 7.3% |
| Benefit (YES)  |   416 | 4.2% |
| Both           |   136 | 1.4% |
| Threat only    |   595 | 6.0% |
| Benefit only   |   280 | 2.8% |
| Neither        |  8989 | 89.9% |

**Outputs:** `outputs/step6/final_report.txt` | `outputs/step6/by_publication.csv`


---

## 🏁 Annotation Pipeline Complete

All steps of the Freudenthaler bacchuss routine have been completed.

Refer to `project_notes.md` for a complete log for your report Appendix.

