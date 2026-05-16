# ============================================================
# scripts/prepare_public_repo.R
# Prepares the project for a public GitHub repository by
# removing sensitive data and large binaries.
# ============================================================

cat("=== PREPARING PUBLIC REPOSITORY ===\n")

files_to_remove <- c(
  "data/raw/dataset_10k_translated.csv",
  "outputs/step5/final_annotated_10k.csv",
  ".Renviron",
  ".env"
)

dirs_to_remove <- c(
  ".git"
)

for (f in files_to_remove) {
  if (file.exists(f)) {
    cat("Removing sensitive file:", f, "\n")
    file.remove(f)
  }
}

for (d in dirs_to_remove) {
  if (dir.exists(d)) {
    cat("WARNING: Folder", d, "detected. Please delete it manually before pushing to a new public repo.\n")
    # We don't delete .git automatically to avoid accidents if the user is currently IN a git repo.
  }
}

cat("\nPUBLIC REPOSITORY PREPARATION COMPLETE.\n")
cat("Note: Ensure you have followed the instructions in docs/SECURITY_AND_REPRODUCIBILITY.md\n")
