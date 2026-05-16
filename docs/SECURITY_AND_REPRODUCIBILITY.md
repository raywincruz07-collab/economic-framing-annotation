# Security and Reproducibility

This document outlines the security strategy and reproducibility steps for the economic-framing-annotation project.

## 1. Security & Key Management

- **Environment Variables:** All sensitive API credentials (including `MAKI_API_KEY`) are loaded via environment variables. The system uses the `.Renviron` file to manage these securely.
- **Git Exclusion:** The `.Renviron` file is explicitly excluded from version control via `.gitignore` to prevent accidental leaks.
- **Placeholders:** The repository includes `.Renviron.example`, which contains only generic placeholders. No real API keys are committed to the repository history.
- **Data Privacy:** Large raw datasets and final annotated outputs containing research data are excluded from the public GitHub repository.

## 2. Reproducibility

To reproduce the project results locally, follow these steps:

1. **Setup Environment:**
   - Copy `.Renviron.example` to `.Renviron`.
   - Add your valid API credentials to `.Renviron`.
2. **Prepare Data:**
   - Place the required input datasets (available in the academic submission package) into the `data/raw/` directory.
3. **Install Dependencies:**
   - Install the required R packages as listed in the `README.md`.
4. **Execute Pipeline:**
   - Run the R scripts in the `scripts/` directory in numbered order.
   - The scripts will automatically load configuration and credentials from `config.R` and the environment.

## 3. Exclusion Policy

This public repository adheres to a strict "Secret-Free" and "Private-Safe" policy. Files containing API keys, credentials, or large research datasets are intentionally excluded to ensure academic integrity and data security.
