# ============================================================
# scripts/utils_api.R
# API configuration and safety checks
# ============================================================

check_api_config <- function() {
  missing <- c()

  if (!exists("API_MODEL") || is.na(API_MODEL) || API_MODEL == "") missing <- c(missing, "API_MODEL")
  if (!exists("API_HOST") || is.na(API_HOST) || API_HOST == "") missing <- c(missing, "API_HOST")
  if (!exists("API_KEY") || is.na(API_KEY) || API_KEY == "") missing <- c(missing, "API_KEY")
  if (!exists("API_BACKEND") || is.na(API_BACKEND) || API_BACKEND == "") missing <- c(missing, "API_BACKEND")

  if (length(missing) > 0) {
    stop(
      paste0(
        "Missing API configuration: ", paste(missing, collapse = ", "),
        ". Set these in .Renviron. See .Renviron.example."
      ),
      call. = FALSE
    )
  }

  invisible(TRUE)
}
