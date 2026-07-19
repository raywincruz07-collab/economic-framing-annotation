# Annotation Methodology
## Economic Framing Detection in German Immigration News

### Academic Basis
- Codebuch SCM Economy Culture Security (2025)
- de Vreese, Boomgaarden & Semetko (2011) — sub-question operationalization
- Guo, Su & Chen (2023) — computational framing analysis
- Freudenthaler bacchuss routine

### Dimensions Annotated
Two binary dimensions per paragraph:
- **Economic Threat** (T1–T5): immigration framed as causing economic harm
- **Economic Benefit** (B1–B5): immigration framed as generating economic value

### Coding Rule: Occurrence Not Affirmation
Frames are coded by presence — if the text mentions a frame, even to deny it,
the frame is coded YES. (Codebuch SCM 2025, p.1)

### Sub-criteria
**Threat (T1–T5):** Economic well-being threat · EU/German economic prospects ·
Labour market harm · Welfare/public finance drain · Integration/capacity costs

**Benefit (B1–B5):** Tax revenue/economic growth · EU/German economic benefit ·
Demographic necessity · Skilled labour shortage + immigration · Conditional/lost benefits

### Validation Results (8-iteration prompt development)
| Run | Change | Threat F1 | Benefit F1 |
|---|---|---|---|
| 1 | Baseline | 0.643 | 0.286 |
| 2 | Logistics exclusions | 0.652 | 0.857 |
| 3 | Strict NO rules | 0.438 | 0.667 |
| 4 | International exclusions | 0.622 | 0.600 |
| 5 | Structured Inference / Few-shot + CoT + encoding fix | 0.727 | 0.500 |
| 6 | T5/B5/B4 examples | 0.833 | 0.769 |
| 7 | Benefit NO example | 0.857 | 0.769 |
| 8 | Legal-status NO example | **0.811** | **0.769** |

### Final Validation Metrics
- **Threat:** Precision=0.833, Recall=0.789, F1=0.811 ✅
- **Benefit:** Precision=0.625, Recall=1.000, F1=0.769 🟢 (High recall, moderate precision. Statistical fragility due to low prevalence (2.5%) in the validation set.)
- **briseus consistency:** 17/200 Threat, 13/200 Benefit uncertain (both < 40/200 gate)

### Final Corpus Distribution (10,000 rows)
| Frame Type | Count | Percentage |
|:---|:---|:---|
| **NEITHER** | 8,989 | **89.9%** |
| **THREAT only** | 595 | **6.0%** |
| **BENEFIT only** | 280 | **2.8%** |
| **BOTH frames** | 136 | **1.4%** |

### Key Findings by Publication
*   **Highest Threat Framing:** *Jouwatch* (31.2%), *TA* (20.4%), *Tichys Einblick* (20.0%).
*   **Highest Benefit Framing:** *Handelsblatt* (11.1%), *Epoch Times* (10.7%).

## Limitations and Future Research

### Statistical Volatility of Low-Prevalence Frames
The economic benefit frame has a very low prevalence (approx. 2.5–4%) in the corpus. While the system achieved perfect recall (identifying all human-labelled benefit cases), the precision of 0.625 is mathematically sensitive to a small number of false positives. In this project, 4 borderline cases (related to the legal right to work vs. explicit economic benefit) accounted for the precision gap.

### Single-Model Dependency
This project utilized the university compute proxy model exclusively for the full 10,000-row run to ensure internal consistency and resource efficiency. While the `bacchuss` routine allows for multi-model benchmarking, such a comparison was out of scope for this phase. Future work could validate these findings across different model architectures (e.g., Llama 3 or GPT-4o).

### Translation Layer
The analysis was performed on English translations of German news paragraphs. While the translation quality was high, nuanced linguistic framing in the original German text might have been altered during the translation process. 
