library(testthat)

# Source the utility functions if they exist
utils_path <- file.path("../../", "src/R/utils.R")
if (file.exists(utils_path)) {
  source(utils_path)
} else if (file.exists(file.path("../../", "scripts/utils.R"))) {
  source(file.path("../../", "scripts/utils.R"))
}

test_that("label cleaning", {
  # Test explicit YES and NO
  expect_equal(as.character(clean_label("YES")), "YES")
  expect_equal(as.character(clean_label("NO")), "NO")
  
  # Test Label: format
  expect_equal(as.character(clean_label("Label: YES")), "YES")
  expect_equal(as.character(clean_label("Label: NO")), "NO")
  
  # Test with formatting like **
  expect_equal(as.character(clean_label("**Label: YES**")), "YES")
  
  # Test conversational text ending with Label: NO
  expect_equal(as.character(clean_label("conversational text ending with Label: NO")), "NO")
  
  # Test lowercase
  expect_equal(as.character(clean_label("yes")), "YES")
  
  # Test invalid or ambiguous text
  expect_equal(as.character(clean_label("invalid or ambiguous text")), NA_character_)
})

test_that("text cleaning", {
  expect_type(clean_text_api("test"), "character")
  expect_equal(as.character(clean_text_api("")), "")
  expect_equal(as.character(clean_text_api("ordinary text")), "ordinary text")
  # Does not change length (it's vectorized)
  expect_equal(length(clean_text_api(c("a", "b"))), 2)
})
