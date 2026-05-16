# Final Submission Checklist

Use this checklist to ensure the project is ready for submission to the professor.

## 1. Security
- [ ] No hard-coded API keys exist in any script (use `Sys.getenv("MAKI_API_KEY")`).
- [ ] `.Renviron` is present locally but excluded from Git/ZIP.
- [ ] `.gitignore` correctly excludes secrets and large datasets.

## 2. Structure & Integrity
- [ ] `config.R` sources correctly and contains all global settings.
- [ ] `scripts/utils.R` contains helper functions.
- [ ] `scripts/check_project_integrity.R` passes with no failures.
- [ ] Output directories (`outputs/step2_1`, etc.) are created automatically.

## 3. Data Availability
- [ ] `data/raw/dataset_10k_translated.csv` is present in the full submission.
- [ ] `outputs/step5/final_annotated_10k.csv` is present and has 10,000 rows.
- [ ] `outputs/step5/spot_check_50rows.csv` is present for demonstration.

## 4. Documentation
- [ ] `README.md` follows the professional structure.
- [ ] `docs/METHODOLOGY.md` includes limitations and correct F1 wording.
- [ ] `docs/BACCHUSS_ROUTINE_MAPPING.md` explains the alignment with the professor's routine.
- [ ] `docs/SECURITY_AND_REPRODUCIBILITY.md` explains key management.

## 5. Academic Integrity
- [ ] Citations for SCM Codebuch (2025) and de Vreese (2010) are included.
- [ ] The development process (8 iterations) is documented in `reports/prompt_version_log.csv`.
