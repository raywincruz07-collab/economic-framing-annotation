library(testthat)

test_that("Path and secret checks", {
  files <- list.files(file.path("../../"), recursive = TRUE, full.names = TRUE)
  files <- files[!grepl("archive/|metadata/|reports/audits/|\\.git/|\\.pdf$|\\.png$|\\.RData$|\\.zip$|test_project_security\\.R$", files)]
  files <- files[grepl("\\.(R|py|sh|txt|md|yml|yaml|json)$", files)]
  
  found_issues <- FALSE
  for (f in files) {
    tryCatch({
      content <- paste(readLines(f, warn = FALSE), collapse = " ")
      if (grepl("API_KEY\\s*=\\s*['\\\"]|password\\s*=\\s*['\\\"]|Bearer [a-zA-Z0-9]{20,}", content, ignore.case = TRUE)) {
         print(f)
         found_issues <- TRUE
      }
    }, error = function(e) {})
  }
  
  expect_false(found_issues)
})

test_that("Private data exposure", {
  pub_dirs <- c("submission", "reports/contributions", "references", "docs")
  for (pd in pub_dirs) {
    if (dir.exists(file.path("../../", pd))) {
      # The private data is .csv files from coder_completed
      fs <- list.files(file.path("../../", pd), recursive = TRUE, pattern = "coder_.*\\.csv")
      expect_equal(length(fs), 0, label = paste("No private CSV in", pd))
    }
  }
  
  gi <- readLines(file.path("../../", ".gitignore"), warn = FALSE)
  expect_true(any(grepl("submitted_private", gi)), label = "gitignore contains submitted_private")
})
