# Security and Reproducibility

This project is designed to be reproducible and secure. It follows the professor's `bacchuss` routine for computational annotation.

## Security: API Key Management

The project uses a Large Language Model (LLM) via an API. To prevent security breaches:

1. **Environment Variables**: API credentials are NOT hard-coded in the scripts. They are loaded from environment variables using `Sys.getenv()`.
2. **.Renviron**: You should store your API key in a local `.Renviron` file in the project root.
3. **.Renviron.example**: A template is provided in `.Renviron.example`. Copy this to `.Renviron` and paste your key.
4. **Git Protection**: The `.gitignore` file is configured to exclude `.Renviron`, `.env`, and any `.key` files from being committed to the repository.

### Required Environment Variables

- `MAKI_API_KEY`: Your private API key.
- `MAKI_API_HOST`: The API endpoint (default provided in `config.R`).
- `MAKI_API_MODEL`: The model name (default provided in `config.R`).
- `MAKI_API_BACKEND`: The backend type (default provided in `config.R`).

## Reproducibility

To ensure the results are reproducible across different environments:

1. **Central Configuration**: All paths, instructions, and API defaults are defined in `config.R`.
2. **Standard Headers**: Every main script sources `config.R` and `scripts/utils.R` to ensure a consistent environment.
3. **Seed Consistency**: Random seeds are used in sampling scripts (e.g., `step0_draw_sample.R`) to ensure the same samples are drawn every time.
4. **Project Integrity Check**: A script `scripts/check_project_integrity.R` is provided to verify that all required files and folders are present.

## Data Availability

- **Public GitHub**: Large raw datasets (`data/raw/dataset_10k_translated.csv`) and the final 10,000-row output (`outputs/step5/final_annotated_10k.csv`) are excluded from the public GitHub repository for privacy and storage reasons.
- **Academic Submission**: The full academic submission (ZIP package) includes these files for grading and verification.

---
*Note: If you are using this repository on a new system, please ensure you have installed all dependencies listed in the README and configured your `.Renviron` file.*
